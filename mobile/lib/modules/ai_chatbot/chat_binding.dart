import 'package:get/get.dart';
import 'package:pos_vision_app/modules/ai_chatbot/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
  }
}