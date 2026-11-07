import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/geo_audio_manager.dart';
import '../../core/utils/cooldown.dart';
import '../../data/models/poi.dart';
import '../../data/remote/poi_api.dart';
import 'poi_detail_page.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  final Cooldown _cooldown = Cooldown(duration: const Duration(seconds: 2));
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Phân giải mã QR (URL, JSON, hoặc ID thuần) để lấy ra POI/Stall ID
  String? _parsePoiId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. Thử parse URI (VD: https://domain.com/mobile/pois/123 hoặc https://domain.com/?poi=123)
    try {
      final uri = Uri.parse(trimmed);
      if (uri.hasScheme || trimmed.contains('/')) {
        final segments = uri.pathSegments;
        for (int i = 0; i < segments.length; i++) {
          final seg = segments[i].toLowerCase();
          if ((seg == 'pois' || seg == 'stalls' || seg == 'poi' || seg == 'stall') &&
              i + 1 < segments.length) {
            final id = segments[i + 1];
            if (id.isNotEmpty) return id;
          }
        }

        // Kiểm tra query parameter
        final queryId = uri.queryParameters['poi'] ??
            uri.queryParameters['poi_id'] ??
            uri.queryParameters['stall'] ??
            uri.queryParameters['stall_id'] ??
            uri.queryParameters['id'];
        if (queryId != null && queryId.isNotEmpty) {
          return queryId;
        }
      }
    } catch (_) {}

    // 2. Thử parse JSON (VD: {"poi_id": "123"} hoặc {"id": "123"})
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          final id = decoded['poi_id'] ??
              decoded['stall_id'] ??
              decoded['poiId'] ??
              decoded['id'];
          if (id != null && id.toString().isNotEmpty) {
            return id.toString();
          }
        }
      } catch (_) {}
    }

    // 3. Fallback: ID chuỗi ký tự đơn giản (không chứa dấu cách, không phải URL lạ)
    if (!trimmed.contains(' ') && !trimmed.contains('\n') && trimmed.length <= 64) {
      return trimmed;
    }

    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || !_cooldown.isReady) return;

    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue ?? barcode?.displayValue;
    if (raw == null || raw.trim().isEmpty) return;

    _cooldown.trigger();

    final poiId = _parsePoiId(raw);
    if (poiId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã QR không hợp lệ hoặc không thuộc hệ thống.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);
    await _controller.stop();

    try {
      final token = AuthService.instance.accessToken ?? '';
      final data = await PoiApi.instance.getPoi(poiId, token);

      if (data == null) {
        throw Exception('Không tìm thấy thông tin địa điểm này trên hệ thống.');
      }

      final poi = Poi.fromJson(data);

      // Tạm dừng bài thuyết minh đang phát (nếu có) trước khi mở quán mới
      if (GeoAudioManager.instance.isPlaying) {
        await GeoAudioManager.instance.leavePoi();
      }

      if (!mounted) return;

      // Chuyển hướng sang trang chi tiết quán
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PoiDetailPage(poi: poi),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Thông báo'),
            ],
          ),
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Thoát'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() => _isProcessing = false);
                await _controller.start();
              },
              child: const Text('Quét lại'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanBoxSize = screenSize.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Quét mã QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            tooltip: 'Bật/tắt đèn Flash',
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera View Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 2. Viewfinder Overlay (Khung ngắm quét)
          Center(
            child: Container(
              width: scanBoxSize,
              height: scanBoxSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // 3. Hướng dẫn quét
          Positioned(
            bottom: 80,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Hướng camera vào mã QR đặt tại quán ăn để xem chi tiết',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 4. Loading Overlay khi đang fetch dữ liệu
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'Đang tìm thông tin địa điểm...',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

