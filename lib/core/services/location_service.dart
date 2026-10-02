import 'package:geolocator/geolocator.dart';

/// Service managing GPS location access, permissions, and position tracking.
class LocationService {
  LocationService._private();
  static final LocationService instance = LocationService._private();

  /// Default fallback location (District 4, Ho Chi Minh City) if GPS is unavailable
  static const double defaultLatitude = 10.7580;
  static const double defaultLongitude = 106.7020;

  /// Check if GPS location service is enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission from the user
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Check location service and permissions, requesting permission if needed.
  /// Returns `true` if location access is granted and available.
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Fetch the current device position.
  /// Returns `null` if location services are disabled or permission is denied.
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    bool hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit ?? const Duration(seconds: 15),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Stream of real-time position updates
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return Geolocator.getPositionStream(
      locationSettings:
          locationSettings ??
          const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Minimum change in meters to trigger update
          ),
    );
  }

  /// Calculate distance in meters between two lat/long coordinates
  double calculateDistanceInMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Utility to format distance into human-readable text (e.g. "350 m" or "2.4 km")
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}
