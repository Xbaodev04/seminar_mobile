import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/poi.dart';
import '../../data/remote/api_client.dart';
import 'auth_service.dart';
import 'listening_history_service.dart';

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

  Future<void> enterPoi(Poi poi, {String? language}) async {
    _currentPoi = poi;
    _isPlaying = false;
    _userLanguage = language ?? 'vi';
    _visitedCount++;
    _currentContentIndex = 0;
    _currentContentStartTime = null;

    // Fetch stall contents with user language
    try {
      final accessToken = AuthService.instance.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        _currentContents = [];
      } else {
        final contents = await ApiClient.instance.getStallContents(poi.id, accessToken);
        _currentContents = contents;
      }
    } catch (e) {
      _currentContents = [];
    }

    notifyListeners();
  }

  Future<void> _commitListeningHistoryIfNeeded() async {
    if (_currentPoi == null || _currentContents.isEmpty) return;
    if (_currentContentStartTime == null) return;
    if (_currentContentIndex < 0 || _currentContentIndex >= _currentContents.length) return;

    final content = _currentContents[_currentContentIndex];
    final stallContentId = content['id'] as String? ?? '';
    final durationSeconds = DateTime.now().difference(_currentContentStartTime!).inSeconds;

    _currentContentStartTime = null;

    if (durationSeconds <= 0) return;

    try {
      print('[ListeningHistory] commit: stall=${_currentPoi?.id}, content=$stallContentId, duration=$durationSeconds');
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

    if (audioUrl == null || audioUrl.isEmpty) return;

    try {
      _isPlaying = true;

      // Build full URL if it's a relative path
      String fullUrl = audioUrl;
      if (!audioUrl.startsWith('http')) {
        fullUrl = '${ApiClient.instance.baseUrl}$audioUrl';
      }

      await _audioPlayer.setUrl(fullUrl);
      _currentContentStartTime = DateTime.now();
      await _audioPlayer.play();

      notifyListeners();
    } catch (e) {
      _isPlaying = false;
      _currentContentStartTime = null;
      notifyListeners();
    }
  }

  Future<void> playNextContent() async {
    if (_currentContentIndex < _currentContents.length - 1) {
      await playContent(_currentContentIndex + 1);
    } else {
      await leavePoi();
    }
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
      await _commitListeningHistoryIfNeeded();
    } else {
      if (_currentContents.isNotEmpty) {
        await _audioPlayer.play();
        _isPlaying = true;
        _currentContentStartTime ??= DateTime.now();
      }
    }
    notifyListeners();
  }

  Future<void> leavePoi() async {
    await _audioPlayer.stop();
    await _commitListeningHistoryIfNeeded();
    _currentPoi = null;
    _isPlaying = false;
    _userLanguage = null;
    _currentContents = [];
    _currentContentIndex = 0;
    _currentContentStartTime = null;
    notifyListeners();
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
