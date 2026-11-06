import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seminar_mobile/data/remote/poi_api.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/geo_audio_manager.dart';
import '../../core/services/locale_provider.dart';
import '../../core/services/location_service.dart';
import '../../data/models/poi.dart';
import '../../engines/tts_engine.dart';

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

  /// Load extra stall info and audio narration contents from backend with auto translation
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

      final targetLang = LocaleProvider.instance.locale?.languageCode ?? 'vi';

      // Dynamic Translation for contents if user selected another language
      for (final content in contents) {
        final rawTitle = (content['title'] ?? widget.poi.name).toString();
        final rawText =
            (content['text_content'] ?? content['description'] ?? '')
                .toString();

        if (rawText.isNotEmpty && targetLang != 'en') {
          final translatedTitle = await TtsEngine.instance.translateText(
            text: rawTitle,
            targetLang: targetLang,
          );
          final translatedText = await TtsEngine.instance.translateText(
            text: rawText,
            targetLang: targetLang,
          );
          content['translated_title'] = translatedTitle;
          content['translated_text'] = translatedText;
        }
      }

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
          // 1. Sliver App Bar with Cover Image
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                poi.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
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
                        child: _isLoadingContent
                            ? ElevatedButton.icon(
                                onPressed: null,
                                icon: const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange,
                                  ),
                                ),
                                label: const Text('Đang tải bài nghe...'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              )
                            : _contents.isNotEmpty
                            ? ElevatedButton.icon(
                                onPressed: () async {
                                  await GeoAudioManager.instance.enterPoi(
                                    poi,
                                    initialContents: _contents,
                                  );
                                  await GeoAudioManager.instance.playContent(0);
                                },
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Phát Thuyết Minh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.music_off),
                                label: const Text('Chưa có bài nghe'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                      final title =
                          content['translated_title'] ??
                          content['title'] ??
                          poi.name;
                      final description =
                          content['translated_text'] ??
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

  Widget _buildCoverPlaceholder() {
    return Container(
      color: Colors.orange.shade100,
      child: const Center(
        child: Icon(Icons.restaurant, size: 64, color: Colors.orange),
      ),
    );
  }

  Widget _buildFullAudioPlayer(BuildContext context) {
    return ListenableBuilder(
      listenable: GeoAudioManager.instance,
      builder: (context, _) {
        final manager = GeoAudioManager.instance;
        final currentPoi = manager.currentPoi;
        final isCurrentPoi = currentPoi?.id == widget.poi.id;

        if (!isCurrentPoi) return const SizedBox.shrink();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.graphic_eq, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        manager.currentTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Audio Slider
                StreamBuilder<Duration>(
                  stream: manager.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = manager.currentDuration ?? Duration.zero;
                    final maxVal = duration.inMilliseconds.toDouble();
                    final currentVal = position.inMilliseconds.toDouble().clamp(
                      0.0,
                      maxVal > 0 ? maxVal : 1.0,
                    );

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: Slider(
                            value: currentVal,
                            max: maxVal > 0 ? maxVal : 1.0,
                            activeColor: Colors.orange,
                            inactiveColor: Colors.orange.shade100,
                            onChanged: (value) {
                              manager.seek(
                                Duration(milliseconds: value.toInt()),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  fontSize: 11,
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

                // Audio Controls (Rewind, Play/Pause, Fast Forward)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded),
                      iconSize: 28,
                      color: Colors.orange,
                      onPressed: () => manager.seekBackward(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        manager.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                      ),
                      iconSize: 48,
                      color: Colors.orange,
                      onPressed: () => manager.togglePlay(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded),
                      iconSize: 28,
                      color: Colors.orange,
                      onPressed: () => manager.seekForward(),
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
}
