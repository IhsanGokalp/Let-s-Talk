import 'package:flutter/material.dart';
import '../models/user_data.dart';
import 'review_page.dart';

class SetupPage3 extends StatefulWidget {
  final UserData userData;

  SetupPage3({required this.userData});

  @override
  _SetupPage3State createState() => _SetupPage3State();
}

class _SetupPage3State extends State<SetupPage3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          // UI for selecting AI buddy
          ElevatedButton(
            onPressed: () {
              // Pass userData to the ReviewPage
              Navigator.pushNamed(
                context,
                '/review',
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
