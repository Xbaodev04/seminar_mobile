import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/remote/api_client.dart';

String analyticsEventId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Anonymous visits and playback; consent and offline retries survive restarts.
class VisitorAnalytics extends ChangeNotifier {
  VisitorAnalytics({
    http.Client? client,
    String Function()? baseUrl,
    DateTime Function()? now,
    this.retryInterval = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? (() => ApiClient.instance.baseUrl),
       _now = now ?? DateTime.now;
  static final instance = VisitorAnalytics();
  static const consentKey = 'visitor_analytics_consent_v2';
  static const queueKey = 'visitor_analytics_pending_v1';
  static const deviceKey = 'visitor_analytics_device_v1';
  static const sessionKey = 'visitor_analytics_session_v1';
  static const activityKey = 'visitor_analytics_activity_v1';
  static const sessionStartKey = 'visitor_analytics_session_start_v1';
  static const sessionTimeout = Duration(minutes: 30);
  final http.Client _client;
  final String Function() _baseUrl;
  final DateTime Function() _now;
  bool _visitStarted = false;
  String? _announcedSession;
  String? _deviceId;
  String? _sessionId;
  DateTime? _lastTouch;
  final Duration retryInterval;
  SharedPreferences? _prefs;
  bool? _consent;
  bool get hasChoice => _consent != null;
  bool get enabled => _consent == true;
  int get consentVersion => _consentGeneration;
  int get pendingCount => _pending.length;
  final List<Map<String, dynamic>> _pending = [];
  Future<void> _writes = Future.value();
  bool _sending = false;
  bool _disposed = false;
  int _consentGeneration = 0;
  Timer? _retry;

  Future<void> init({SharedPreferences? preferences}) async {
    if (_prefs != null) return;
    _prefs = preferences ?? await SharedPreferences.getInstance();
    _consent = _prefs!.getBool(consentKey);
    // Keep existing declines; ask again before expanding beyond playback data.
    if (_consent == null &&
        _prefs!.getBool('visitor_analytics_consent_v1') == false) {
      _consent = false;
    }
    try {
      final saved = jsonDecode(_prefs!.getString(queueKey) ?? '[]');
      if (enabled && saved is List) {
        _pending.addAll(
          saved
              .whereType<Map>()
              .map((event) => Map<String, dynamic>.from(event))
              .take(500),
        );
      }
    } catch (_) {
      /* Ignore corrupt local analytics, never block audio. */
    }
    _retry = Timer.periodic(retryInterval, (_) => unawaited(flush()));
    unawaited(flush());
  }

  Future<void> setConsent(bool enabled) async {
    await init();
    if (!await _prefs!.setBool(consentKey, enabled)) return;
    ++_consentGeneration;
    _consent = enabled;
    if (!enabled) {
      _pending.clear();
      _deviceId = null;
      _sessionId = null;
      _announcedSession = null;
      for (final key in [deviceKey, sessionKey, activityKey, sessionStartKey]) {
        await _prefs!.remove(key);
      }
    } else if (_visitStarted) {
      _touchSession();
    }
    await _persist();
    if (!_disposed) notifyListeners();
    if (enabled) unawaited(flush());
  }

  void record(Map<String, dynamic> event) {
    if (!enabled ||
        _disposed ||
        !RegExp(
          r'^[0-9a-fA-F]{24}$',
        ).hasMatch(event['poi_id']?.toString() ?? '')) {
      return;
    }
    if (event['kind']?.toString().startsWith('audio_') == true &&
        !const ['vi', 'en', 'zh', 'ja', 'ko'].contains(event['language'])) {
      return;
    }
    if (_visitStarted) _touchSession();
    _enqueue({
      ...event,
      if (_visitStarted) 'device_id': _deviceId,
      if (_visitStarted) 'session_id': _sessionId,
    });
  }

  /// Does not create an identity or send requests before consent.
  Future<void> startVisit() async {
    await init();
    _visitStarted = true;
    if (enabled && !_disposed) _touchSession();
  }

  void recordActivity() {
    if (!_visitStarted || !enabled || _disposed) return;
    final now = _now();
    if (_lastTouch != null &&
        now.difference(_lastTouch!) < const Duration(seconds: 10)) {
      return;
    }
    _lastTouch = now;
    _touchSession();
  }

  void _touchSession() {
    final prefs = _prefs;
    if (!enabled || prefs == null || _disposed) return;
    final now = _now().toUtc();
    _deviceId = prefs.getString(deviceKey) ?? analyticsEventId();
    final last = DateTime.tryParse(prefs.getString(activityKey) ?? '');
    _sessionId = prefs.getString(sessionKey);
    if (_sessionId == null ||
        last == null ||
        now.difference(last) >= sessionTimeout ||
        now.isBefore(last)) {
      _sessionId = analyticsEventId();
      unawaited(prefs.setString(sessionStartKey, now.toIso8601String()));
    }
    unawaited(prefs.setString(deviceKey, _deviceId!));
    unawaited(prefs.setString(sessionKey, _sessionId!));
    unawaited(prefs.setString(activityKey, now.toIso8601String()));
    if (_announcedSession == _sessionId) return;
    _announcedSession = _sessionId;
    _enqueue({
      'event_id': analyticsEventId(),
      'kind': 'app_visited',
      'occurred_at': prefs.getString(sessionStartKey) ?? now.toIso8601String(),
      'device_id': _deviceId,
      'session_id': _sessionId,
    });
  }

  void viewPoi(String poiId, {bool fromQr = false}) {
    record({
      'event_id': analyticsEventId(),
      'kind': 'poi_viewed',
      'poi_id': poiId,
      'source': fromQr ? 'qr' : 'direct',
      'occurred_at': _now().toUtc().toIso8601String(),
    });
  }

  void _enqueue(Map<String, dynamic> event) {
    _pending.add(Map.from(event));
    if (_pending.length > 500) _pending.removeAt(0);
    unawaited(_persist().then((_) => flush()).catchError((Object _) {}));
  }

  Future<void> _persist() {
    final data = jsonEncode(_pending);
    _writes = _writes.catchError((Object _) {}).then((_) async {
      await _prefs?.setString(queueKey, data);
    });
    return _writes;
  }

  Future<void> flush() async {
    if (_sending || !enabled || _disposed || _pending.isEmpty) return;
    _sending = true;
    final generation = _consentGeneration;
    try {
      await _writes;
      while (enabled &&
          !_disposed &&
          generation == _consentGeneration &&
          _pending.isNotEmpty) {
        final batch = _pending.take(50).toList();
        final base = _baseUrl().replaceFirst(RegExp(r'/+$'), '');
        final url = Uri.parse(
          '$base${base.endsWith('/api/v1') ? '' : '/api/v1'}/analytics/collect',
        );
        final response = await _client
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'consent_status': 'granted', 'events': batch}),
            )
            .timeout(const Duration(seconds: 10));
        if (generation != _consentGeneration || _disposed) return;
        if (response.statusCode != 200 &&
            response.statusCode != 400 &&
            response.statusCode != 422) {
          break;
        }
        final sentIds = batch.map((event) => event['event_id']).toSet();
        _pending.removeWhere((event) => sentIds.contains(event['event_id']));
        await _persist();
      }
    } catch (_) {
      /* Keep IDs and timestamps for an idempotent retry. */
    } finally {
      _sending = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _client.close();
    super.dispose();
  }
}
