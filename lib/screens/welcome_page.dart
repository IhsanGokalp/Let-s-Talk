import 'package:flutter/material.dart';
import '../utils/constants.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome To Let’s Talk\nYour 24/7 English Speaking Buddy!",
              textAlign: TextAlign.center,
              style: titleTextStyle,
            ),
            SizedBox(height: 40),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Color(0xFF98A882), // Custom green color
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                    context, '/setup1'); // Navigate to SetupPage1
              },
              child: Text("Get Started"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
