import 'dart:convert';
import 'package:dio/dio.dart' as dio_pack;

class ApiProvider {
  late dio_pack.Dio _dio;

  static const String laravelBaseUrl = "http://10.99.139.10";

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

  Future<Map<String, dynamic>> sendChatMessage({required String question, String? imagePath, String? sessionId}) async {
    try {
      dio_pack.FormData formData = dio_pack.FormData.fromMap({
        "question": question,
        "session_id": sessionId ?? "flutter_default_session",
      });

      if (imagePath != null && imagePath.isNotEmpty) {
        formData.files.add(MapEntry(
          "image",
          await dio_pack.MultipartFile.fromFile(imagePath, filename: "chat_upload.jpg"),
        ));
      }

      var response = await _dio.post(
        "$laravelBaseUrl/api/chat",
        data: formData,
      );

      return response.data;
    } on dio_pack.DioException catch (e) {
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

  Future<void> sendChatMessageStream({
    required String question,
    String? imagePath,
    required String sessionId,
    required Function(String chunk, bool isDone) onEvent,
    required Function(String error) onError,
  }) async {
    try {
      dio_pack.FormData formData = dio_pack.FormData.fromMap({
        "question": question,
        "session_id": sessionId,
      });

      if (imagePath != null && imagePath.isNotEmpty) {
        formData.files.add(MapEntry(
          "image",
          await dio_pack.MultipartFile.fromFile(imagePath, filename: "chat_stream.jpg"),
        ));
      }

      var response = await _dio.post(
        "$laravelBaseUrl/api/chat/stream",
        data: formData,
        options: dio_pack.Options(
          responseType: dio_pack.ResponseType.stream,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      String leftover = "";

      response.data.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .listen((String data) {

        leftover += data;

        // SSE protocol standard: A complete event must end with two newline characters.
        final parts = leftover.split('\n\n');

        // 🌟 The core logic: If the last element is not empty, it means the JSON has not been completely received.
        // We take it out of the array, leave it in the leftover array, and reassemble it when the next network packet arrives.
        leftover = parts.removeLast();

        for (var event in parts) {
          event = event.trim();
          if (event.startsWith('data: ')) {
            final jsonStr = event.substring(6).trim();
            if (jsonStr.isEmpty) continue;

            try {
              final jsonData = jsonDecode(jsonStr);
              final type = jsonData['type'];

              if (type == 'token') {
                onEvent(jsonData['content'] ?? '', false);
              } else if (type == 'done') {
                onEvent('', true);
              } else if (type == 'error') {
                onError(jsonData['message'] ?? 'Unknown error');
              }
            } catch (e) {
              continue;
            }
          }
        }
      }, onDone: () {
      }, onError: (e) {
        onError("Stream interrupted: $e");
      });

    } catch (e) {
      onError("Request failed: $e");
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