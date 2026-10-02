import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/geo_audio_manager.dart';
import '../../core/services/location_service.dart';
import '../../data/models/poi.dart';
import '../../data/remote/poi_api.dart';

class PoiDetailPage extends StatefulWidget {
  final Poi poi;
  final Position? userPosition;

  const PoiDetailPage({super.key, required this.poi, this.userPosition});

  @override
  State<PoiDetailPage> createState() => _PoiDetailPageState();
}

class _PoiDetailPageState extends State<PoiDetailPage> {
  bool _isLoadingContent = false;
  Map<String, dynamic>? _fullDetails;
  List<Map<String, dynamic>> _contents = [];
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadAdditionalDetails();
  }

  /// Load extra stall info and audio narration contents from backend
  Future<void> _loadAdditionalDetails() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      final token = AuthService.instance.accessToken ?? '';
      final details = await PoiApi.instance.getStall(widget.poi.id, token);
      final contents = await PoiApi.instance.getStallContents(
        widget.poi.id,
        token,
      );

      if (mounted) {
        setState(() {
          _fullDetails = details;
          _contents = contents;
          _isLoadingContent = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final poi = widget.poi;

    // Calculate distance
    String? distanceText;
    if (widget.userPosition != null) {
      final meters = LocationService.instance.calculateDistanceInMeters(
        widget.userPosition!.latitude,
        widget.userPosition!.longitude,
        poi.latitude,
        poi.longitude,
      );
      distanceText = LocationService.instance.formatDistance(meters);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Hero Image / Sliver App Bar
          SliverAppBar(
            expandedHeight: 260.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                poi.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  poi.coverImage != null && poi.coverImage!.isNotEmpty
                      ? Image.network(
                          poi.coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildCoverPlaceholder(),
                        )
                      : _buildCoverPlaceholder(),
                  // Dark Gradient Overlay for text legibility
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                tooltip: 'Lưu yêu thích',
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isFavorite
                            ? 'Đã thêm ${poi.name} vào Yêu thích'
                            : 'Đã xóa khỏi danh sách Yêu thích',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),

          // 2. Body Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Rating Row
                  Row(
                    children: [
                      if (poi.category != null && poi.category!.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.category, size: 16),
                          label: Text(poi.category!),
                          backgroundColor: Colors.orange.withValues(
                            alpha: 0.15,
                          ),
                          side: BorderSide.none,
                          labelStyle: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const Spacer(),
                      if (poi.averageRating != null) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          poi.averageRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (poi.totalReviews != null)
                          Text(
                            ' (${poi.totalReviews} đánh giá)',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Bar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await GeoAudioManager.instance.enterPoi(poi);
                            await GeoAudioManager.instance.playContent(0);
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Phát Thuyết Minh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang mở bản đồ chỉ đường...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Chỉ đường'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFullAudioPlayer(context),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Info Cards (Opening Hours, Phone, Distance, Price)
                  const Text(
                    'Thông tin chi tiết',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (distanceText != null)
                    _buildInfoTile(
                      icon: Icons.directions_walk,
                      title: 'Khoảng cách từ bạn',
                      subtitle: distanceText,
                    ),

                  if (poi.openingHours != null && poi.openingHours!.isNotEmpty)
                    _buildInfoTile(
                      icon: Icons.access_time_filled,
                      title: 'Giờ mở cửa',
                      subtitle: poi.openingHours!,
                    ),

                  if (poi.contactPhone != null && poi.contactPhone!.isNotEmpty)
                    _buildInfoTile(
                      icon: Icons.phone,
                      title: 'Số điện thoại',
                      subtitle: poi.contactPhone!,
                    ),

                  if (poi.priceRange != null && poi.priceRange!.isNotEmpty)
                    _buildInfoTile(
                      icon: Icons.monetization_on,
                      title: 'Khoảng giá',
                      subtitle: poi.priceRange!,
                    ),

                  if (_fullDetails != null &&
                      _fullDetails!['owner_name'] != null &&
                      _fullDetails!['owner_name'].toString().isNotEmpty)
                    _buildInfoTile(
                      icon: Icons.person,
                      title: 'Chủ gian hàng / Quản lý',
                      subtitle: _fullDetails!['owner_name'].toString(),
                    ),

                  if (poi.website != null && poi.website!.isNotEmpty)
                    _buildInfoTile(
                      icon: Icons.language,
                      title: 'Website / Trang chủ',
                      subtitle: poi.website!,
                    ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Additional Narration / Story Contents
                  Row(
                    children: [
                      const Text(
                        'Nội dung thuyết minh',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoadingContent) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_contents.isNotEmpty)
                    ..._contents.map((content) {
                      final title = content['title'] ?? poi.name;
                      final description =
                          content['text_content'] ??
                          content['description'] ??
                          'Chưa có bài viết mô tả chi tiết.';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                description.toString(),
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                  else
                    Card(
                      color: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Ứng dụng Ẩm thực Đường phố - Lắng nghe thuyết minh và khám phá nét văn hóa đặc sắc tại địa điểm này.',
                          style: TextStyle(color: Colors.black87, height: 1.4),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullAudioPlayer(BuildContext context) {
    final manager = GeoAudioManager.instance;

    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.orange.shade50,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  manager.currentTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                // Slider tiến trình & Thời gian
                StreamBuilder<Duration>(
                  stream: manager.positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    final dur = manager.currentDuration ?? Duration.zero;
                    final maxSec = dur.inSeconds > 0
                        ? dur.inSeconds.toDouble()
                        : 1.0;
                    final currentSec = pos.inSeconds.toDouble().clamp(
                      0.0,
                      maxSec,
                    );

                    return Column(
                      children: [
                        Slider(
                          value: currentSec,
                          max: maxSec,
                          activeColor: Colors.orange,
                          onChanged: (val) {
                            manager.seek(Duration(seconds: val.toInt()));
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(pos),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _formatDuration(dur),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Bộ nút điều khiển: Tua lùi 10s, Play/Pause, Tua tới 10s
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      iconSize: 32,
                      onPressed: () => manager.seekBackward(seconds: 10),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        manager.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                      ),
                      iconSize: 56,
                      color: Colors.orange,
                      onPressed: () => manager.togglePlay(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      iconSize: 32,
                      onPressed: () => manager.seekForward(seconds: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.fastfood, size: 80, color: Colors.grey),
      ),
    );
  }
}
