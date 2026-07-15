import 'dart:convert'; // Import for JSON encoding.
import 'package:dio/dio.dart' as dio_pack;

class ApiProvider {
  late dio_pack.Dio _dio;

  static const String laravelBaseUrl = "http://10.94.230.10";

  ApiProvider() {
    // Initialize Dio with common timeout settings.
    _dio = dio_pack.Dio(
      dio_pack.BaseOptions(
        headers: {
          "Accept": "application/json",
        },
        // Chat requests might take slightly longer due to AI generation,
        // bumped receiveTimeout to 15 seconds.
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  //Synchronize the detection results and captured image with the Laravel backend.
  Future<Map<String, dynamic>> scanAndSync(String imagePath) async {
    try {
      dio_pack.FormData formData = dio_pack.FormData.fromMap({
        "device_id": "Flutter_Client_01",
        "image": await dio_pack.MultipartFile.fromFile(
          imagePath,
          filename: "scene.jpg",
        ),
      });

      var response = await _dio.post(
        "$laravelBaseUrl/api/vision-scan/sync",
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("Unexpected server status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to process scan: $e");
    }
  }

  //Send a chat message to the Laravel backend for RAG processing.
  Future<Map<String, dynamic>> sendChatMessage(String itemCode, String question) async {
    try {
      // Send standard JSON data instead of FormData for simple text fields
      var response = await _dio.post(
        "$laravelBaseUrl/api/chat",
        data: {
          "item_code": itemCode,
          "question": question,
        },
      );

      return response.data;
    } on dio_pack.DioException catch (e) {
      // Handle Dio specific errors gracefully (e.g., Laravel returns 500 or 422)
      if (e.response != null) {
        final errorMsg = e.response?.data['message'] ?? e.response?.statusMessage;
        throw Exception("Server error: $errorMsg");
      } else {
        throw Exception("Network error: ${e.message}");
      }
    } catch (e) {
      throw Exception("Chat request failed: $e");
    }
  }

  Future<Map<String, dynamic>> addToInventory(String itemName, int quantity,{String? sku}) async {
    try {
      var response = await _dio.post(
        "$laravelBaseUrl/api/inventory/add",
        data: {
          "sku":sku,
          "item_name": itemName,
          "quantity": quantity,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to add inventory: $e");
    }
  }

  Future<Map<String, dynamic>> checkSku(String sku) async {
    try {
      var response = await _dio.post(
        "$laravelBaseUrl/api/inventory/check-sku",
        data: {"sku": sku},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to check SKU: $e");
    }
  }
}