import 'package:flutter/foundation.dart';

String defaultApiBaseUrl() {
  const configured = String.fromEnvironment('SEMINAR_API_BASE');
  if (configured.isNotEmpty) {
    return kIsWeb ? Uri.base.resolve(configured).toString() : configured;
  }
  return kIsWeb
      ? Uri.base.resolve('/api/v1').toString()
      : 'http://172.20.10.6:8000/api/v1';
}

/// Vercel HTTP rewrites do not proxy WebSockets. Supply the direct backend URL.
String? onlineStatusBaseUrl(String apiBase) {
  const direct = String.fromEnvironment('SEMINAR_WS_BASE');
  if (!kIsWeb) return apiBase;
  if (direct.isNotEmpty) return direct;
  return Uri.parse(apiBase).origin == Uri.base.origin ? null : apiBase;
}

String? resolveMediaUrl(String? value, String apiBase) {
  if (value == null || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (uri.hasScheme) {
    return uri.scheme == 'https' || uri.scheme == 'http' ? value : null;
  }
  if (uri.hasAuthority) return null;
  return Uri.parse(
    apiBase,
  ).resolve(value.startsWith('/') ? value : '/$value').toString();
}
