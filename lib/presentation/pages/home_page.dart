import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/geo_audio_manager.dart';
import '../../core/services/location_service.dart';
import '../../data/local/mock_pois.dart';
import '../../data/models/poi.dart';
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
  int _currentIndex = 0;
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
          _pois = fetchedPois.isNotEmpty ? fetchedPois : mockPois;
          _isLoadingPois = false;
        });
      }
    } catch (e) {
      // Gracefully fallback to local search on mock POIs if API call fails
      if (mounted) {
        final q = (search ?? '').toLowerCase().trim();
        final filteredMock = q.isEmpty
            ? mockPois
            : mockPois.where((poi) {
                final nameMatches = poi.name.toLowerCase().contains(q);
                final catMatches =
                    poi.category != null &&
                    poi.category!.toLowerCase().contains(q);
                return nameMatches || catMatches;
              }).toList();

        setState(() {
          _pois = filteredMock;
          _isLoadingPois = false;
        });
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
                          onPoiTapped: _onPoiTapped,
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
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 1) {
                // Không đổi _currentIndex vì ta push sang 1 màn hình hoàn toàn mới
                Navigator.pushNamed(context, '/profile');
              } else {
                setState(() => _currentIndex = index);
              }
            },
          ),
        ],
      ),
    );
  }
}
