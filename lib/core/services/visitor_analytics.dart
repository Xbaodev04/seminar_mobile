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

/// Anonymous playback events; consent and offline retries survive app restarts.
class VisitorAnalytics extends ChangeNotifier {
  VisitorAnalytics({
    http.Client? client,
    String Function()? baseUrl,
    this.retryInterval = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? (() => ApiClient.instance.baseUrl);
  static final instance = VisitorAnalytics();
  static const consentKey = 'visitor_analytics_consent_v1';
  static const queueKey = 'visitor_analytics_pending_v1';
  final http.Client _client;
  final String Function() _baseUrl;
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
    if (!enabled) _pending.clear();
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
    if (!const ['vi', 'en', 'zh', 'ja', 'ko'].contains(event['language'])) {
      return;
    }
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
