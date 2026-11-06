import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:seminar_mobile/core/services/locale_provider.dart';

import '../../core/services/auth_service.dart';
import 'api_client.dart';
import 'http_client.dart';

class PoiApi {
  PoiApi._private();
  static final PoiApi instance = PoiApi._private();

  static const _timeout = Duration(seconds: 30);

  Uri _uri(String path) => Uri.parse('${ApiClient.instance.baseUrl}$path');

  /// Fetches POIs from backend API trying candidate path variations
  Future<List<Map<String, dynamic>>> listPois(
    String accessToken, {
    String? search,
    double? latitude,
    double? longitude,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
      queryParams['keyword'] = search;
    }

    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['lat'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
      queryParams['lng'] = longitude.toString();
    }

    // Candidate URL paths (ưu tiên /pois chuẩn mới, fallback /stalls)
    final candidatePaths = [
      '/mobile/pois',
      '/mobile/pois/',
      '/api/v1/mobile/pois',
      '/mobile/stalls',
      '/mobile/stalls/',
      '/api/v1/mobile/stalls',
    ];

    http.Response? lastResponse;

    for (final path in candidatePaths) {
      final uri = _uri(path).replace(queryParameters: queryParams);
      try {
        final headers = <String, String>{
          'Accept-Language':
              LocaleProvider.instance.locale?.languageCode ??
              (PlatformDispatcher.instance.locale.languageCode),
          'Accept': 'application/json',
        };

        final deviceId = AuthService.instance.deviceId;
        if (deviceId.isNotEmpty) {
          headers['X-Device-Id'] = deviceId;
        }

        if (accessToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $accessToken';
        }

        final res = await HttpClientWithTokenRefresh.instance.get(
          uri,
          headers: headers,
          timeout: _timeout,
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map) {
            if (body['data'] is List) {
              return List<Map<String, dynamic>>.from(body['data'] as List);
            } else if (body['data'] is Map && body['data']['items'] is List) {
              return List<Map<String, dynamic>>.from(
                body['data']['items'] as List,
              );
            } else if (body['items'] is List) {
              return List<Map<String, dynamic>>.from(body['items'] as List);
            } else if (body['poi'] is List) {
              return List<Map<String, dynamic>>.from(body['poi'] as List);
            } else {
              // Fallback for FastAPI standard pagination response without explicit 'items' wrapper
              // Check if keys contain standard dict items but missing 'items' explicitly
              try {
                return [Map<String, dynamic>.from(body)];
              } catch (_) {}
            }
          } else if (body is List) {
            return List<Map<String, dynamic>>.from(body);
          }
          return <Map<String, dynamic>>[];
        }
        lastResponse = res;
      } catch (_) {
        // Continue trying next candidate path
      }
    }

    if (lastResponse != null && lastResponse.statusCode >= 400) {
      throw Exception(_parseError(lastResponse));
    }
    return <Map<String, dynamic>>[];
  }

  /// Alias tương thích ngược cho listStalls
  Future<List<Map<String, dynamic>>> listStalls(
    String accessToken, {
    String? search,
    double? latitude,
    double? longitude,
    int limit = 20,
    int offset = 0,
  }) => listPois(
    accessToken,
    search: search,
    latitude: latitude,
    longitude: longitude,
    limit: limit,
    offset: offset,
  );

  /// Fetches content for a POI
  Future<List<Map<String, dynamic>>> getPoiContents(
    String poiId,
    String accessToken,
  ) async {
    final candidatePaths = [
      '/mobile/pois/$poiId/content',
      '/mobile/pois/$poiId/content/',
      '/api/v1/mobile/pois/$poiId/content',
      '/mobile/stalls/$poiId/content',
      '/mobile/stalls/$poiId/content/',
      '/api/v1/mobile/stalls/$poiId/content',
    ];

    for (final path in candidatePaths) {
      try {
        final headers = <String, String>{
          'Accept-Language':
              LocaleProvider.instance.locale?.languageCode ??
              (PlatformDispatcher.instance.locale.languageCode),
          'Accept': 'application/json',
        };
        final deviceId = AuthService.instance.deviceId;
        if (deviceId.isNotEmpty) {
          headers['X-Device-Id'] = deviceId;
        }

        if (accessToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $accessToken';
        }

        final res = await HttpClientWithTokenRefresh.instance.get(
          _uri(path),
          headers: headers,
          timeout: _timeout,
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map && body['data'] != null) {
            if (body['data'] is List) {
              return List<Map<String, dynamic>>.from(body['data'] as List);
            }
            return [body['data'] as Map<String, dynamic>];
          } else if (body is List) {
            return List<Map<String, dynamic>>.from(body);
          }
          return <Map<String, dynamic>>[];
        }
      } catch (_) {
        // Try next candidate
      }
    }

    return <Map<String, dynamic>>[];
  }

  /// Fetches content for all POIs based on language
  Future<List<Map<String, dynamic>>> loadAllPoiContents(
    String accessToken,
  ) async {
    final candidatePaths = [
      '/mobile/content/load-all',
      '/mobile/content/load-all/',
      '/api/v1/mobile/content/load-all',
    ];

    for (final path in candidatePaths) {
      try {
        final headers = <String, String>{
          'Accept-Language':
              LocaleProvider.instance.locale?.languageCode ??
              (PlatformDispatcher.instance.locale.languageCode),
          'Accept': 'application/json',
        };
        final deviceId = AuthService.instance.deviceId;
        if (deviceId.isNotEmpty) {
          headers['X-Device-Id'] = deviceId;
        }

        if (accessToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $accessToken';
        }

        final res = await HttpClientWithTokenRefresh.instance.get(
          _uri(path),
          headers: headers,
          timeout: _timeout,
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map && body['data'] != null) {
            if (body['data'] is List) {
              return List<Map<String, dynamic>>.from(body['data'] as List);
            }
          } else if (body is List) {
            return List<Map<String, dynamic>>.from(body);
          }
          return <Map<String, dynamic>>[];
        }
      } catch (_) {
        // Try next candidate
      }
    }

    return <Map<String, dynamic>>[];
  }

  /// Fetches nearby unlistened content
  Future<List<Map<String, dynamic>>> getNearbyContent(
    String accessToken, {
    required double latitude,
    required double longitude,
  }) async {
    final queryParams = <String, String>{
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    final candidatePaths = [
      '/mobile/content/nearby',
      '/mobile/content/nearby/',
      '/api/v1/mobile/content/nearby',
    ];

    for (final path in candidatePaths) {
      final uri = _uri(path).replace(queryParameters: queryParams);
      try {
        final headers = <String, String>{
          'Accept-Language':
              LocaleProvider.instance.locale?.languageCode ??
              (PlatformDispatcher.instance.locale.languageCode),
          'Accept': 'application/json',
        };
        final deviceId = AuthService.instance.deviceId;
        if (deviceId.isNotEmpty) {
          headers['X-Device-Id'] = deviceId;
        }

        if (accessToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $accessToken';
        }

        final res = await HttpClientWithTokenRefresh.instance.get(
          uri,
          headers: headers,
          timeout: _timeout,
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map) {
            if (body['data'] is List) {
              return List<Map<String, dynamic>>.from(body['data'] as List);
            } else if (body['data'] is Map && body['data']['items'] is List) {
              return List<Map<String, dynamic>>.from(
                body['data']['items'] as List,
              );
            } else if (body['items'] is List) {
              return List<Map<String, dynamic>>.from(body['items'] as List);
            }
          } else if (body is List) {
            return List<Map<String, dynamic>>.from(body);
          }
          return <Map<String, dynamic>>[];
        }
      } catch (_) {
        // Try next candidate
      }
    }

    return <Map<String, dynamic>>[];
  }

  /// Alias tương thích ngược cho getStallContents
  Future<List<Map<String, dynamic>>> getStallContents(
    String stallId,
    String accessToken,
  ) => getPoiContents(stallId, accessToken);

  /// Fetches detail for a single POI
  Future<Map<String, dynamic>?> getPoi(String poiId, String accessToken) async {
    final candidatePaths = [
      '/mobile/pois/$poiId',
      '/mobile/pois/$poiId/',
      '/api/v1/mobile/pois/$poiId',
      '/mobile/stalls/$poiId',
      '/mobile/stalls/$poiId/',
      '/api/v1/mobile/stalls/$poiId',
    ];

    for (final path in candidatePaths) {
      try {
        final headers = <String, String>{
          'Accept-Language':
              LocaleProvider.instance.locale?.languageCode ??
              (PlatformDispatcher.instance.locale.languageCode),
          'Accept': 'application/json',
        };
        final deviceId = AuthService.instance.deviceId;
        if (deviceId.isNotEmpty) {
          headers['X-Device-Id'] = deviceId;
        }

        if (accessToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $accessToken';
        }

        final res = await HttpClientWithTokenRefresh.instance.get(
          _uri(path),
          headers: headers,
          timeout: _timeout,
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map && body['data'] != null) {
            return body['data'] as Map<String, dynamic>;
          } else if (body is Map<String, dynamic>) {
            return body;
          }
          return null;
        }
      } catch (_) {
        // Try next candidate
      }
    }

    return null;
  }

  /// Alias tương thích ngược cho getStall
  Future<Map<String, dynamic>?> getStall(String stallId, String accessToken) =>
      getPoi(stallId, accessToken);

  String _parseError(http.Response res) {
    String raw;
    try {
      raw = utf8.decode(res.bodyBytes);
    } catch (_) {
      try {
        raw = latin1.decode(res.bodyBytes);
      } catch (_) {
        raw = res.body;
      }
    }

    String fixMojibake(String s) {
      if (s.contains('Ã') || s.contains('Â') || s.contains('\uFFFD')) {
        try {
          final bytes = latin1.encode(s);
          return utf8.decode(bytes);
        } catch (_) {
          return s;
        }
      }
      return s;
    }

    try {
      final body = jsonDecode(raw);

      if (body is Map) {
        if (body['message'] != null && body['message'].toString().isNotEmpty) {
          return fixMojibake(body['message'].toString());
        }
        if (body['error'] != null && body['error'].toString().isNotEmpty) {
          return fixMojibake(body['error'].toString());
        }
        if (body['detail'] != null) {
          return fixMojibake(body['detail'].toString());
        }
      }
      return 'HTTP ${res.statusCode}: ${fixMojibake(raw)}';
    } catch (_) {
      return 'HTTP ${res.statusCode}';
    }
  }
}
