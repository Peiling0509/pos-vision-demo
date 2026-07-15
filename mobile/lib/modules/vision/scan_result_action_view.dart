import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_vision_app/modules/vision/vision_controller.dart';
import '../../data/provider/api_provider.dart';
// import 'detection_model.dart'; // 确保引入你的模型

class ScanResultActionView extends StatelessWidget {
  const ScanResultActionView({super.key});

  final Color baseColor = const Color(0xFFE0E5EC);

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final XFile image = args['image'];
    final List<dynamic> detections = args['detections'];
    final double imgW = args['imageWidth'];
    final double imgH = args['imageHeight'];

    final String? scannedSku = args['sku'];

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        backgroundColor: baseColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.grey.shade800,
          ),
          onPressed: () {
            Get.find<VisionController>().resetState();
            Get.back();
          },
        ),
        title: Text(
          'Confirm Results',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            height: 280,
            width: double.infinity,
            decoration: _getNeumorphicDecoration(borderRadius: 20, baseColor: baseColor),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double viewW = constraints.maxWidth;
                  double viewH = constraints.maxHeight;

                  double scale = (viewW / imgW < viewH / imgH)
                      ? (viewW / imgW)
                      : (viewH / imgH);

                  double renderedW = imgW * scale;
                  double renderedH = imgH * scale;

                  double offsetX = (viewW - renderedW) / 2;
                  double offsetY = (viewH - renderedH) / 2;

                  return Stack(
                    children: [
                      Container(
                        width: viewW,
                        height: viewH,
                        color: Colors.black87,
                        child: Image.file(
                          File(image.path),
                          fit: BoxFit.contain,
                        ),
                      ),
                      ...detections.map((item) {
                        List<double> box = item.box;
                        double conf = item.confidence;
                        String label = item.label;

                        Color boxColor;
                        if (conf >= 0.85) {
                          boxColor = const Color(0xFF00E676);
                        } else if (conf >= 0.60) {
                          boxColor = Colors.orangeAccent;
                        } else {
                          boxColor = Colors.redAccent;
                        }

                        double left = (box[0] * scale) + offsetX;
                        double top = (box[1] * scale) + offsetY;
                        double width = (box[2] - box[0]) * scale;
                        double height = (box[3] - box[1]) * scale;

                        return Positioned(
                          left: left,
                          top: top,
                          width: width,
                          height: height,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: boxColor, width: 2.0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: boxColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(6),
                                  ),
                                ),
                                child: Text(
                                  "$label ${(conf * 100).toInt()}%",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Detected Items (${detections.length})',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: detections.length,
              itemBuilder: (context, index) {
                final item = detections[index];
                return DetectionItemCard(
                  item: item,
                  sku: scannedSku,
                  baseColor: baseColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static BoxDecoration _getNeumorphicDecoration({required double borderRadius, required Color baseColor}) {
    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade400,
          offset: const Offset(6, 6),
          blurRadius: 12,
          spreadRadius: 1,
        ),
        const BoxShadow(
          color: Colors.white,
          offset: Offset(-6, -6),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ],
    );
  }
}

class DetectionItemCard extends StatefulWidget {
  final dynamic item;
  final String? sku;
  final Color baseColor;

  const DetectionItemCard({
    super.key,
    required this.item,
    required this.sku,
    required this.baseColor,
  });

  @override
  State<DetectionItemCard> createState() => _DetectionItemCardState();
}

class _DetectionItemCardState extends State<DetectionItemCard> {
  bool _isLoading = false;
  bool _isAdded = false;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String actionText;
    IconData actionIcon;

    if (widget.item.confidence >= 0.85) {
      statusColor = const Color(0xFF00E676);
      actionText = 'Add';
      actionIcon = Icons.add_task_rounded;
    } else if (widget.item.confidence >= 0.60) {
      statusColor = Colors.orangeAccent;
      actionText = 'Verify';
      actionIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Colors.redAccent;
      actionText = 'Edit';
      actionIcon = Icons.edit_rounded;
    }

    // 如果已经入库成功，改变视觉状态
    if (_isAdded) {
      statusColor = Colors.grey.shade500;
      actionText = 'Added';
      actionIcon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: ScanResultActionView._getNeumorphicDecoration(
          borderRadius: 16,
          baseColor: widget.baseColor
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: widget.item.confidence,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(_isAdded ? Colors.grey.shade400 : statusColor),
                ),
                Center(
                  child: Text(
                    '${(widget.item.confidence * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 商品名称与状态文本
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isAdded ? 'Successfully synced' : (widget.item.confidence >= 0.85 ? 'High Accuracy' : 'Needs Review'),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () async {
              if (_isAdded || _isLoading) return;

              if (widget.item.confidence < 0.85) {
                Get.snackbar(
                  'Verification Required',
                  'Please manually verify this item before adding.',
                  backgroundColor: Colors.orangeAccent,
                  colorText: Colors.white,
                );
                return;
              }
              setState(() {
                _isLoading = true;
              });

              try {
                // 2. 调用真实 API，带上 sku 参数
                final response = await Get.find<ApiProvider>().addToInventory(
                  widget.item.label,
                  1,
                  sku: widget.sku,
                );

                if (response['status'] == 'success') {
                  // 3. 成功后更新为 Added 状态
                  setState(() {
                    _isLoading = false;
                    _isAdded = true;
                  });

                  // 注意：这里移除了 Get.back()，允许用户留在页面继续添加其他商品
                }
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });

                Get.snackbar(
                  'Error',
                  'Failed to sync with server.',
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.baseColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: _isAdded
                    ? []
                    : [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: _isLoading
                  ? SizedBox(
                width: 50,
                height: 16,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ),
              )
                  : Row(
                children: [
                  Icon(actionIcon, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    actionText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}