import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  static final RouteService instance = RouteService._private();
  RouteService._private();

  Future<List<LatLng>> getRoute(LatLng start, LatLng destination) async {
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?geometries=geojson',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;
          return coordinates.map((coord) {
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
    return [];
  }
}
