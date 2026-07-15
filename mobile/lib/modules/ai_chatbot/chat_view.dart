import 'dart:math' as math; // Remember to import math for the wave animation
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_controller.dart';
// import 'chat_controller.dart'; // Make sure to import your ChatController

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  final Color baseColor = const Color(0xFFE0E5EC);

  @override
  Widget build(BuildContext context) {
    Get.put(ChatController());

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        backgroundColor: baseColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'AI Assistant',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: Obx(() {
              int itemCount =
                  controller.messages.length +
                  (controller.isTyping.value ? 1 : 0);

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index < controller.messages.length) {
                    final msg = controller.messages[index];
                    return _buildNeumorphicBubble(msg);
                  } else {
                    return _buildTypingBubble();
                  }
                },
              );
            }),
          ),

          // Bottom input area
          _buildNeumorphicInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              offset: const Offset(5, 5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const TypingAnimation(),
      ),
    );
  }

  // --- Neumorphic chat bubble ---
  Widget _buildNeumorphicBubble(ChatMessage msg) {
    bool isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

        constraints: BoxConstraints(maxWidth: Get.width * 0.75),

        decoration: BoxDecoration(
          color: isUser ? Colors.red : baseColor,

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              offset: const Offset(5, 5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),

        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.grey.shade800,
            fontSize: 15,
            height: 1.4,
            fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // --- Neumorphic bottom input area ---
  Widget _buildNeumorphicInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(30),

                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
              ),

              child: TextField(
                controller: controller.textController,
                style: TextStyle(color: Colors.grey.shade800),

                decoration: InputDecoration(
                  hintText: 'Enter your question...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 15),

          GestureDetector(
            onTap: controller.sendMessage,

            child: Container(
              width: 50,
              height: 50,

              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,

                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                ],
              ),

              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Smooth three-dot wave animation
// =========================================================================

class TypingAnimation extends StatefulWidget {
  const TypingAnimation({super.key});

  @override
  State<TypingAnimation> createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<TypingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Animation repeats every 1.2 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,

          builder: (context, child) {
            // Calculate bouncing height using a sine wave.
            // Delay offsets create the wave effect.
            double offset = math.sin(
              (_controller.value * 2 * math.pi) - (index * math.pi / 2),
            );

            // Only move upward when the sine value is positive.
            double translateY = offset > 0 ? offset * -6.0 : 0.0;

            return Transform.translate(
              offset: Offset(0, translateY),

              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),

                child: CircleAvatar(
                  radius: 4,

                  // The color becomes darker at the highest point
                  // and lighter when returning to its resting position.
                  backgroundColor: Color.lerp(
                    Colors.grey.shade300,
                    Colors.grey.shade700,
                    offset > 0 ? offset : 0,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
