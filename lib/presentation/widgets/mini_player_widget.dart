import 'package:flutter/material.dart';

import '../../core/services/geo_audio_manager.dart';

class MiniPlayerWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayerWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GeoAudioManager.instance,
      builder: (context, _) {
        final manager = GeoAudioManager.instance;
        final poi = manager.currentPoi;

        // Nếu không có bài nào đang chọn/phát thì ẩn Mini Player
        if (poi == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: Card(
            margin: const EdgeInsets.all(8),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Thanh tiến trình mỏng phía trên
                StreamBuilder<Duration>(
                  stream: manager.positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    final dur = manager.currentDuration ?? Duration.zero;
                    final progress = (dur.inMilliseconds > 0)
                        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(
                            0.0,
                            1.0,
                          )
                        : 0.0;
                    return LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.orange,
                      ),
                    );
                  },
                ),
                // 2. Nội dung Mini Player
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: poi.coverImage != null && poi.coverImage!.isNotEmpty
                        ? Image.network(
                            poi.coverImage!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: Colors.orange[100],
                            child: const Icon(
                              Icons.audiotrack,
                              color: Colors.orange,
                            ),
                          ),
                  ),
                  title: Text(
                    manager.currentTitle.isNotEmpty
                        ? manager.currentTitle
                        : poi.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    poi.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút Phát / Tạm dừng
                      IconButton(
                        icon: Icon(
                          manager.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                        ),
                        iconSize: 36,
                        color: Colors.orange,
                        onPressed: () => manager.togglePlay(),
                      ),
                      // Nút Tắt Player
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => manager.leavePoi(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
