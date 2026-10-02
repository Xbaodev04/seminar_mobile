import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/poi.dart';

class MapFeatureController {
  final MapController mapController = MapController();

  // Zoom limits to prevent over-zooming that may hide tiles
  final double minZoom = 3.0;
  final double maxZoom = 18.0;

  LatLng getDefaultCenter(List<Poi> pois) {
    if (pois.isEmpty) return LatLng(10.762622, 106.660172);
    return LatLng(pois[0].latitude, pois[0].longitude);
  }

  double _clampZoom(double z) => z < minZoom ? minZoom : (z > maxZoom ? maxZoom : z);

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
