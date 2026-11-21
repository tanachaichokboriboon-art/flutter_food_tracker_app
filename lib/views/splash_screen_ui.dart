
// ignore_for_file: annotate_overrides, override_on_non_overriding_member

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_food_tracker_app/views/show_all_food_tracker_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF44336),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FoodTrackerApp());
}

// Main Application
class FoodTrackerApp extends StatelessWidget {
  const FoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreenUI(),
    );
  }
}

// Splash Screen UI
class SplashScreenUI extends StatefulWidget {
  const SplashScreenUI({super.key});

  @override
  State<SplashScreenUI> createState() => _SplashScreenUIState();
}

class _SplashScreenUIState extends State<SplashScreenUI> {

  @override
  void initState() {
    super.initState();

    // delay หน้าจอ 3 วิ แล้วเปิดไปหน้า ShowAllFoodTrackerUI()
    Future.delayed(
      const Duration(seconds: 3),
      () {
        // ตรวจสอบว่าหน้าจอยังทำงานอยู่
        if (!mounted) return;

        // เปิดหน้าถัดไปแบบย้อนกลับไม่ได้
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ShowAllFoodTrackerUI(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF44336),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Spacer(flex: 3),

              // Food Logo
              Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 35),

              // App Name
              const Text(
                'Food Tracker',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFEB3B),
                ),
              ),

              const SizedBox(height: 25),

              // Food Emojis
              const Text(
                '🍔  🍟  🌭  🍿  🍨  🧁',
                style: TextStyle(
                  fontSize: 30,
                ),
              ),

              const SizedBox(height: 45),

              // Loading Indicator
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: Color(0xFFFFEB3B),
                  strokeWidth: 5,
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
