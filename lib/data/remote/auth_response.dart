Map<String, dynamic> normalizeAuthTokens(Map<String, dynamic> response) {
  final data = response['data'] is Map
      ? Map<String, dynamic>.from(response['data'] as Map)
      : response;
  final access =
      response['accessToken'] ??
      response['access_token'] ??
      data['accessToken'] ??
      data['access_token'];
  final refresh =
      response['refreshToken'] ??
      response['refresh_token'] ??
      data['refreshToken'] ??
      data['refresh_token'];
  if (access is! String ||
      access.isEmpty ||
      refresh is! String ||
      refresh.isEmpty) {
    throw const FormatException(
      'Phản hồi đăng nhập thiếu access token hoặc refresh token',
    );
  }
  return {...response, 'accessToken': access, 'refreshToken': refresh};
}

Map<String, dynamic> normalizeAuthProfile(Map<String, dynamic> response) {
  var profile = response;
  for (var i = 0; i < 2; i++) {
    final nested = profile['data'] ?? profile['user'];
    if (nested is! Map) break;
    profile = Map<String, dynamic>.from(nested);
  }
  final id = profile['id'] ?? profile['_id'];
  if (id == null || id.toString().isEmpty || id == 'unknown') {
    throw const FormatException('Phản hồi tài khoản thiếu ID hợp lệ');
  }
  return {...profile, 'id': id.toString()};
}
