import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/poi.dart';
import 'poi_card_item.dart';

class HomePoiListView extends StatelessWidget {
  final List<Poi> pois;
  final Position? userPosition;
  final ValueChanged<Poi> onPoiTapped;

  const HomePoiListView({
    super.key,
    required this.pois,
    required this.userPosition,
    required this.onPoiTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (pois.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: pois.length,
      itemBuilder: (ctx, idx) {
        final poi = pois[idx];
        return PoiCardItem(
          poi: poi,
          userPosition: userPosition,
          onTap: () => onPoiTapped(poi),
        );
      },
    );
  }
}
