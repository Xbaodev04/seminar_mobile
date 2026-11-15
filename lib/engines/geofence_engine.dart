import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/services/location_service.dart';
import '../data/models/poi.dart';
import 'narration_engine.dart';

class GeofenceEngine {
  static final GeofenceEngine instance = GeofenceEngine._private();

  StreamSubscription<Position>? _positionSub;
  Timer? _safetyTimer;

  List<Poi> _nearbyPois = [];
  final Map<String, DateTime> _enterCandidates = {};
  String? _currentPlayingPoiId;

  GeofenceEngine._private();

  void start() {
    _positionSub?.cancel();
    _positionSub = LocationService.instance.getPositionStream().listen((pos) {
      _onPositionUpdate(pos);
    });

    _safetyTimer?.cancel();
    _safetyTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _reconcileLoop();
    });
  }

  void stop() {
    _positionSub?.cancel();
    _positionSub = null;
    _safetyTimer?.cancel();
    _safetyTimer = null;
    _enterCandidates.clear();
    _currentPlayingPoiId = null;
  }

  void updatePois(List<Poi> pois) {
    _nearbyPois = pois;
  }

  void _onPositionUpdate(Position pos) {
    _reconcileLoop(currentPos: pos);
  }

  Future<void> _reconcileLoop({Position? currentPos}) async {
    final pos =
        currentPos ?? await LocationService.instance.getCurrentPosition();
    if (pos == null) return;

    if (NarrationEngine.instance.isPlaying ||
        NarrationEngine.instance.isPreparing) {
      return;
    }

    final now = DateTime.now();
    final candidatePois = <Poi>[];

    for (final poi in _nearbyPois) {
      if (poi.latitude == 0.0 || poi.longitude == 0.0) continue;

      final dist = LocationService.instance.calculateDistanceInMeters(
        pos.latitude,
        pos.longitude,
        poi.latitude,
        poi.longitude,
      );

      final radius = (poi.radius != null && poi.radius! > 0)
          ? poi.radius!.toDouble()
          : 30.0;

      if (dist <= radius) {
        if (!_enterCandidates.containsKey(poi.id)) {
          _enterCandidates[poi.id] = now;
        } else {
          final enterTime = _enterCandidates[poi.id]!;
          if (now.difference(enterTime).inSeconds >= 3) {
            candidatePois.add(poi);
          }
        }
      } else {
        _enterCandidates.remove(poi.id);
      }
    }

    if (candidatePois.isEmpty) return;

    candidatePois.sort((a, b) {
      final pA = a.audioPriority ?? 0;
      final pB = b.audioPriority ?? 0;
      if (pA != pB) {
        return pB.compareTo(pA);
      }
      final distA = LocationService.instance.calculateDistanceInMeters(
        pos.latitude,
        pos.longitude,
        a.latitude,
        a.longitude,
      );
      final distB = LocationService.instance.calculateDistanceInMeters(
        pos.latitude,
        pos.longitude,
        b.latitude,
        b.longitude,
      );
      return distA.compareTo(distB);
    });

    final bestPoi = candidatePois.first;

    if (_currentPlayingPoiId == bestPoi.id) return;

    debugPrint(
      '[GeofenceEngine] Confirm ENTER: \${bestPoi.name} (Priority: \${bestPoi.audioPriority})',
    );
    _currentPlayingPoiId = bestPoi.id;

    // Auto Play via NarrationEngine
    await NarrationEngine.instance.enterPoi(bestPoi, autoPlay: true);
  }
}
