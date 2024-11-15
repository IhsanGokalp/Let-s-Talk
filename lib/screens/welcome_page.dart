import 'dart:async';
import 'package:flutter/material.dart';
import 'setup_page1.dart'; // Import SetupPage1 instead of MeetingPage

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    // Start a timer to delay for 2 seconds and then navigate to SetupPage1
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SetupPage1()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Intro Text
              Text(
                "Welcome To Let’s Talk\nYour 24/7 English Speaking Buddy!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 40),

              // Circular Design Element
              Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: Color(0xFF98A882), // Custom green color
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
