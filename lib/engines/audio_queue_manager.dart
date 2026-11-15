import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/locale_provider.dart';
import '../data/remote/api_client.dart';
import '../data/remote/localization_api.dart';
import 'audio_output.dart';
import 'narration_audio_resolver.dart';
import 'playback_tracker.dart';
import '../core/services/visitor_analytics.dart';

class AudioRequest {
  final String? poiId;
  final String? audioUrl;
  final bool isFallback;
  final String? sourceLang;
  final String fallbackText;
  final String targetLang;
  final VoidCallback? onComplete;
  final ValueChanged<LocalizedNarration>? onLocalized;
  final VoidCallback? onStarted;

  const AudioRequest({
    this.poiId,
    this.audioUrl,
    this.isFallback = false,
    this.sourceLang,
    required this.fallbackText,
    required this.targetLang,
    this.onComplete,
    this.onLocalized,
    this.onStarted,
  });
}

class AudioQueueManager extends ChangeNotifier {
  static final AudioQueueManager instance = AudioQueueManager._production();

  factory AudioQueueManager._production() {
    final api = LocalizationApi(baseUrl: () => ApiClient.instance.baseUrl);
    return AudioQueueManager(
      audio: Mp3Output(),
      speech: DeviceSpeechOutput(),
      currentLanguage: () => LocaleProvider.instance.effectiveLanguageCode,
      resolver: NarrationAudioResolver(
        baseUrl: () => ApiClient.instance.baseUrl,
        generate: api.generate,
      ),
      onDispose: api.close,
      analytics: PlaybackTracker(
        emit: VisitorAnalytics.instance.record,
        isEnabled: () => VisitorAnalytics.instance.enabled,
        consentVersion: () => VisitorAnalytics.instance.consentVersion,
      ),
    );
  }

  AudioQueueManager({
    required AudioOutput audio,
    required SpeechOutput speech,
    required NarrationAudioResolver resolver,
    required String Function() currentLanguage,
    VoidCallback? onDispose,
    PlaybackTracker? analytics,
  }) : _audio = audio,
       _speech = speech,
       _resolver = resolver,
       _currentLanguage = currentLanguage,
       _onDispose = onDispose,
       _analytics = analytics {
    _audioSubscription = _audio.completed.listen((_) {
      if (_isPlayingAudio) _handleCompletion();
    });
    _speechSubscription = _speech.completed.listen((_) {
      if (_isPlayingTts) _handleCompletion();
    });
    _positionSubscription = _audio.positionStream.listen((position) {
      if (_isPlayingAudio && _isCurrent(_currentReqId)) {
        _analytics?.audioPosition(position);
      }
    });
  }

  final AudioOutput _audio;
  final SpeechOutput _speech;
  final NarrationAudioResolver _resolver;
  final String Function() _currentLanguage;
  final VoidCallback? _onDispose;
  final PlaybackTracker? _analytics;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<void> _audioSubscription;
  late final StreamSubscription<void> _speechSubscription;
  Future<void> _loadTail = Future<void>.value();
  int _currentReqId = 0;
  bool _disposed = false;
  bool _isPlayingAudio = false;
  bool _isPlayingTts = false;
  bool _isPreparing = false;
  bool _audioLoaded = false;
  AudioRequest? _currentReq;
  ResolvedNarration? _resolved;

  bool get isPlaying => _isPlayingAudio || _isPlayingTts;
  bool get isPreparing => _isPreparing;
  Stream<Duration> get positionStream => _audio.positionStream;
  Stream<Duration?> get durationStream => _audio.durationStream;
  Duration get currentPosition => _audio.position;
  Duration? get currentDuration => _audioLoaded ? _audio.duration : null;

  bool _isCurrent(int id) =>
      !_disposed &&
      id == _currentReqId &&
      _currentReq != null &&
      _currentReq!.targetLang == _currentLanguage();

  Future<void> enqueue(AudioRequest req) async {
    _analytics?.finish(completed: false);
    final id = ++_currentReqId;
    _currentReq = req;
    _resolved = null;
    _audioLoaded = false;
    _isPreparing = true;
    await _halt(id);
    if (!_isCurrent(id)) return;
    notifyListeners();
    final resolved = await _resolver.resolve(
      poiId: req.poiId,
      audioUrl: req.audioUrl,
      isFallback: req.isFallback,
      text: req.fallbackText,
      targetLang: req.targetLang,
      sourceLang: req.sourceLang,
      isCurrent: () => _isCurrent(id),
    );
    if (!_isCurrent(id) || resolved == null) return;
    _resolved = resolved;
    _analytics?.prepare(req.poiId, resolved.language);
    if (resolved.localization != null) {
      req.onLocalized?.call(resolved.localization!);
    }
    if (resolved.audioUrl != null) {
      try {
        // Serialize native loads: an old setUrl must not replace a newer source.
        final load = _loadTail.then((_) async {
          if (_isCurrent(id)) await _audio.load(resolved.audioUrl!);
        });
        _loadTail = load.catchError((Object _) {});
        await load;
        if (!_isCurrent(id)) return;
        _audioLoaded = true;
        _startAudio(id);
        return;
      } catch (_) {
        if (!_isCurrent(id)) return;
        _audioLoaded = false;
      }
    }
    await _startSpeech(id);
  }

  void _startAudio(int id) {
    if (!_isCurrent(id)) return;
    _isPreparing = false;
    _isPlayingAudio = true;
    _isPlayingTts = false;
    _analytics?.audioResumed(_audio.position);
    _currentReq?.onStarted?.call();
    notifyListeners();
    // just_audio.play completes at the END of playback. Do not block enqueue/UI.
    unawaited(_playAudio(id));
  }

  Future<void> _playAudio(int id) async {
    try {
      await _audio.play();
    } catch (_) {
      if (!_isCurrent(id)) return;
      _isPlayingAudio = false;
      _analytics?.pause();
      _audioLoaded = false;
      await _startSpeech(id);
    }
  }

  Future<void> _startSpeech(int id) async {
    if (!_isCurrent(id) || _resolved == null) return;
    _isPreparing = false;
    _isPlayingAudio = false;
    if (_resolved!.text.trim().isEmpty) {
      notifyListeners();
      return;
    }
    _isPlayingTts = true;
    try {
      await _speech.speak(_resolved!.text, _resolved!.language);
      if (!_isCurrent(id)) return;
      _analytics?.speechStarted();
      _currentReq?.onStarted?.call();
    } catch (_) {
      if (!_isCurrent(id)) return;
      _isPlayingTts = false;
    }
    notifyListeners();
  }

  void _handleCompletion() {
    if (!_isCurrent(_currentReqId)) return;
    _analytics?.finish(completed: true);
    final callback = _currentReq?.onComplete;
    _isPlayingAudio = false;
    _isPlayingTts = false;
    _isPreparing = false;
    _currentReq = null;
    _resolved = null;
    _audioLoaded = false;
    notifyListeners();
    callback?.call();
  }

  Future<void> _halt(int id) async {
    _isPlayingAudio = false;
    _isPlayingTts = false;
    try {
      await _audio.stop();
    } catch (_) {}
    if (_disposed || id != _currentReqId) return;
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<void> stop() async {
    _analytics?.finish(completed: false);
    final id = ++_currentReqId;
    _currentReq = null;
    _resolved = null;
    _audioLoaded = false;
    _isPreparing = false;
    await _halt(id);
    if (!_disposed) notifyListeners();
  }

  Future<void> pause() async {
    _analytics?.pause();
    ++_currentReqId; // Also discard an on-demand result still in flight.
    _isPreparing = false;
    _isPlayingAudio = false;
    _isPlayingTts = false;
    try {
      await _audio.pause();
    } catch (_) {}
    try {
      await _speech.stop();
    } catch (_) {}
    if (!_disposed) notifyListeners();
  }

  Future<void> resume() async {
    final req = _currentReq;
    if (req == null || req.targetLang != _currentLanguage() || _disposed) {
      return;
    }
    if (_isPreparing || isPlaying) return;
    final id = ++_currentReqId;
    if (_audioLoaded && _resolved?.audioUrl != null) {
      _startAudio(id);
    } else if (_resolved != null) {
      await _startSpeech(id);
    } else {
      await enqueue(req);
    }
  }

  Future<void> seek(Duration position) {
    _analytics?.seekTo(position);
    return _audio.seek(position);
  }

  Future<void> seekForward({int seconds = 10}) async {
    final next = currentPosition + Duration(seconds: seconds);
    final end = currentDuration ?? Duration.zero;
    await seek(next > end ? end : next);
  }

  Future<void> seekBackward({int seconds = 10}) async {
    final previous = currentPosition - Duration(seconds: seconds);
    await seek(previous < Duration.zero ? Duration.zero : previous);
  }

  @override
  void dispose() {
    _analytics?.finish(completed: false);
    _disposed = true;
    ++_currentReqId;
    unawaited(_audioSubscription.cancel());
    unawaited(_speechSubscription.cancel());
    unawaited(_positionSubscription.cancel());
    unawaited(_audio.dispose());
    unawaited(_speech.stop());
    _onDispose?.call();
    super.dispose();
  }
}
