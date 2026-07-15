import 'package:get/get.dart';
import 'package:pos_vision_app/modules/vision/vision_controller.dart';

class VisionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VisionController>(() => VisionController());
  }
}