import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class LocalizationFailure implements Exception {
  final int? statusCode;
  final DateTime? retryAt;
  const LocalizationFailure({this.statusCode, this.retryAt});
}

class LocalizedNarration {
  final String poiId;
  final String lang;
  final String title;
  final String text;
  final String audioUrl;

  const LocalizedNarration({
    required this.poiId,
    required this.lang,
    required this.title,
    required this.text,
    required this.audioUrl,
  });
}

/// Resolve static paths against the API origin, never against /api/v1.
String resolveAudioUrl(String baseUrl, String path) {
  final origin = Uri.parse(baseUrl).replace(path: '/', query: '', fragment: '');
  final uri = origin.resolve(path.trim());
  if (!{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
    throw const FormatException('Invalid audio URL');
  }
  return uri.toString();
}

class LocalizationApi {
  LocalizationApi({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 50),
    DateTime Function()? clock,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now;

  final String Function() baseUrl;
  final http.Client _client;
  final Duration timeout;
  final DateTime Function() _clock;
  DateTime? _retryAt;

  Future<LocalizedNarration> generate(String poiId, String lang) async {
    if (_retryAt != null && _clock().isBefore(_retryAt!)) {
      throw LocalizationFailure(statusCode: 429, retryAt: _retryAt);
    }
    final base = baseUrl().replaceFirst(RegExp(r'/+$'), '');
    final response = await _client
        .post(
          Uri.parse('$base/localizations/on-demand'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'poi_id': poiId, 'lang': lang}),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      final seconds = int.tryParse(response.headers['retry-after'] ?? '');
      if ({429, 503}.contains(response.statusCode) &&
          seconds != null &&
          seconds > 0) {
        _retryAt = _clock().add(Duration(seconds: seconds));
      }
      throw LocalizationFailure(
        statusCode: response.statusCode,
        retryAt: _retryAt,
      );
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic> ||
        body['lang'] != lang ||
        body['audio_status'] != 'completed' ||
        body['is_fallback'] != false) {
      throw const FormatException(
        'Localization is not ready in the requested language',
      );
    }
    for (final key in ['poi_id', 'title', 'translated_text', 'audio_url']) {
      if (body[key] is! String || (body[key] as String).trim().isEmpty) {
        throw const FormatException('Incomplete localization response');
      }
    }
    return LocalizedNarration(
      poiId: body['poi_id'] as String,
      lang: lang,
      title: body['title'] as String,
      text: body['translated_text'] as String,
      audioUrl: resolveAudioUrl(base, body['audio_url'] as String),
    );
  }

  void close() => _client.close();
}
