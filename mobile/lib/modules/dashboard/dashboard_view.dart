import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ai_chatbot/chat_view.dart';
import '../vision/vision_view.dart';
import 'dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  final Color baseColor = const Color(0xFFE0E5EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: baseColor,
      // IndexedStack keeps all child pages alive in memory
      body: Obx(() => IndexedStack(
        index: controller.tabIndex.value,
        children: const [
          VisionView(),
          ChatView(),
        ],
      )),
      bottomNavigationBar: _buildNeumorphicBottomNav(),
    );
  }

  Widget _buildNeumorphicBottomNav() {
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: baseColor,
        boxShadow: [
          // Subtle upper shadow to separate the nav bar from the body
          BoxShadow(
            color: Colors.grey.shade400,
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          backgroundColor: baseColor,
          elevation: 0, // Remove default elevation in favor of our custom shadow
          currentIndex: controller.tabIndex.value,
          onTap: controller.changeTabIndex,
          selectedItemColor: Colors.red, // Bright green accent
          unselectedItemColor: Colors.grey.shade500,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.document_scanner_rounded),
              ),
              label: 'Vision Scan',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.smart_toy_rounded),
              ),
              label: 'AI Chat',
            ),
          ],
        ),
      ),
    ));
  }
}