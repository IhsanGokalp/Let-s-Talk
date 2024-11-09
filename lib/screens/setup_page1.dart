import 'package:flutter/material.dart';
import '../models/user_data.dart';
import 'setup_page2.dart';

class SetupPage1 extends StatefulWidget {
  @override
  _SetupPage1State createState() => _SetupPage1State();
}

class _SetupPage1State extends State<SetupPage1> {
  final UserData _userData = UserData(); // Initialize UserData

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Setup")),
      body: Column(
        children: [
          // UI for entering Name, Language, and Age Range
          ElevatedButton(
            onPressed: () {
              // Navigate to SetupPage2 with _userData as an argument
              Navigator.pushNamed(
                context,
                '/setup2',
                arguments: _userData,
              );
            },
            child: Text("Next Page"),
          ),
        ],
      ),
    );
  }
}
