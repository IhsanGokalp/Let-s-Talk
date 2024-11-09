import 'package:flutter/material.dart';
import '../models/user_data.dart';
import 'setup_page3.dart';

class SetupPage2 extends StatefulWidget {
  final UserData userData;

  SetupPage2({required this.userData});

  @override
  _SetupPage2State createState() => _SetupPage2State();
}

class _SetupPage2State extends State<SetupPage2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          // UI for selecting interests
          ElevatedButton(
            onPressed: () {
              // Pass userData to the next page
              Navigator.pushNamed(
                context,
                '/setup3',
                arguments: widget.userData, // Pass the UserData instance
              );
            },
            child: Text("Next Page"),
          ),
        ],
      ),
    );
  }
}
