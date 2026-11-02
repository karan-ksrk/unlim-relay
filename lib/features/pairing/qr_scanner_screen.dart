import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/pairing_invite.dart';
import '../../app/app_info.dart';

/// Scans the receiver's pairing QR code and pops with a [PairingInvite].
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;
  String? _lastRejected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final invite = PairingInvite.tryParse(raw);
      if (invite != null) {
        _done = true;
        context.pop(invite);
        return;
      }
      if (raw != _lastRejected) {
        _lastRejected = raw;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That is not a $appName pairing code.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan pairing code')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(24),
              child: const SafeArea(
                top: false,
                child: Text(
                  'Point the camera at the QR code on the receiver phone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
