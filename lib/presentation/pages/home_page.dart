import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/location_service.dart';
import '../../data/local/mock_pois.dart';
import '../../data/models/poi.dart';
import '../../data/remote/poi_api.dart';
import '../../features/map/map_controller.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/poi_card_item.dart';
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

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSub;

  List<Poi> _pois = [];
  String _searchQuery = '';
  bool _isLoadingPois = false;
  bool _isLoadingLocation = true;
  Poi? _selectedPoi;

  // Default fallback center (Ho Chi Minh City)
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

  /// Initialize user location tracking and fetch POIs
  Future<void> _initLocationAndPois() async {
    setState(() {
      _isLoadingLocation = true;
    });

    // 1. Get current position
    final position = await LocationService.instance.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      if (position != null) {
        _mapFeatureController.moveToLatLng(
          LatLng(position.latitude, position.longitude),
          zoom: 15.0,
        );
      }
    }

    // 2. Start listening to position stream for real-time tracking
    _positionStreamSub = LocationService.instance.getPositionStream().listen((
      newPos,
    ) {
      if (mounted) {
        setState(() {
          _currentPosition = newPos;
        });
      }
    });

    // 3. Fetch POIs from API (or fallback to mock data)
    await _fetchPois();
  }

  /// Fetch POIs from backend API with optional search query
  Future<void> _fetchPois({String? search}) async {
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

        // Automatically move camera to the first valid POI so pins are immediately visible
        final displayList = _pois;
        if (displayList.isNotEmpty) {
          final firstValidPoi = displayList.firstWhere(
            (p) => p.latitude != 0.0 && p.longitude != 0.0,
            orElse: () => displayList.first,
          );
          if (firstValidPoi.latitude != 0.0 && firstValidPoi.longitude != 0.0) {
            _mapFeatureController.moveToLatLng(
              LatLng(firstValidPoi.latitude, firstValidPoi.longitude),
              zoom: 15.0,
            );
          }
        }
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

  /// Center map on user current position
  void _recenterOnUser() {
    if (_currentPosition != null) {
      _mapFeatureController.moveToLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 16.0,
      );
    } else {
      _mapFeatureController.moveToLatLng(_defaultCenter, zoom: 15.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đang lấy vị trí GPS... Vui lòng kiểm tra quyền vị trí.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Open quick view sheet when a POI marker or card is tapped
  void _onPoiTapped(Poi poi) {
    setState(() {
      _selectedPoi = poi;
    });

    if (_isMapView) {
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
      body: Column(
        children: [
          // 1. Search Bar Widget with Backend API Integration
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm địa điểm, món ăn...',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Content Area (Map View or List View)
          Expanded(
            child: Stack(
              children: [
                if (_isMapView)
                  // Map View Mode
                  FlutterMap(
                    mapController: _mapFeatureController.mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: 15.0,
                      minZoom: _mapFeatureController.minZoom,
                      maxZoom: _mapFeatureController.maxZoom,
                    ),
                    children: [
                      // OpenStreetMap Tile Layer
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.seminar_mobile',
                      ),

                      // Markers Layer
                      MarkerLayer(
                        markers: [
                          // User Location Marker
                          if (_currentPosition != null)
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 44,
                              height: 44,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // POI Markers from Backend Search API
                          ..._pois.map((poi) {
                            final isSelected = _selectedPoi?.id == poi.id;
                            return Marker(
                              point: LatLng(poi.latitude, poi.longitude),
                              width: isSelected ? 48 : 40,
                              height: isSelected ? 48 : 40,
                              child: GestureDetector(
                                onTap: () => _onPoiTapped(poi),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.deepOrange
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.restaurant_rounded,
                                    color: Colors.white,
                                    size: isSelected ? 26 : 22,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  )
                else
                  // List View Mode
                  _pois.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Không tìm thấy địa điểm nào phù hợp',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: _pois.length,
                          itemBuilder: (ctx, idx) {
                            final poi = _pois[idx];
                            return PoiCardItem(
                              poi: poi,
                              userPosition: _currentPosition,
                              onTap: () => _onPoiTapped(poi),
                            );
                          },
                        ),

                // Loading Overlay Indicator when calling API
                if (_isLoadingPois || _isLoadingLocation)
                  Positioned(
                    top: 12,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Đang tìm kiếm dữ liệu từ server...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
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
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}
