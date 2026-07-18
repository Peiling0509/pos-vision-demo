import 'dart:io';
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
                controller: controller.scrollController,
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
        padding: const EdgeInsets.all(14),
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
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg.imagePath != null)
              Container(
                margin: EdgeInsets.only(bottom: msg.text.isNotEmpty ? 10 : 0),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(File(msg.imagePath!), fit: BoxFit.cover),
              ),

            if (msg.text.isNotEmpty)
              isUser
                  ? Text(
                      msg.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : StreamFadeText(
                      text: msg.text,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeumorphicInputArea() {
    return Container(
      // decoration: BoxDecoration(
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.grey.shade400,
      //       offset: const Offset(5, 5),
      //       blurRadius: 10,
      //       spreadRadius: 1,
      //     ),
      //     BoxShadow(
      //       color: baseColor,
      //       offset: Offset(-5, -5),
      //       blurRadius: 10,
      //       spreadRadius: 1,
      //     ),
      //   ],
      // ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (controller.selectedImage.value != null) {
              return Container(
                margin: const EdgeInsets.only(bottom: 15, left: 10),
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      offset: const Offset(3, 3),
                      blurRadius: 5,
                    ),
                  ],
                  image: DecorationImage(
                    image: FileImage(controller.selectedImage.value!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -5,
                      right: -5,
                      child: IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: controller.clearImage,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          Row(
            children: [
              GestureDetector(
                onTap: controller.showImageSourceOptions,
                child: Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
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
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.grey.shade700,
                    size: 22,
                  ),
                ),
              ),

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
                      hintText: 'Ask or scan something...',
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

// =========================================================================
// Advanced AI Streaming Fade Text Animation
// =========================================================================
class StreamFadeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const StreamFadeText({super.key, required this.text, required this.style});

  @override
  State<StreamFadeText> createState() => _StreamFadeTextState();
}

class _StreamFadeTextState extends State<StreamFadeText>
    with SingleTickerProviderStateMixin {
  late String _oldText;
  late String _newText;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _oldText = widget.text;
    _newText = "";
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(StreamFadeText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text.length > oldWidget.text.length) {
      _oldText = oldWidget.text;
      _newText = widget.text.substring(oldWidget.text.length);
      _controller.forward(from: 0.0);
    } else if (widget.text != oldWidget.text) {
      _oldText = widget.text;
      _newText = "";
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 确保有一个保底颜色
    Color baseColor = widget.style.color ?? Colors.grey.shade800;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return RichText(
          text: TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: _oldText),

              TextSpan(
                text: _newText,
                style: widget.style.copyWith(
                  color: baseColor.withOpacity(_fadeAnimation.value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
