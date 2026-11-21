import 'package:flutter/material.dart';

import '../../data/models/poi.dart';
import '../../data/remote/poi_access.dart';
import '../../data/remote/poi_api.dart';
import 'poi_detail_page.dart';

/// Public entry point for QR scans from the phone camera, without login or GPS.
class PoiLinkPage extends StatefulWidget {
  const PoiLinkPage({
    super.key,
    required this.poiId,
    this.lookupPoi,
    this.detailBuilder,
  });

  final String? poiId;
  final Future<Map<String, dynamic>?> Function(String)? lookupPoi;
  final Widget Function(Poi)? detailBuilder;

  @override
  State<PoiLinkPage> createState() => _PoiLinkPageState();
}

class _PoiLinkPageState extends State<PoiLinkPage> {
  late Future<Poi?> _poi;

  @override
  void initState() {
    super.initState();
    _poi = _load();
  }

  Future<Poi?> _load() async {
    final id = widget.poiId;
    if (id == null) return null;
    final data =
        await (widget.lookupPoi?.call(id) ?? PoiApi.instance.getPoi(id, ''));
    if (data == null) return null;
    requirePublicPoi(data);
    return Poi.fromJson(data);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Poi?>(
    future: _poi,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        final poi = snapshot.data!;
        return widget.detailBuilder?.call(poi) ??
            PoiDetailPage(poi: poi, fromPublicLink: true);
      }
      final loading = snapshot.connectionState != ConnectionState.done;
      final message = widget.poiId == null
          ? 'Liên kết quán không hợp lệ'
          : snapshot.error is PoiNotPublicException
          ? PoiNotPublicException.message
          : snapshot.hasError
          ? 'Không tải được thông tin quán. Vui lòng thử lại.'
          : 'Không tìm thấy quán';
      return Scaffold(
        appBar: AppBar(title: const Text('Ẩm thực Quận 4')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text('Đang tải thông tin quán…'),
                ] else ...[
                  const Icon(Icons.info_outline, size: 40),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  if (widget.poiId != null) ...[
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        final request = _load();
                        setState(() {
                          _poi = request;
                        });
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
