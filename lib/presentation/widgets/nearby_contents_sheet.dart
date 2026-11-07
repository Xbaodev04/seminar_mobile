import 'package:flutter/material.dart';

import '../../core/services/geo_audio_manager.dart';

class NearbyContentsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> contents;

  const NearbyContentsSheet({super.key, required this.contents});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'Các địa điểm lân cận',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.separated(
              itemCount: contents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final content = contents[index];
                final stallName =
                    (content['stall_name'] ?? content['poi_name'] ?? 'Địa điểm')
                        .toString();
                final title =
                    (content['translated_title'] ??
                            content['title'] ??
                            stallName)
                        .toString();
                final coverImage = (content['cover_image'] ?? '').toString();

                return ListenableBuilder(
                  listenable: GeoAudioManager.instance,
                  builder: (context, _) {
                    final manager = GeoAudioManager.instance;
                    final isPlayingThis =
                        manager.currentContentIndex == index &&
                        manager.currentContents.length == contents.length;

                    return Card(
                      elevation: isPlayingThis ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isPlayingThis
                              ? Colors.orange
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                                      Icons.restaurant,
                                      color: Colors.orange,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.orange.shade100,
                                  child: const Icon(
                                    Icons.restaurant,
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
                        subtitle: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                          ),
                        ),
                        trailing: isPlayingThis
                            ? const Icon(Icons.volume_up, color: Colors.orange)
                            : IconButton(
                                icon: const Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  // Play specific content from playlist
                                  GeoAudioManager.instance.playContent(index);
                                },
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
