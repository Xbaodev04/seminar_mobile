import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:seminar_mobile/data/remote/poi_access.dart';
import 'package:seminar_mobile/presentation/pages/qr_scan_page.dart';

class FakeScannerController extends MobileScannerController {
  FakeScannerController() : super(autoStart: false);
  int stops = 0;
  int starts = 0;

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> start({
    CameraFacing? cameraDirection,
    CameraLensType? cameraLensType,
  }) async {
    starts++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const scannerChannel = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(scannerChannel, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(scannerChannel, null);
  });

  for (final payloadGuard in [false, true]) {
    testWidgets(
      'hidden QR shows closed dialog and supports retry (payload=$payloadGuard)',
      (tester) async {
        final controller = FakeScannerController();
        late void Function(BarcodeCapture) scan;
        var requests = 0;
        String? requestedId;
        await tester.pumpWidget(
          MaterialApp(
            home: QrScanPage(
              controller: controller,
              scannerBuilder: (onDetect) {
                scan = onDetect;
                return const SizedBox();
              },
              lookupPoi: (id) async {
                requests++;
                requestedId = id;
                if (payloadGuard) return {'id': id, 'is_active': false};
                throw const PoiNotPublicException();
              },
            ),
          ),
        );
        const capture = BarcodeCapture(
          barcodes: [Barcode(rawValue: 'https://example.com/pois/poi-hidden')],
        );
        scan(capture);
        scan(capture); // Repeated camera frames must not open multiple dialogs.
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.text('Quán đã đóng cửa'),
          findsOneWidget,
          reason:
              (tester.widget<AlertDialog>(find.byType(AlertDialog)).content
                      as Text)
                  .data,
        );
        expect(find.text('Quét lại'), findsOneWidget);
        expect(find.text('Thoát'), findsOneWidget);
        expect(requests, 1);
        expect(requestedId, 'poi-hidden');
        expect(controller.stops, 1);
        await tester.tap(find.text('Quét lại'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(controller.starts, 1);
        expect(find.byType(QrScanPage), findsOneWidget);
      },
    );
  }

  testWidgets('missing QR displays not found rather than closed', (
    tester,
  ) async {
    late void Function(BarcodeCapture) scan;
    await tester.pumpWidget(
      MaterialApp(
        home: QrScanPage(
          controller: FakeScannerController(),
          scannerBuilder: (onDetect) {
            scan = onDetect;
            return const SizedBox();
          },
          lookupPoi: (_) async => null,
        ),
      ),
    );
    scan(
      const BarcodeCapture(
        barcodes: [Barcode(rawValue: '{"poi_id":"missing"}')],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Không tìm thấy thông tin địa điểm này trên hệ thống.'),
      findsOneWidget,
    );
    expect(find.text('Quán đã đóng cửa'), findsNothing);
  });
}
