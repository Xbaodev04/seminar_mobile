import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/location_service.dart';
import '../../data/models/poi.dart';

class PoiCardItem extends StatelessWidget {
  final Poi poi;
  final Position? userPosition;
  final VoidCallback? onTap;
  final VoidCallback? onTapListen;

  const PoiCardItem({
    super.key,
    required this.poi,
    this.userPosition,
    this.onTap,
    this.onTapListen,
  });

  @override
  Widget build(BuildContext context) {
    String? distanceText;
    if (userPosition != null) {
      double distanceInMeters = LocationService.instance
          .calculateDistanceInMeters(
            userPosition!.latitude,
            userPosition!.longitude,
            poi.latitude,
            poi.longitude,
          );
      distanceText = LocationService.instance.formatDistance(distanceInMeters);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: poi.coverImage != null && poi.coverImage!.isNotEmpty
                    ? Image.network(
                        poi.coverImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    if (poi.category != null && poi.category!.isNotEmpty) ...[
                      Text(
                        poi.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    Row(
                      children: [
                        if (poi.averageRating != null) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            poi.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (distanceText != null) ...[
                          const Icon(
                            Icons.directions_walk,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            distanceText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action button
              IconButton(
                icon: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.orange,
                  size: 32,
                ),
                tooltip: 'Nghe thuyết minh',
                onPressed:
                    onTapListen ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đang phát thuyết minh: ${poi.name}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.restaurant, color: Colors.grey, size: 32),
    );
  }
}
