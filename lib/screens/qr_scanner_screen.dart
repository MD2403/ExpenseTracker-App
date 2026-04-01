import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, required this.onScanned});

  final void Function(String upiId, String? name) onScanned;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _scanned = false;
  bool _torchOn = false;

  // Parse UPI QR code
  // UPI QR format: upi://pay?pa=upiid@bank&pn=Name&...
  Map<String, String> _parseUpiQr(String qrData) {
    final result = <String, String>{};
    try {
      final uri = Uri.parse(qrData);
      result['pa'] = uri.queryParameters['pa'] ?? '';
      result['pn'] = uri.queryParameters['pn'] ?? '';
      result['am'] = uri.queryParameters['am'] ?? '';
    } catch (e) {
      // If not a valid URI, check if it's just a UPI ID
      if (qrData.contains('@')) {
        result['pa'] = qrData;
      }
    }
    return result;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;

      // Check if it's a UPI QR code
      if (rawValue.startsWith('upi://') ||
          rawValue.contains('@')) {
        setState(() => _scanned = true);
        controller.stop();

        final parsed = _parseUpiQr(rawValue);
        final upiId  = parsed['pa'] ?? '';
        final name   = parsed['pn'];

        if (upiId.isNotEmpty) {
          widget.onScanned(upiId, name?.isNotEmpty == true ? name : null);
          Navigator.pop(context);
        } else {
          // Not a valid UPI QR
          setState(() => _scanned = false);
          controller.start();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Not a valid UPI QR code. Try again.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan UPI QR Code',
            style: TextStyle(color: Colors.white)),
        actions: [
          // Torch toggle
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          // Flip camera
          IconButton(
            icon: const Icon(Icons.flip_camera_ios,
                color: Colors.white),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Overlay with scanning frame
          CustomPaint(
            size: Size.infinite,
            painter: _ScannerOverlayPainter(),
          ),

          // Bottom instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner,
                      color: Colors.white70, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'Point camera at UPI QR code',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supports Google Pay, PhonePe, Paytm QR codes',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12),
                    textAlign: TextAlign.center,
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

// Custom painter for scanner overlay
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Scanning box dimensions
    const boxSize   = 260.0;
    final boxLeft   = (size.width - boxSize) / 2;
    final boxTop    = (size.height - boxSize) / 2 - 40;
    final boxRight  = boxLeft + boxSize;
    final boxBottom = boxTop + boxSize;

    // Draw dark overlay with transparent center
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(boxLeft, boxTop, boxRight, boxBottom),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, paint);

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLen = 30.0;
    const r         = 12.0;

    // Top-left corner
    canvas.drawPath(
        Path()
          ..moveTo(boxLeft, boxTop + cornerLen)
          ..lineTo(boxLeft, boxTop + r)
          ..quadraticBezierTo(boxLeft, boxTop, boxLeft + r, boxTop)
          ..lineTo(boxLeft + cornerLen, boxTop),
        cornerPaint);

    // Top-right corner
    canvas.drawPath(
        Path()
          ..moveTo(boxRight - cornerLen, boxTop)
          ..lineTo(boxRight - r, boxTop)
          ..quadraticBezierTo(
              boxRight, boxTop, boxRight, boxTop + r)
          ..lineTo(boxRight, boxTop + cornerLen),
        cornerPaint);

    // Bottom-left corner
    canvas.drawPath(
        Path()
          ..moveTo(boxLeft, boxBottom - cornerLen)
          ..lineTo(boxLeft, boxBottom - r)
          ..quadraticBezierTo(
              boxLeft, boxBottom, boxLeft + r, boxBottom)
          ..lineTo(boxLeft + cornerLen, boxBottom),
        cornerPaint);

    // Bottom-right corner
    canvas.drawPath(
        Path()
          ..moveTo(boxRight - cornerLen, boxBottom)
          ..lineTo(boxRight - r, boxBottom)
          ..quadraticBezierTo(
              boxRight, boxBottom, boxRight, boxBottom - r)
          ..lineTo(boxRight, boxBottom - cornerLen),
        cornerPaint);

    // Scanning line animation hint
    final linePaint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(boxLeft + 10, (boxTop + boxBottom) / 2),
      Offset(boxRight - 10, (boxTop + boxBottom) / 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}