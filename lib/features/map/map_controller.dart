import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/poi.dart';

class MapFeatureController {
  final MapController mapController = MapController();

  // District 4, HCMC Map Bounds (South-West to North-East)
  final LatLngBounds district4Bounds = LatLngBounds(
    const LatLng(10.7430, 106.6900),
    const LatLng(10.7720, 106.7150),
  );

  // Zoom limits focused on District 4
  final double minZoom = 14.0;
  final double maxZoom = 18.0;

  LatLng getDefaultCenter(List<Poi> pois) {
    if (pois.isEmpty) return const LatLng(10.7580, 106.7020);
    return LatLng(pois[0].latitude, pois[0].longitude);
  }

  double _clampZoom(double z) =>
      z < minZoom ? minZoom : (z > maxZoom ? maxZoom : z);

  void moveToPoi(Poi poi, {double zoom = 16.0}) {
    final z = _clampZoom(zoom);
    mapController.move(LatLng(poi.latitude, poi.longitude), z);
  }

  /// Move the map to an arbitrary LatLng
  void moveToLatLng(LatLng pos, {double zoom = 16.0}) {
    final z = _clampZoom(zoom);
    mapController.move(pos, z);
  }
}
