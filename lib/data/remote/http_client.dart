import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:seminar_mobile/core/services/auth_service.dart';

/// HTTP client wrapper that automatically handles token refresh on 401 responses
class HttpClientWithTokenRefresh {
  HttpClientWithTokenRefresh._private();
  static final HttpClientWithTokenRefresh instance = HttpClientWithTokenRefresh._private();

  static const _defaultTimeout = Duration(seconds: 60);

  /// Makes a GET request with automatic token refresh on 401
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(timeout);
      
      // Handle 401 - try to refresh token and retry once
      if (response.statusCode == 401) {
        final refreshed = await AuthService.instance.refreshAccessToken();
        if (refreshed) {
          // Retry the request with the new token
          return await http.get(url, headers: headers).timeout(timeout);
        }
      }
      return response;
    } on TimeoutException {
      throw Exception('Request timed out. Please check network or server.');
    }
  }

  /// Makes a POST request with automatic token refresh on 401
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(timeout);
      
      // Handle 401 - try to refresh token and retry once
      if (response.statusCode == 401) {
        final refreshed = await AuthService.instance.refreshAccessToken();
        if (refreshed) {
          // Retry the request with the new token
          return await http.post(url, headers: headers, body: body).timeout(timeout);
        }
      }
      return response;
    } on TimeoutException {
      throw Exception('Request timed out. Please check network or server.');
    }
  }

  /// Makes a PUT request with automatic token refresh on 401
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      final response = await http
          .put(url, headers: headers, body: body)
          .timeout(timeout);
      
      // Handle 401 - try to refresh token and retry once
      if (response.statusCode == 401) {
        final refreshed = await AuthService.instance.refreshAccessToken();
        if (refreshed) {
          // Retry the request with the new token
          return await http.put(url, headers: headers, body: body).timeout(timeout);
        }
      }
      return response;
    } on TimeoutException {
      throw Exception('Request timed out. Please check network or server.');
    }
  }

  /// Makes a DELETE request with automatic token refresh on 401
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(timeout);
      
      // Handle 401 - try to refresh token and retry once
      if (response.statusCode == 401) {
        final refreshed = await AuthService.instance.refreshAccessToken();
        if (refreshed) {
          // Retry the request with the new token
          return await http.delete(url, headers: headers).timeout(timeout);
        }
      }
      return response;
    } on TimeoutException {
      throw Exception('Request timed out. Please check network or server.');
    }
  }
}
