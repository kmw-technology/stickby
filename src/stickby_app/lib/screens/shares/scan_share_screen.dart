import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/p2p_share.dart';
import '../../providers/p2p_provider.dart';
import '../../theme/app_theme.dart';

/// Screen for scanning a QR code to receive a P2P share.
class ScanShareScreen extends StatefulWidget {
  const ScanShareScreen({super.key});

  @override
  State<ScanShareScreen> createState() => _ScanShareScreenState();
}

class _ScanShareScreenState extends State<ScanShareScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<TorchState>(
              valueListenable: _scannerController.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _scannerController.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return _buildErrorState(error.errorDetails?.message ?? 'Camera error');
            },
          ),

          // Overlay with scanning frame
          _buildScannerOverlay(),

          // Instructions at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInstructions(),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.textOnPrimary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing share...',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return CustomPaint(
      painter: _ScannerOverlayPainter(),
      child: Container(),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              color: AppColors.textOnPrimary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              'Point your camera at a StickBy QR code',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'The share will be automatically processed and saved to your device.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnPrimary.withOpacity(0.8),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'End-to-end encrypted',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _scannerController.start(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _processQRCode(rawValue);
        break;
      }
    }
  }

  Future<void> _processQRCode(String data) async {
    // Prevent duplicate processing
    if (_isProcessing || _hasScanned) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });

    // Pause scanner while processing
    await _scannerController.stop();

    try {
      final p2pProvider = context.read<P2PProvider>();

      // Validate it's a StickBy QR code
      try {
        // Try to decode to validate format
        QRShareData.decode(data);
      } catch (e) {
        _showError('Invalid QR code. This is not a StickBy share.');
        return;
      }

      // Receive the share
      final receivedShare = await p2pProvider.receiveShare(data);

      if (receivedShare == null) {
        _showError(p2pProvider.errorMessage ?? 'Failed to process share');
        return;
      }

      // Show success and navigate back
      if (mounted) {
        await _showSuccessDialog(receivedShare);
        Navigator.of(context).pop(receivedShare);
      }
    } catch (e) {
      _showError('Error processing QR code: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        action: SnackBarAction(
          label: 'Retry',
          textColor: AppColors.textOnPrimary,
          onPressed: () {
            setState(() => _hasScanned = false);
            _scannerController.start();
          },
        ),
      ),
    );

    setState(() => _hasScanned = false);
    _scannerController.start();
  }

  Future<void> _showSuccessDialog(ReceivedShare share) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: AppColors.success,
            size: 32,
          ),
        ),
        title: const Text('Share Received!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Successfully received contacts from:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              share.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.contacts, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${share.contacts.length} contacts received',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('View Contacts'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the scanner overlay with a transparent center frame.
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final frameSize = size.width * 0.7;
    final frameLeft = (size.width - frameSize) / 2;
    final frameTop = (size.height - frameSize) / 2 - 50;
    final frameRect = Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize);

    // Draw semi-transparent overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw frame border
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(16)),
      borderPaint,
    );

    // Draw corner accents
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(frameLeft, frameTop + cornerLength),
      Offset(frameLeft, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameTop),
      Offset(frameLeft + cornerLength, frameTop),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(frameLeft + frameSize - cornerLength, frameTop),
      Offset(frameLeft + frameSize, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft + frameSize, frameTop),
      Offset(frameLeft + frameSize, frameTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(frameLeft, frameTop + frameSize - cornerLength),
      Offset(frameLeft, frameTop + frameSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameTop + frameSize),
      Offset(frameLeft + cornerLength, frameTop + frameSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(frameLeft + frameSize - cornerLength, frameTop + frameSize),
      Offset(frameLeft + frameSize, frameTop + frameSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft + frameSize, frameTop + frameSize - cornerLength),
      Offset(frameLeft + frameSize, frameTop + frameSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
