import 'package:flutter/material.dart';

import '../../core/services/geo_audio_manager.dart';
import '../../core/services/listening_history_service.dart';
import '../../data/models/poi.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mini_player_widget.dart';
import 'poi_detail_page.dart';

class ListeningHistoryPage extends StatefulWidget {
  const ListeningHistoryPage({super.key});

  @override
  State<ListeningHistoryPage> createState() => _ListeningHistoryPageState();
}

class _ListeningHistoryPageState extends State<ListeningHistoryPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ListeningHistoryService.instance.fetchHistory(
        page: 1,
        size: 30,
      );

      List<Map<String, dynamic>> items = [];
      if (res['data'] is List) {
        items = List<Map<String, dynamic>>.from(res['data'] as List);
      } else if (res['data'] is Map && res['data']['items'] is List) {
        items = List<Map<String, dynamic>>.from(res['data']['items'] as List);
      } else if (res['items'] is List) {
        items = List<Map<String, dynamic>>.from(res['items'] as List);
      } else if (res['results'] is List) {
        items = List<Map<String, dynamic>>.from(res['results'] as List);
      }

      if (mounted) {
        setState(() {
          _historyItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatListenedAt(dynamic raw) {
    if (raw == null) return '';
    try {
      DateTime dt;
      if (raw is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(
          raw > 10000000000 ? raw : raw * 1000,
        );
      } else if (raw is String) {
        final parsedInt = int.tryParse(raw);
        if (parsedInt != null) {
          dt = DateTime.fromMillisecondsSinceEpoch(
            parsedInt > 10000000000 ? parsedInt : parsedInt * 1000,
          );
        } else {
          dt = DateTime.parse(raw);
        }
      } else {
        return '';
      }
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$hour:$minute - $day/$month/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _formatDuration(dynamic raw) {
    if (raw == null) return '';
    int seconds = 0;
    if (raw is int) {
      seconds = raw;
    } else if (raw is String) {
      seconds = int.tryParse(raw) ?? 0;
    }
    if (seconds <= 0) return '';
    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return '$mins phút ${secs > 0 ? '$secs giây' : ''}';
    }
    return '$seconds giây';
  }

  void _navigateToPoiDetail(Map<String, dynamic> item) {
    final stallData = item['stall'] ?? item['poi'] ?? item;
    final stallId = (stallData['id'] ?? item['stall_id'] ?? '').toString();
    final name = (stallData['name'] ?? item['stall_name'] ?? 'Địa điểm')
        .toString();
    final lat =
        double.tryParse(
          (stallData['latitude'] ?? item['latitude'] ?? 0).toString(),
        ) ??
        0.0;
    final lng =
        double.tryParse(
          (stallData['longitude'] ?? item['longitude'] ?? 0).toString(),
        ) ??
        0.0;
    final coverImage = (stallData['cover_image'] ?? item['cover_image'] ?? '')
        .toString();

    final poi = Poi(
      id: stallId,
      name: name,
      latitude: lat,
      longitude: lng,
      coverImage: coverImage.isNotEmpty ? coverImage : null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PoiDetailPage(poi: poi)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.historyTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.loadHistoryError,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadHistory,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : _historyItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 72,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.noHistoryMessage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _historyItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _historyItems[index];
                  final stallData = item['stall'] ?? item['poi'] ?? item;
                  final stallName =
                      (stallData['name'] ??
                              item['stall_name'] ??
                              'Địa điểm ẩm thực')
                          .toString();
                  final contentTitle =
                      (item['content_title'] ??
                              item['title'] ??
                              item['stall_content_title'] ??
                              '')
                          .toString();
                  final listenedAtStr = _formatListenedAt(
                    item['listened_at'] ?? item['created_at'],
                  );
                  final durationStr = _formatDuration(
                    item['listen_duration'] ?? item['duration'],
                  );
                  final coverImage =
                      (stallData['cover_image'] ?? item['cover_image'] ?? '')
                          .toString();

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: coverImage.isNotEmpty
                            ? Image.network(
                                coverImage,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.orange.shade100,
                                  child: const Icon(
                                    Icons.audiotrack,
                                    color: Colors.orange,
                                  ),
                                ),
                              )
                            : Container(
                                width: 52,
                                height: 52,
                                color: Colors.orange.shade100,
                                child: const Icon(
                                  Icons.audiotrack,
                                  color: Colors.orange,
                                ),
                              ),
                      ),
                      title: Text(
                        stallName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (contentTitle.isNotEmpty)
                            Text(
                              contentTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              if (listenedAtStr.isNotEmpty) ...[
                                const Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                Text(
                                  listenedAtStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              if (listenedAtStr.isNotEmpty &&
                                  durationStr.isNotEmpty)
                                const Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              if (durationStr.isNotEmpty)
                                Text(
                                  'Thời lượng: $durationStr',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.orange,
                          size: 36,
                        ),
                        onPressed: () => _navigateToPoiDetail(item),
                      ),
                      onTap: () => _navigateToPoiDetail(item),
                    ),
                  );
                },
              ),
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
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                Navigator.of(context).pushReplacementNamed('/home');
              } else if (index == 2) {
                Navigator.of(context).pushReplacementNamed('/profile');
              }
            },
          ),
        ],
      ),
    );
  }
}
