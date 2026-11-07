import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/poi.dart';
import '../../features/map/map_controller.dart';

class HomeMapView extends StatelessWidget {
  final MapFeatureController mapFeatureController;
  final LatLng initialCenter;
  final Position? currentPosition;
  final List<Poi> pois;
  final Poi? selectedPoi;
  final LatLng? tappedPosition;
  final List<LatLng>? routePoints;
  final ValueChanged<Poi> onPoiTapped;
  final ValueChanged<LatLng>? onMapTapped;

  const HomeMapView({
    super.key,
    required this.mapFeatureController,
    required this.initialCenter,
    required this.currentPosition,
    required this.pois,
    required this.selectedPoi,
    this.tappedPosition,
    this.routePoints,
    required this.onPoiTapped,
    this.onMapTapped,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Tạo danh sách Marker tổng hợp
    final List<Marker> allMarkers = [];

    // 2. CHỈ add Marker "Vị trí bạn" NẾU currentPosition != null (Tuyệt đối không dùng initialCenter làm fallback)
    if (currentPosition != null) {
      allMarkers.add(
        Marker(
          point: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          width: 96,
          height: 56,
          alignment: Alignment.bottomCenter,
          // 3. Fix lỗi UI Text: Bọc bên trong Material transparency để tránh gạch chân vàng trên Canvas
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 3),
                      Text(
                        'Vị trí bạn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.blue.shade700,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Add Marker cho vị trí người dùng vừa click trên bản đồ (nếu có)
    if (tappedPosition != null) {
      allMarkers.add(
        Marker(
          point: tappedPosition!,
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    // 4. Thêm danh sách POI Markers vào allMarkers
    allMarkers.addAll(
      pois.map((poi) {
        final isSelected = selectedPoi?.id == poi.id;
        final size = isSelected ? 52.0 : 44.0;
        final hasCover = poi.coverImage != null && poi.coverImage!.isNotEmpty;

        return Marker(
          point: LatLng(poi.latitude, poi.longitude),
          width: size,
          height: size,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => onPoiTapped(poi),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepOrange : Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.deepOrange : Colors.white,
                  width: isSelected ? 3.0 : 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasCover
                    ? Image.network(
                        poi.coverImage!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: Colors.white,
                            size: isSelected ? 28 : 22,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: Colors.white,
                          size: isSelected ? 28 : 22,
                        ),
                      ),
              ),
            ),
          ),
        );
      }),
    );

    return FlutterMap(
      mapController: mapFeatureController.mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15.5,
        minZoom: mapFeatureController.minZoom,
        maxZoom: mapFeatureController.maxZoom,
        onTap: (tapPosition, point) {
          onMapTapped?.call(point);
        },
      ),
      children: [
        // OpenStreetMap Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.seminar_mobile',
        ),

        // Route Polyline Layer
        if (routePoints != null && routePoints!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints!,
                color: Colors.blueAccent,
                strokeWidth: 5.0,
              ),
            ],
          ),

        // Vòng tròn hiển thị bán kính (geofence radius) của POI đang được chọn/nghe
        if (selectedPoi != null &&
            selectedPoi!.latitude != 0.0 &&
            selectedPoi!.longitude != 0.0)
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(selectedPoi!.latitude, selectedPoi!.longitude),
                radius:
                    (selectedPoi!.radius != null && selectedPoi!.radius! > 0)
                    ? selectedPoi!.radius!.toDouble()
                    : 30.0,
                useRadiusInMeter: true,
                color: Colors.deepOrange.withValues(alpha: 0.18),
                borderColor: Colors.deepOrange,
                borderStrokeWidth: 2.0,
              ),
            ],
          ),

        // Truyền danh sách allMarkers cho MarkerLayer
        MarkerLayer(markers: allMarkers),
      ],
    );
  }
}
