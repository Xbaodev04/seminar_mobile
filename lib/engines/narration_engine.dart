import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/poi.dart';
import '../core/services/locale_provider.dart';
import '../core/services/auth_service.dart';
import '../core/services/listening_history_service.dart';
import '../data/remote/api_client.dart';
import 'audio_queue_manager.dart';

class NarrationEngine extends ChangeNotifier {
  static final NarrationEngine instance = NarrationEngine._private();

  NarrationEngine._private() {
    AudioQueueManager.instance.addListener(() {
      notifyListeners();
    });
  }

  Poi? _currentPoi;
  List<Map<String, dynamic>> _currentContents = [];
  int _currentContentIndex = 0;
  DateTime? _currentContentStartTime;
  int _generation = 0;
  bool _isLoadingContents = false;

  Poi? get currentPoi => _currentPoi;
  List<Map<String, dynamic>> get currentContents => _currentContents;
  int get currentContentIndex => _currentContentIndex;
  bool get isPlaying => AudioQueueManager.instance.isPlaying;
  bool get isPreparing =>
      _isLoadingContents || AudioQueueManager.instance.isPreparing;

  Future<void> enterPoi(
    Poi poi, {
    List<Map<String, dynamic>>? initialContents,
    bool autoPlay = false,
  }) async {
    final generation = ++_generation;
    _isLoadingContents = true;
    final history = _commitListeningHistoryIfNeeded();
    await AudioQueueManager.instance.stop();
    await history;
    if (generation != _generation) return;
    _currentPoi = poi;
    _currentContents = [];
    _currentContentIndex = 0;
    _currentContentStartTime = null;

    if (initialContents != null && initialContents.isNotEmpty) {
      _isLoadingContents = false;
      _currentContents = initialContents;
      if (autoPlay && _currentContents.isNotEmpty) {
        await playContent(0);
      } else {
        notifyListeners();
      }
      return;
    }

    try {
      final token = AuthService.instance.accessToken ?? '';
      final contents = await ApiClient.instance.getStallContents(poi.id, token);
      if (generation != _generation) return;
      _isLoadingContents = false;
      _currentContents = contents;
      if (autoPlay && _currentContents.isNotEmpty) {
        await playContent(0);
      }
    } catch (e) {
      if (generation != _generation) return;
      _isLoadingContents = false;
      debugPrint('[NarrationEngine] error: $e');
      _currentContents = [];
    }
    notifyListeners();
  }

  Future<void> playContent(int index) async {
    if (index < 0 || index >= _currentContents.length) return;
    final generation = ++_generation;
    final history = _commitListeningHistoryIfNeeded();
    await AudioQueueManager.instance.stop();
    await history;
    if (generation != _generation) return;

    _currentContentIndex = index;
    final content = _currentContents[index];

    // Xử lý URL Audio
    String? audioUrl = content['audio_url'] as String?;
    if (audioUrl != null && !audioUrl.startsWith('http')) {
      final baseUri = Uri.parse(ApiClient.instance.baseUrl);
      final hostBase =
          '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
      audioUrl =
          '$hostBase${audioUrl.startsWith('/') ? audioUrl : '/$audioUrl'}';
    }

    final targetLang = LocaleProvider.instance.effectiveLanguageCode;
    final textToSpeak =
        (content['translated_text'] ??
                content['text_content'] ??
                content['description'] ??
                content['title'] ??
                '')
            .toString();

    _currentContentStartTime = null;

    // NarrationEngine -> AudioQueueManager -> playWithFallback()
    final request = AudioRequest(
      poiId: (content['poi_id'] ?? content['stall_id'] ?? _currentPoi?.id)
          ?.toString(),
      audioUrl: audioUrl,
      isFallback: content['is_fallback'] == true,
      sourceLang: content['language_code'] as String?,
      fallbackText: textToSpeak,
      targetLang: targetLang,
      onLocalized: (localized) {
        if (generation != _generation) return;
        _currentContents[index] = {
          ...content,
          'title': localized.title,
          'translated_title': localized.title,
          'translated_text': localized.text,
          'text_content': localized.text,
          'audio_url': localized.audioUrl,
          'language_code': localized.lang,
          'is_fallback': false,
        };
        notifyListeners();
      },
      onStarted: () {
        if (generation == _generation) {
          _currentContentStartTime ??= DateTime.now();
        }
      },
      onComplete: () {
        if (generation != _generation) return;
        // Khi bài hiện tại phát xong, tự động gọi playNextContent
        _onAudioCompleted();
      },
    );

    await AudioQueueManager.instance.enqueue(request);
    notifyListeners();
  }

  Future<void> _onAudioCompleted() async {
    final generation = _generation;
    await _commitListeningHistoryIfNeeded();
    if (generation != _generation) return;
    await playNextContent();
  }

  Future<void> playNextContent() async {
    if (_currentContentIndex < _currentContents.length - 1) {
      await playContent(_currentContentIndex + 1);
    } else {
      await leavePoi();
    }
  }

  Future<void> togglePlay() async {
    if (AudioQueueManager.instance.isPlaying ||
        AudioQueueManager.instance.isPreparing) {
      await AudioQueueManager.instance.pause();
      await _commitListeningHistoryIfNeeded();
    } else {
      await AudioQueueManager.instance.resume();
    }
    notifyListeners();
  }

  Future<void> leavePoi() async {
    ++_generation;
    _isLoadingContents = false;
    final history = _commitListeningHistoryIfNeeded();
    // Clear synchronously so delayed content/API results cannot restore this POI.
    _currentPoi = null;
    _currentContents = [];
    _currentContentIndex = 0;
    _currentContentStartTime = null;
    await AudioQueueManager.instance.stop();
    await history;
    notifyListeners();
  }

  Map<String, dynamic>? get currentContent {
    if (_currentContents.isEmpty ||
        _currentContentIndex < 0 ||
        _currentContentIndex >= _currentContents.length) {
      return null;
    }
    return _currentContents[_currentContentIndex];
  }

  String get currentTitle =>
      currentContent?['translated_title'] ??
      currentContent?['title'] ??
      currentContent?['poi_name'] ??
      currentContent?['stall_name'] ??
      _currentPoi?.name ??
      '';

  Future<void> _commitListeningHistoryIfNeeded() async {
    if (_currentContents.isEmpty || _currentContentStartTime == null) return;
    if (_currentContentIndex < 0 ||
        _currentContentIndex >= _currentContents.length) {
      return;
    }

    final content = _currentContents[_currentContentIndex];
    final stallContentId = content['id'] as String? ?? '';
    final stallId =
        content['poi_id'] ?? content['stall_id'] ?? _currentPoi?.id ?? '';
    final durationSeconds = DateTime.now()
        .difference(_currentContentStartTime!)
        .inSeconds;

    _currentContentStartTime = null;

    if (durationSeconds <= 0 || stallId.isEmpty) return;

    try {
      await ListeningHistoryService.instance.addHistory(
        stallId: stallId,
        stallContentId: stallContentId,
        listenedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        listenDuration: durationSeconds,
      );
    } catch (_) {}
  }
}
