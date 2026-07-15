import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/provider/api_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  // Message list using .obs for reactive state management
  var messages = <ChatMessage>[].obs;

  // Indicates whether the AI is currently generating a response
  var isTyping = false.obs;

  // Text input controller
  final TextEditingController textController = TextEditingController();

  // Simulated current product SKU received from the scanning page
  String currentItemCode = "dutch_lady_low_fat";

  // Initialize with a greeting message from the AI assistant
  @override
  void onInit() {
    super.onInit();
    messages.add(
      ChatMessage(
        text:
            "Hello! I'm your AI shopping assistant. What would you like to know about this product?",
        isUser: false,
      ),
    );
  }

  Future<void> sendMessage() async {
    String text = textController.text.trim();
    if (text.isEmpty) return;

    // 1. Add the user's question to the message list and clear the input field
    messages.add(ChatMessage(text: text, isUser: true));
    textController.clear();
    isTyping.value = true;

    try {
      var response = await _apiProvider.sendChatMessage(currentItemCode, text);
      if (response['status'] == 'success') {
        messages.add(ChatMessage(text: response['answer'], isUser: false));
      } else {
        messages.add(
          ChatMessage(
            text: "System Message: ${response['message']}",
            isUser: false,
          ),
        );
      }
    } catch (e) {
      messages.add(
        ChatMessage(
          text: "Sorry, your request could not be completed. $e",
          isUser: false,
        ),
      );
    } finally {
      isTyping.value = false;
    }
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
