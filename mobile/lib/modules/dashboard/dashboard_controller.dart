import 'package:get/get.dart';

class DashboardController extends GetxController {
  // Reactive variable to track the current selected tab
  var tabIndex = 0.obs;

  void changeTabIndex(int index) {
    tabIndex.value = index;
  }
}