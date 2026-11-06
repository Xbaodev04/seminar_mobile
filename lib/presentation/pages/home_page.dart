import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/geo_audio_manager.dart';
import '../../core/services/location_service';
import '../../data/remote/poi_api.dart';
import '../../features/map/map_controller.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/home_loading_overlay.dart';
import '../widgets/home_map_view.dart';
import '../widgets/home_poi_list_view.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/mini_player_widget.dart';
import '../widgets/poi_quick_view_sheet.dart';
import 'poi_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isMapView =
      true; // Toggle between Map View (true) and List View (false)

  final MapFeatureController _mapFeatureController = MapFeatureController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Default Position fallback for District 4 when GPS is unavailable or on Emulator
  static final Position _defaultPosition = Position(
    latitude: LocationService.defaultLatitude,
    longitude: LocationService.defaultLongitude,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );

  Position? _currentPosition = _defaultPosition;
  StreamSubscription<Position>? _positionStreamSub;

  List<Poi> _pois = [];
  String _searchQuery = '';
  bool _isLoadingPois = false;
  bool _isLoadingLocation = true;
  Poi? _selectedPoi;
  LatLng? _tappedPosition;

  // Default fallback center (District 4, Ho Chi Minh City)
  static final LatLng _defaultCenter = LatLng(
    LocationService.defaultLatitude,
    LocationService.defaultLongitude,
  );

  @override
  void initState() {
    super.initState();
    _initLocationAndPois();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _positionStreamSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Check if the GPS position is within Vietnam bounds
  bool _isInVietnam(Position pos) {
    return pos.latitude >= 8.0 &&
        pos.latitude <= 24.0 &&
        pos.longitude >= 102.0 &&
        pos.longitude <= 110.0;
  }

  /// Initialize user location tracking and fetch POIs
  Future<void> _initLocationAndPois() async {
    setState(() {
      _isLoadingLocation = true;
    });

    // 1. Get current position with fallback to District 4 if GPS is unavailable or outside Vietnam (e.g. Emulator)
    Position? position = await LocationService.instance.getCurrentPosition();
    if (position == null || !_isInVietnam(position)) {
      position = _defaultPosition;
    }

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _mapFeatureController.moveToLatLng(
        LatLng(position.latitude, position.longitude),
        zoom: 15.5,
      );
    }

    // 2. Start listening to position stream for real-time tracking
    _positionStreamSub = LocationService.instance.getPositionStream().listen((
      newPos,
    ) {
      if (mounted) {
        setState(() {
          _currentPosition = _isInVietnam(newPos) ? newPos : _defaultPosition;
        });
      }
    });

    // 3. Fetch POIs from API (or fallback to mock data)
    await _fetchPois();
  }

  /// Fetch POIs from backend API with optional search query
  Future<void> _fetchPois({String? search}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingPois = true;
    });

    try {
      final token = AuthService.instance.accessToken ?? '';
      final lat = _currentPosition?.latitude ?? LocationService.defaultLatitude;
      final lng =
          _currentPosition?.longitude ?? LocationService.defaultLongitude;

      final rawList = await PoiApi.instance.listStalls(
        token,
        search: search,
        latitude: lat,
        longitude: lng,
        limit: 30,
      );

      final fetchedPois = rawList.map((map) => Poi.fromJson(map)).toList();

      if (mounted) {
        setState(() {
          _pois = fetchedPois; // Chỉ dùng dữ liệu thật từ Backend
          _isLoadingPois = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Nếu lỗi, không dùng mock nữa, chỉ báo rỗng và tắt loading
        setState(() {
          _pois = [];
          _isLoadingPois = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kết nối đến máy chủ: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Debounced search handler: triggers Backend API call after 500ms pause in typing
  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchPois(search: val.trim());
    });
  }

  /// Clear search field and re-fetch all POIs
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _fetchPois();
  }

  /// Center map on user current position (handles 3 scenarios for optimal UX)
  void _recenterOnUser() async {
    Position? newPosition = await LocationService.instance.getCurrentPosition();

    if (!mounted) return;

    if (newPosition != null && !_isInVietnam(newPosition)) {
      newPosition = _defaultPosition;
    }

    if (newPosition != null) {
      // Trường hợp 1: Thành công lấy vị trí mới
      setState(() {
        _currentPosition = newPosition;
      });
      _mapFeatureController.moveToLatLng(
        LatLng(newPosition.latitude, newPosition.longitude),
        zoom: 16.0,
      );
    } else if (_currentPosition != null) {
      // Trường hợp 2: Thất bại lấy vị trí mới NHƯNG đã có vị trí cũ
      _mapFeatureController.moveToLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 16.0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể cập nhật vị trí mới. Đang dùng vị trí gần nhất.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Trường hợp 3: Thất bại hoàn toàn -> Gán vị trí mặc định Quận 4
      setState(() {
        _currentPosition = _defaultPosition;
      });
      _mapFeatureController.moveToLatLng(_defaultCenter, zoom: 15.5);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể lấy vị trí GPS. Đã đặt vị trí mặc định tại Quận 4.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Open quick view sheet and move camera when a POI marker/suggestion is tapped
  void _onPoiTapped(Poi poi) {
    setState(() {
      _selectedPoi = poi;
      if (poi.latitude != 0.0 && poi.longitude != 0.0) {
        _tappedPosition = LatLng(poi.latitude, poi.longitude);
      }
    });

    if (poi.latitude != 0.0 && poi.longitude != 0.0) {
      _mapFeatureController.moveToPoi(poi, zoom: 16.5);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PoiQuickViewSheet(
        poi: poi,
        userPosition: _currentPosition,
        onTapDetail: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PoiDetailPage(poi: poi, userPosition: _currentPosition),
            ),
          );
        },
      ),
    );
  }

  /// Khi người dùng chạm vào một điểm bất kỳ trên bản đồ:
  /// 1. Đặt marker tại vị trí vừa chạm
  /// 2. Tính khoảng cách đến tất cả quán ăn đã load
  /// 3. So sánh với bán kính kích hoạt (trigger_radius) của quán gần nhất
  /// 4. Nếu nằm trong bán kính -> Tự động bật thuyết minh audio quán đó
  Future<void> _onMapTapped(LatLng point) async {
    setState(() {
      _tappedPosition = point;
    });

    if (_pois.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa có dữ liệu quán ăn trên bản đồ để tính khoảng cách.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    const distanceCalculator = Distance();
    Poi? nearestPoi;
    double minDistance = double.infinity;

    for (final poi in _pois) {
      if (poi.latitude == 0.0 && poi.longitude == 0.0) continue;
      final d = distanceCalculator.as(
        LengthUnit.Meter,
        point,
        LatLng(poi.latitude, poi.longitude),
      );
      if (d < minDistance) {
        minDistance = d;
        nearestPoi = poi;
      }
    }

    if (nearestPoi == null) return;

    final effectiveRadius =
        (nearestPoi.radius != null && nearestPoi.radius! > 0)
        ? nearestPoi.radius!.toDouble()
        : 30.0;

    final isWithinRadius = minDistance <= effectiveRadius;

    if (isWithinRadius) {
      setState(() {
        _selectedPoi = nearestPoi;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.volume_up, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Điểm chọn cách "${nearestPoi.name}" ${minDistance.round()}m (trong bán kính ${effectiveRadius.round()}m). Đang tự động thuyết minh...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Chi tiết',
            textColor: Colors.white,
            onPressed: () => _onPoiTapped(nearestPoi!),
          ),
        ),
      );

      // Tự động tải nội dung và phát thuyết minh audio
      await GeoAudioManager.instance.enterPoi(nearestPoi, autoPlay: true);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Điểm chọn cách quán gần nhất "${nearestPoi.name}" ${minDistance.round()}m (ngoài bán kính thuyết minh ${effectiveRadius.round()}m).',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.map, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Street Food Go',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Toggle Map / List view icon button
          IconButton(
            icon: Icon(_isMapView ? Icons.format_list_bulleted : Icons.map),
            tooltip: _isMapView ? 'Xem dạng Danh sách' : 'Xem dạng Bản đồ',
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
            onPressed: () {
              _initLocationAndPois();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Main Content Area (Map View or List View)
          Positioned.fill(
            child: Column(
              children: [
                // Top margin spacer for the floating search bar
                const SizedBox(height: 68),
                Expanded(
                  child: Stack(
                    children: [
                      if (_isMapView)
                        // Map View Mode
                        HomeMapView(
                          mapFeatureController: _mapFeatureController,
                          initialCenter: initialCenter,
                          currentPosition: _currentPosition,
                          pois: _pois,
                          selectedPoi: _selectedPoi,
                          tappedPosition: _tappedPosition,
                          onPoiTapped: _onPoiTapped,
                          onMapTapped: _onMapTapped,
                        )
                      else
                        // List View Mode
                        HomePoiListView(
                          pois: _pois,
                          userPosition: _currentPosition,
                          onPoiTapped: _onPoiTapped,
                        ),

                      // Loading Overlay Indicator when calling API
                      HomeLoadingOverlay(
                        isLoading: _isLoadingPois || _isLoadingLocation,
                      ),

                      // Floating Action Button to Recenter GPS (Map View Mode)
                      if (_isMapView)
                        Positioned(
                          right: 16,
                          bottom: 24,
                          child: FloatingActionButton(
                            heroTag: 'recenter_gps_fab',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            onPressed: _recenterOnUser,
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Bar Widget with AutoComplete Suggestions Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeSearchBar(
              searchController: _searchController,
              searchQuery: _searchQuery,
              suggestions: _pois,
              userPosition: _currentPosition,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
              onSuggestionSelected: _onPoiTapped,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayerWidget(
            onTap: () {
              final poi = GeoAudioManager.instance.currentPoi;
              if (poi != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PoiDetailPage(poi: poi)),
                );
              }
            },
          ),
          AppBottomNav(
            currentIndex: 0,
            onTap: (index) {
              if (index == 1) {
                Navigator.pushReplacementNamed(context, '/listening_history');
              } else if (index == 2) {
                Navigator.pushReplacementNamed(context, '/profile');
              }
            },
          ),
        ],
      ),
    );
  }
}
