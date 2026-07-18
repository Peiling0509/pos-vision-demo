import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/provider/api_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath; // Ensure imagePath is retained here

  ChatMessage({required this.text, required this.isUser, this.imagePath});
}

class ChatController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  var messages = <ChatMessage>[].obs;
  var isTyping = false.obs;

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String currentItemCode = "dutch_lady_low_fat";

  Rx<File?> selectedImage = Rx<File?>(null);

  final ImagePicker _picker = ImagePicker();

  final Color baseColor = const Color(
    0xFFE0E5EC,
  ); // Keep the neumorphic background color consistent

  @override
  void onInit() {
    super.onInit();
    messages.add(
      ChatMessage(
        text:
            "Hello! I'm your AI shopping assistant. Feel free to ask questions or upload a photo of a product!",
        isUser: false,
      ),
    );
  }

  void _scrollToChatBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==========================================
  // Display a bottom sheet with Camera and Gallery options
  // ==========================================
  void showImageSourceOptions() {
    // Hide the keyboard to prevent it from covering the bottom sheet
    FocusManager.instance.primaryFocus?.unfocus();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.white.withOpacity(0.8),
          //     offset: const Offset(-5, -5),
          //     blurRadius: 5,
          //   ),
          // ],
        ),
        child: Wrap(
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
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      offset: const Offset(3, 3),
                      blurRadius: 5,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-3, -3),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.grey.shade700,
                ),
              ),
              title: Text(
                'Take a Photo',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      offset: const Offset(3, 3),
                      blurRadius: 5,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-3, -3),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: Colors.grey.shade700,
                ),
              ),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20), // Bottom spacing
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Receive the selected image source (Camera or Gallery)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load image: $e',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  void clearImage() {
    selectedImage.value = null;
  }

  // Future<void> sendMessage() async {
  //   String text = textController.text.trim();
  //   if (text.isEmpty && selectedImage.value == null) return;
  //
  //   //Automatically dismiss the keyboard after sending a message
  //   FocusManager.instance.primaryFocus?.unfocus();
  //
  //   String displayMessage = text.isEmpty ? "" : text;
  //
  //   // Store the image path together with the message for UI rendering
  //   messages.add(
  //     ChatMessage(
  //       text: displayMessage,
  //       isUser: true,
  //       imagePath: selectedImage.value?.path,
  //     ),
  //   );
  //
  //   textController.clear();
  //   isTyping.value = true;
  //
  //   //after send message, scroll to bottom to see the latest message
  //   _scrollToChatBottom();
  //
  //   String? currentImagePath = selectedImage.value?.path;
  //   clearImage();
  //
  //   try {
  //     var response = await _apiProvider.sendChatMessage(
  //       question: text.isEmpty
  //           ? "Please scan this image and tell me what product it is."
  //           : text,
  //       imagePath: currentImagePath,
  //       sessionId: "flutter_client_001",
  //     );
  //
  //     if (response['status'] == 'success') {
  //       messages.add(
  //         ChatMessage(
  //           text: response['answer'],
  //           isUser: false,
  //         ),
  //       );
  //     } else {
  //       messages.add(
  //         ChatMessage(
  //           text: "System Message: ${response['message']}",
  //           isUser: false,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     messages.add(
  //       ChatMessage(
  //         text: "Sorry, your request could not be completed. $e",
  //         isUser: false,
  //       ),
  //     );
  //   } finally {
  //     isTyping.value = false;
  //     _scrollToChatBottom();
  //   }
  // }

  Future<void> sendMessage() async {
    String text = textController.text.trim();
    if (text.isEmpty && selectedImage.value == null) return;

    FocusManager.instance.primaryFocus?.unfocus();

    String displayMessage = text.isEmpty ? "" : text;
    messages.add(ChatMessage(text: displayMessage, isUser: true, imagePath: selectedImage.value?.path));

    textController.clear();

    isTyping.value = true;
    _scrollToChatBottom();

    String? currentImagePath = selectedImage.value?.path;
    clearImage();

    bool isFirstChunk = true;
    int aiMessageIndex = -1;

    try {
      await _apiProvider.sendChatMessageStream(
          question: text.isEmpty ? "Please scan this image and tell me what product it is." : text,
          imagePath: currentImagePath,
          sessionId: "flutter_client_001",
          onEvent: (String chunk, bool isDone) {
            if (isDone) {
              isTyping.value = false;
            } else {
              if (isFirstChunk) {
                isTyping.value = false;
                messages.add(ChatMessage(text: chunk, isUser: false));
                aiMessageIndex = messages.length - 1;
                isFirstChunk = false;
              } else {
                String currentText = messages[aiMessageIndex].text;
                messages[aiMessageIndex] = ChatMessage(
                    text: currentText + chunk,
                    isUser: false
                );

                messages.refresh();
              }

              _scrollToChatBottom();
            }
          },
          onError: (String errorMsg) {
            isTyping.value = false;
            if (aiMessageIndex == -1) {
              messages.add(ChatMessage(text: "System Message: $errorMsg", isUser: false));
            } else {
              messages[aiMessageIndex] = ChatMessage(text: "System Message: $errorMsg", isUser: false);
              messages.refresh();
            }
          }
      );
    } catch (e) {
      isTyping.value = false;
      messages.add(ChatMessage(text: "Sorry, your request could not be completed. $e", isUser: false));
    }
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
