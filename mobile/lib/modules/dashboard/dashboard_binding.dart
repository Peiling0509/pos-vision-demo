import 'package:get/get.dart';
import '../ai_chatbot/chat_controller.dart';
import '../vision/vision_controller.dart';
import 'dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());

    Get.lazyPut<VisionController>(() => VisionController());
    Get.lazyPut<ChatController>(() => ChatController());
  }
}