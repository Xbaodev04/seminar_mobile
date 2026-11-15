import '../core/services/visitor_analytics.dart';

/// One playback identity spans pause/resume and MP3 -> device speech fallback.
class PlaybackTracker {
  PlaybackTracker({
    required this.emit,
    DateTime Function()? now,
    bool Function()? isEnabled,
    int Function()? consentVersion,
  }) : _now = now ?? DateTime.now,
       _isEnabled = isEnabled ?? (() => true),
       _consentVersion = consentVersion ?? (() => 0);
  final void Function(Map<String, dynamic>) emit;
  final DateTime Function() _now;
  final bool Function() _isEnabled;
  final int Function() _consentVersion;
  int _version = 0;
  bool _recording = false;
  String? _poiId;
  String? _language;
  String? _playbackId;
  bool _started = false;
  double _seconds = 0;
  Duration _position = Duration.zero;
  DateTime? _speechSince;

  void prepare(String? poiId, String language) {
    finish(completed: false);
    _poiId = poiId;
    _language = language;
    _playbackId = analyticsEventId();
    _recording = _isEnabled();
    _version = _consentVersion();
    _started = false;
    _seconds = 0;
    _position = Duration.zero;
  }

  void _event(String kind, {double? seconds}) {
    if (!_recording ||
        !_isEnabled() ||
        _version != _consentVersion() ||
        _poiId == null ||
        _playbackId == null)
      return;
    emit({
      'event_id': analyticsEventId(),
      'poi_id': _poiId,
      'kind': kind,
      'occurred_at': _now().toUtc().toIso8601String(),
      'playback_id': _playbackId,
      'language': _language,
      if (seconds != null) 'duration_seconds': seconds.clamp(0, 86400),
    });
  }

  void _start() {
    if (_started) return;
    _started = true;
    _event('audio_started');
  }

  void audioResumed(Duration position) {
    _position = position;
  }

  void audioPosition(Duration position) {
    final delta = position - _position;
    _position = position;
    if (delta <= Duration.zero) return;
    _start();
    _seconds += delta.inMicroseconds / Duration.microsecondsPerSecond;
  }

  void speechStarted() {
    _start();
    _speechSince ??= _now();
  }

  void pause() {
    if (_speechSince != null) {
      _seconds +=
          _now().difference(_speechSince!).inMicroseconds /
          Duration.microsecondsPerSecond;
      _speechSince = null;
    }
  }

  void seekTo(Duration position) {
    _position = position;
  }

  void finish({required bool completed}) {
    pause();
    if (_started) {
      _event(completed ? 'audio_completed' : 'audio_ended', seconds: _seconds);
    }
    _started = false;
    _playbackId = null;
    _recording = false;
  }
}
