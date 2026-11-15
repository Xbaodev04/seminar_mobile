/// The API distinguishes an existing unpublished POI from a missing QR target.
class PoiNotPublicException implements Exception {
  static const message = 'Quán đã đóng cửa';

  const PoiNotPublicException();

  @override
  String toString() => message;
}

void requirePublicPoi(Map<String, dynamic> data) {
  if (data['is_active'] == false) {
    throw const PoiNotPublicException();
  }
}
