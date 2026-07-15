import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'data/provider/api_provider.dart';
import 'routes/app_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(ApiProvider());

  runApp(const SmartPosApp());
}

class SmartPosApp extends StatelessWidget {
  const SmartPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart POS Vision Engine',
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE0E5EC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE0E5EC),
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
      ),
    );
  }
}