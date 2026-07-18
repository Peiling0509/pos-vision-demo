import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_vision_app/modules/vision/vision_controller.dart';
import 'package:pos_vision_app/modules/vision/barcode_scanner_view.dart';

class VisionView extends GetView<VisionController> {
  const VisionView({super.key});

  final Color baseColor = const Color(0xFFE0E5EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: baseColor,

      appBar: AppBar(
        backgroundColor: baseColor,
        elevation: 0,
        centerTitle: true,

        title: Text(
          'Smart POS Vision',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),

      body: GetBuilder<VisionController>(
        builder: (_) {
          // --- Integration point:
          // If no image has been captured yet, display the operation menu
          if (controller.pickedImage == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  // 1. Recommended operation: Scan barcode for product identification
                  _buildNeumorphicButton(
                    onPressed: () => Get.to(() => const BarcodeScannerView()),

                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan SKU Barcode',
                  ),

                  // const SizedBox(height: 32),
                  //
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Container(
                  //       width: 40,
                  //       height: 2,
                  //       color: Colors.grey.shade300,
                  //     ),
                  //
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 12),
                  //       child: Text(
                  //         'OR',
                  //         style: TextStyle(
                  //           color: Colors.grey.shade500,
                  //           fontWeight: FontWeight.w800,
                  //           letterSpacing: 2,
                  //         ),
                  //       ),
                  //     ),
                  //     Container(
                  //       width: 40,
                  //       height: 2,
                  //       color: Colors.grey.shade300,
                  //     ),
                  //   ],
                  // ),
                  //
                  // const SizedBox(height: 32),

                  // 2. Alternative operation:
                  // Direct AI vision-based inventory counting
                  // _buildNeumorphicButton(
                  //   onPressed: controller.captureAndDetect,
                  //   icon: Icons.camera_enhance_rounded,
                  //   label: 'Direct AI Count',
                  // ),
                ],
              ),
            );
          }

          // If an image exists, display image preview and AI detection results
          return _buildVisionPreview();
        },
      ),

      // Floating button:
      // Allow user to retake image after completing a scan
      floatingActionButton: GetBuilder<VisionController>(
        builder: (_) {
          return controller.pickedImage != null
              ? _buildNeumorphicFab(
                  onPressed: controller.captureAndDetect,
                  icon: Icons.camera_alt_rounded,
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  // --- Neumorphic rectangular button ---
  Widget _buildNeumorphicButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 260, // Fixed width to align both buttons
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            // Dark shadow on bottom-right
            // Simulates light source from top-left
            BoxShadow(
              color: Colors.grey.shade400,
              offset: const Offset(6, 6),
              blurRadius: 12,
              spreadRadius: 1,
            ),

            // Highlight on top-left
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-6, -6),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Neumorphic circular floating action button ---
  Widget _buildNeumorphicFab({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              offset: const Offset(4, 4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),

        child: Icon(icon, color: Colors.grey.shade700, size: 28),
      ),
    );
  }

  // --- Render image preview with AI detection bounding boxes ---
  Widget _buildVisionPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double viewW = constraints.maxWidth - 40;
        double viewH = constraints.maxHeight - 40;

        double imgW = controller.imageOriginalWidth;
        double imgH = controller.imageOriginalHeight;

        // Adjust image orientation
        if (viewW < viewH && imgW > imgH) {
          double temp = imgW;
          imgW = imgH;
          imgH = temp;
        }

        // Calculate image scaling ratio
        double scale = (viewW / imgW < viewH / imgH)
            ? (viewW / imgW)
            : (viewH / imgH);

        double renderedW = imgW * scale;
        double renderedH = imgH * scale;

        // Calculate image offset position
        double offsetX = (viewW - renderedW) / 2;
        double offsetY = (viewH - renderedH) / 2;

        return Center(
          child: Container(
            width: viewW,
            height: viewH,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  offset: const Offset(8, 8),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-8, -8),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Original captured image
                  Container(
                    width: viewW,
                    height: viewH,
                    color: Colors.black87,
                    child: Image.file(
                      File(controller.pickedImage!.path),
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Draw AI detection bounding boxes
                  ...controller.detections.map((item) {
                    List<double> box = item.box;
                    String label = item.label;
                    double conf = item.confidence;
                    double left = (box[0] * scale) + offsetX;
                    double top = (box[1] * scale) + offsetY;
                    double width = (box[2] - box[0]) * scale;
                    double height = (box[3] - box[1]) * scale;

                    return Positioned(
                      left: left,
                      top: top,
                      width: width,
                      height: height,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF00E676),
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),

                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),

                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(5),
                                bottomRight: Radius.circular(8),
                              ),
                            ),

                            child: Text(
                              "$label ${(conf * 100).toInt()}%",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Show loading indicator while uploading image
                  if (controller.isUploading.value)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF00E676),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
