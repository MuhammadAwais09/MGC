import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences
import 'package:manhattangoldcoin/screens/home_screen.dart'; // Import your HomeScreen
import 'package:manhattangoldcoin/screens/main_screen.dart'; // Import your MainScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set up animation controller and animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 3), // Updated to 3 seconds
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    // Check if the user has opened the app before
    _checkFirstTimeUser();
  }

  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      // Set the flag to false, indicating the user has opened the app
      await prefs.setBool('isFirstTime', false);
      // Navigate to MainScreen
      Timer(const Duration(seconds: 3), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      });
    } else {
      // Retrieve wallet info from SharedPreferences
      String? seedPhrase = prefs.getString('seedPhrase');
      String? privateKey = prefs.getString('privateKey');
      String? publicKey = prefs.getString('publicKey');
      String? address = prefs.getString('address');

      // Navigate to HomeScreen and pass the retrieved wallet info
      Timer(const Duration(seconds: 3), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              privateKey: privateKey ?? '',
              publicKey: publicKey ?? '',
              address: address ?? '',
              seedPhrase: seedPhrase ?? '',
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5D7),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/icons/splash.png', // Replace with your image path
                  width: screenSize.width * 0.9, // Increased width
                  height: screenSize.width * 0.8, // Increased height
                  fit: BoxFit.contain, // Ensure the image fits within its box
                ),
              ),
              // Remove the title text
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false, // This line removes the debug banner
    );
  }
}
