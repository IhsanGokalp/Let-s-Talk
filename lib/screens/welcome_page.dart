import 'dart:async';
import 'package:flutter/material.dart';
import 'setup_page1.dart'; // Import SetupPage1 instead of MeetingPage
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/user_data.dart'; // Add this import

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    // Start fade in
    _fadeController.forward();

    // Schedule navigation after 2 seconds
    Timer(const Duration(seconds: 2), () async {
      await _fadeController.reverse();
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    final user = await _userService.getUser();

    if (user != null && mounted) {
      final userData = UserData()
        ..name = user.name
        ..selectedLanguage = user.language
        ..selectedAgeRange = user.ageRange
        ..selectedTopics = Set.from(user.topics)
        ..selectedBuddy = user.aiBuddy;

      Navigator.pushReplacementNamed(
        context,
        '/mainConversation',
        arguments: userData,
      );
    } else if (mounted) {
      Navigator.pushReplacementNamed(context, '/setup1');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome To Let's Talk\nYour 24/7 English Speaking Buddy!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Color(0xFF98A882),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
