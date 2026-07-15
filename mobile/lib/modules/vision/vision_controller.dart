import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:pos_vision_app/modules/vision/scan_result_action_view.dart';
import 'dart:io';

import '../../data/provider/api_provider.dart';
import 'detection_model.dart';

class VisionController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  XFile? pickedImage;
  RxBool isUploading = false.obs;

  double imageOriginalWidth = 0;
  double imageOriginalHeight = 0;

  String? currentSku;
  String? currentItemName;

  // 1. Update the list to use the strongly typed Model
  RxList<DetectionModel> detections = <DetectionModel>[].obs;

  Future<void> captureAndDetect({String? sku, String? itemName}) async {
    // 1. Save the passed SKU and Item Name to the controller's state
    if (sku != null) currentSku = sku;
    if (itemName != null) currentItemName = itemName;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024, // Optimized for YOLO processing speed
      maxHeight: 1024,
    );

    if (image == null) return;

    pickedImage = image;
    isUploading.value = true;
    update(); // Refresh UI to show the neumorphic loading state

    try {
      // Decode image to get original dimensions for accurate bounding box drawing
      final bytes = await image.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);

      imageOriginalWidth = decodedImage.width.toDouble();
      imageOriginalHeight = decodedImage.height.toDouble();

      // Send to Laravel API Gateway for YOLO processing
      final response = await Get.find<ApiProvider>().scanAndSync(image.path);

      if (response['status'] == 'success') {
        var rawData = response['ai_raw_data'] ?? [];

        if (rawData is List) {
          // Map the raw JSON list to highly-typed DetectionModel objects
          List<DetectionModel> parsedDetections = rawData
              .map((e) => DetectionModel.fromJson(e as Map<String, dynamic>))
              .toList();

          detections.assignAll(parsedDetections);
        }

        // 2. Navigate to the confirmation view AND pass the saved SKU data
        Get.to(
              () => const ScanResultActionView(),
          arguments: {
            'image': pickedImage,
            'detections': detections,
            'imageWidth': imageOriginalWidth,
            'imageHeight': imageOriginalHeight,
            'sku': currentSku,
            'itemName': currentItemName,
          },
          transition: Transition.cupertino, // Smooth iOS-style slide transition
        );

      } else {
        // Upgraded error UI matching the red warning theme
        Get.snackbar(
          'Scan Failed',
          response['message'] ?? 'Unable to process image.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      Get.log('Vision Capture Error: $e');
      Get.snackbar(
        'System Error',
        'Could not reach the AI Engine. Check your connection.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isUploading.value = false;
      update(); // Refresh UI to reset loading state
    }
  }

  void resetState() {
    pickedImage = null;
    detections.clear();
    currentSku = null;
    currentItemName = null;
    isUploading.value = false;
    imageOriginalWidth = 0.0;
    imageOriginalHeight = 0.0;

    update();
  }
}
