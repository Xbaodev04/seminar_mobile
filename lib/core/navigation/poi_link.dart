/// Canonical public QR URL: `https://<visitor-domain>/poi/<id>`.
/// Also accepts existing `/pois/<id>` and `?poi=<id>` links.
String? poiIdFromLocation(String location) {
  try {
    final uri = Uri.parse(location);
    final path = uri.fragment.startsWith('/') ? Uri.parse(uri.fragment) : uri;
    final segments = path.pathSegments;
    String? id;
    if (segments.length == 2 && {'poi', 'pois'}.contains(segments[0])) {
      id = segments[1];
    } else if (segments.isEmpty ||
        (segments.length == 1 && segments[0].isEmpty)) {
      id = path.queryParameters['poi'] ?? path.queryParameters['poi_id'];
    }
    return id != null && RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id)
        ? id
        : null;
  } on FormatException {
    return null;
  }
}

bool isQrLocation(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null) return false;
  final path = uri.fragment.startsWith('/') ? Uri.tryParse(uri.fragment) : uri;
  return path?.queryParameters['source'] == 'qr';
}

bool isPoiLocation(String location) {
  final uri = Uri.tryParse(location);
  return uri != null &&
      (uri.path == '/poi' ||
          uri.path.startsWith('/poi/') ||
          uri.path == '/pois' ||
          uri.path.startsWith('/pois/') ||
          uri.queryParameters.containsKey('poi') ||
          uri.queryParameters.containsKey('poi_id') ||
          uri.fragment.startsWith('/poi/'));
}
