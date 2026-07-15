import 'package:get/get.dart';
import 'package:pos_vision_app/modules/ai_chatbot/chat_binding.dart';
import 'package:pos_vision_app/modules/ai_chatbot/chat_view.dart';
import '../modules/dashboard/dashboard_binding.dart';
import '../modules/dashboard/dashboard_view.dart';
import '../modules/vision/vision_binding.dart';
import '../modules/vision/vision_view.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.DASHBOARD;

  static final routes = [
    GetPage(
      name: Routes.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),

    GetPage(
      name: Routes.VISION,
      page: () => const VisionView(),
      binding: VisionBinding(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: Routes.CHAT,
      page: () => const ChatView(),
      binding: ChatBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}