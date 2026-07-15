import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_vision_app/modules/vision/vision_controller.dart';

import '../../data/provider/api_provider.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final Color baseColor = const Color(0xFFE0E5EC);

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: Text(
          'Scan SKU',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: baseColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Scanner view
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetection,
          ),

          // Simple scanning frame UI decoration (optional)
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00E676),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Core: Process barcode result and display bottom sheet ---
  void _handleBarcodeDetection(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String scannedCode = barcode.rawValue!;

        _scannerController.stop();

        Get.dialog(
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
              ),
            ),
          ),
          barrierDismissible: false,
        );

        try {
          final response = await Get.find<ApiProvider>().checkSku(scannedCode);
          Get.back();

          String itemName;
          if (response['exists'] == true) {
            itemName = response['data']['name'];
          } else {
            itemName = 'New Product (Unregistered)';
          }

          _showActionBottomSheet(scannedCode, itemName);

        } catch (e) {
          Get.back();
          Get.snackbar(
            'Error',
            'Failed to fetch product details.',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          _scannerController.start();
        }
        break;
      }
    }
  }

  void _showActionBottomSheet(String sku, String itemName) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              offset: const Offset(0, -4),
              blurRadius: 15,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Text(
              itemName,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'SKU: $sku',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildNeumorphicButton(
                    onPressed: () {
                      Get.back();
                      _showManualEntryDialog(sku, itemName);
                    },
                    icon: Icons.keyboard_alt_rounded,
                    label: 'Manual\nEntry',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildNeumorphicButton(
                    onPressed: () {
                      Get.back();
                      Get.back();

                      Future.delayed(const Duration(milliseconds: 300), () {
                        Get.find<VisionController>().captureAndDetect(
                          sku: sku,
                          itemName: itemName,
                        );
                      });
                    },
                    icon: Icons.camera_enhance_rounded,
                    label: 'AI Vision\nCount',
                    isHighlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    ).then((_) {
      _scannerController.start();
    });
  }

  // --- Manual quantity input dialog ---
  void _showManualEntryDialog(String sku, String itemName) {
    final TextEditingController qtyController = TextEditingController();

    Get.defaultDialog(
      title: 'Enter Quantity',
      titleStyle: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold),
      backgroundColor: baseColor,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // 提醒用户正在给哪个商品填数量
            Text(
              itemName,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  const BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                  BoxShadow(color: Colors.grey.shade400, offset: const Offset(3, 3), blurRadius: 6),
                ],
              ),
              child: TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                ),
              ),
            ),
          ],
        ),
      ),
      confirm: TextButton(
        onPressed: () {
          // TODO: 调用 ApiProvider
          Get.back();
          Get.snackbar(
            'Success',
            'Added to inventory.',
            backgroundColor: const Color(0xFF00E676),
            colorText: Colors.white,
          );
        },
        child: const Text('Confirm', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  // Neumorphic button component
  Widget _buildNeumorphicButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isHighlight = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
          border: isHighlight
              ? Border.all(
            color: const Color(0xFF00E676).withOpacity(0.3),
            width: 1.5,
          )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              offset: const Offset(5, 5),
              blurRadius: 10,
            ),

            const BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 10,
            ),
          ],
        ),

        child: Column(
          children: [
            Icon(
              icon,
              color: isHighlight
                  ? const Color(0xFF00E676)
                  : Colors.grey.shade700,
              size: 32,
            ),

            const SizedBox(height: 12),

            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}