import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/models/poi.dart';
import '../../data/remote/api_client.dart';
import '../../engines/tts_engine.dart';
import 'auth_service.dart';
import 'listening_history_service.dart';
import 'locale_provider.dart';

/// A singleton manager that controls audio playback for POI content
class GeoAudioManager extends ChangeNotifier {
  GeoAudioManager._private() {
    _audioPlayer.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await _commitListeningHistoryIfNeeded();
        await playNextContent();
      } else if (!state.playing && _isPlaying) {
        // User paused/stopped via external controls (lockscreen/media keys)
        _isPlaying = false;
        await _commitListeningHistoryIfNeeded();
        notifyListeners();
      }
    });

    TtsEngine.instance.addListener(() {
      final tts = TtsEngine.instance;
      if (tts.isSpeaking != _isPlaying) {
        _isPlaying = tts.isSpeaking;
        notifyListeners();
      }
    });
  }
  static final GeoAudioManager instance = GeoAudioManager._private();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Poi? _currentPoi;
  bool _isPlaying = false;
  int _visitedCount = 0;
  Duration _totalListen = Duration.zero;
  String? _userLanguage;
  List<Map<String, dynamic>> _currentContents = [];
  int _currentContentIndex = 0;
  DateTime? _currentContentStartTime;

  Poi? get currentPoi => _currentPoi;
  bool get isPlaying => _isPlaying;
  int get visitedCount => _visitedCount;
  Duration get totalListen => _totalListen;
  String? get userLanguage => _userLanguage;
  List<Map<String, dynamic>> get currentContents => _currentContents;
  int get currentContentIndex => _currentContentIndex;

  Future<void> enterPoi(
    Poi poi, {
    String? language,
    List<Map<String, dynamic>>? initialContents,
    bool autoPlay = false,
  }) async {
    _currentPoi = poi;
    _isPlaying = false;
    _userLanguage = language ?? 'vi';
    _visitedCount++;
    _currentContentIndex = 0;
    _currentContentStartTime = null;

    if (initialContents != null && initialContents.isNotEmpty) {
      _currentContents = initialContents;
      if (autoPlay && _currentContents.isNotEmpty) {
        await playContent(0);
      } else {
        notifyListeners();
      }
      return;
    }

    // Fetch stall contents (public endpoint, works with or without accessToken)
    try {
      final accessToken = AuthService.instance.accessToken ?? '';
      final contents = await ApiClient.instance.getStallContents(
        poi.id,
        accessToken,
      );
      _currentContents = contents;
      if (autoPlay && _currentContents.isNotEmpty) {
        await playContent(0);
      }
    } catch (e) {
      debugPrint('[GeoAudioManager] getStallContents error: $e');
      _currentContents = [];
    }

    notifyListeners();
  }

  Future<void> _commitListeningHistoryIfNeeded() async {
    if (_currentPoi == null || _currentContents.isEmpty) return;
    if (_currentContentStartTime == null) return;
    if (_currentContentIndex < 0 ||
        _currentContentIndex >= _currentContents.length) {
      return;
    }

    final content = _currentContents[_currentContentIndex];
    final stallContentId = content['id'] as String? ?? '';
    final durationSeconds = DateTime.now()
        .difference(_currentContentStartTime!)
        .inSeconds;

    _currentContentStartTime = null;

    if (durationSeconds <= 0) return;

    try {
      print(
        '[ListeningHistory] commit: stall=${_currentPoi?.id}, content=$stallContentId, duration=$durationSeconds',
      );
      await ListeningHistoryService.instance.addHistory(
        stallId: _currentPoi?.id ?? '',
        stallContentId: stallContentId,
        listenedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        listenDuration: durationSeconds,
      );
      print('[ListeningHistory] success');
    } catch (e) {
      print('[ListeningHistory] error: $e');
    }
  }

  Future<void> playContent(int index) async {
    if (index < 0 || index >= _currentContents.length) return;

    // Commit history for existing track before switching
    await _commitListeningHistoryIfNeeded();

    _currentContentIndex = index;
    final content = _currentContents[index];
    final audioUrl = content['audio_url'] as String?;
    final targetLang = LocaleProvider.instance.locale?.languageCode ?? 'vi';
    final textToSpeak =
        (content['translated_text'] ??
                content['text_content'] ??
                content['description'] ??
                content['title'] ??
                '')
            .toString();

    // 1. Ưu tiên phát file Audio MP3 từ Backend nếu có sẵn
    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        await TtsEngine.instance.stop(); // Stop TTS nếu đang nói
        _isPlaying = true;

        // Build full URL if it's a relative path (e.g. /static/audio/xyz.mp3)
        String fullUrl = audioUrl;
        if (!audioUrl.startsWith('http')) {
          final baseUri = Uri.parse(ApiClient.instance.baseUrl);
          final hostBase =
              '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
          fullUrl =
              '$hostBase${audioUrl.startsWith('/') ? audioUrl : '/$audioUrl'}';
        }

        await _audioPlayer.setUrl(fullUrl);
        _currentContentStartTime = DateTime.now();
        await _audioPlayer.play();

        notifyListeners();
        return;
      } catch (e) {
        debugPrint(
          '[GeoAudioManager] Audio URL playback error: $e, falling back to TTS',
        );
      }
    }

    // 2. Fallback sang Text-To-Speech nếu không có audioUrl hoặc phát file bị lỗi
    if (textToSpeak.isNotEmpty) {
      try {
        await _audioPlayer.stop(); // Stop MP3 player
        _isPlaying = true;
        _currentContentStartTime = DateTime.now();

        await TtsEngine.instance.speak(
          text: textToSpeak,
          targetLang: targetLang,
        );

        notifyListeners();
        return;
      } catch (e) {
        debugPrint('[GeoAudioManager] TTS fallback error: $e');
      }
    }

    _isPlaying = false;
    _currentContentStartTime = null;
    notifyListeners();
  }

  Future<void> playNextContent() async {
    if (_currentContentIndex < _currentContents.length - 1) {
      await playContent(_currentContentIndex + 1);
    } else {
      await leavePoi();
    }
  }

  Future<void> togglePlay() async {
    final targetLang = LocaleProvider.instance.locale?.languageCode ?? 'vi';

    if (_isPlaying) {
      if (targetLang != 'en') {
        await TtsEngine.instance.stop();
      } else {
        await _audioPlayer.pause();
      }
      _isPlaying = false;
      await _commitListeningHistoryIfNeeded();
    } else {
      if (_currentContents.isNotEmpty) {
        if (targetLang != 'en') {
          final content = _currentContents[_currentContentIndex];
          final textToSpeak =
              (content['translated_text'] ??
                      content['text_content'] ??
                      content['description'] ??
                      '')
                  .toString();
          await TtsEngine.instance.speak(
            text: textToSpeak,
            targetLang: targetLang,
          );
        } else {
          await _audioPlayer.play();
        }
        _isPlaying = true;
        _currentContentStartTime ??= DateTime.now();
      }
    }
    notifyListeners();
  }

  Future<void> leavePoi() async {
    await _audioPlayer.stop();
    await TtsEngine.instance.stop();
    await _commitListeningHistoryIfNeeded();
    _currentPoi = null;
    _isPlaying = false;
    _userLanguage = null;
    _currentContents = [];
    _currentContentIndex = 0;
    _currentContentStartTime = null;
    notifyListeners();
  }

  /// 1. Lấy bài thuyết minh hiện tại
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
      _currentPoi?.name ??
      '';
  String get currentAudioUrl => currentContent?['audio_url'] ?? '';

  /// 2. Expose các Stream thời gian từ just_audio cho UI cập nhật Slider
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Duration get currentPosition => _audioPlayer.position;
  Duration? get currentDuration => _audioPlayer.duration;

  /// 3. Các hàm điều khiển Seek (Tua)
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekForward({int seconds = 10}) async {
    final newPos = _audioPlayer.position + Duration(seconds: seconds);
    final dur = _audioPlayer.duration ?? Duration.zero;
    await _audioPlayer.seek(newPos > dur ? dur : newPos);
  }

  Future<void> seekBackward({int seconds = 10}) async {
    final newPos = _audioPlayer.position - Duration(seconds: seconds);
    await _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void addListen(Duration d) {
    _totalListen += d;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
