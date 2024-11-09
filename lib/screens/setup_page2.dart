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
  final List<String> _topics = [
    'Literature',
    'Sports',
    'Music',
    'Cooking',
    'Cartoons',
    'Drama',
    'Technology',
    'Travel',
    'Movies',
    'Videogames',
    'History',
    'TV Shows'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Setup - Interests"),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Just One More Information.",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text("Which topics are you interested in?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 20),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _topics.map((topic) {
                final isSelected =
                    widget.userData.selectedTopics.contains(topic);
                return ChoiceChip(
                  label: Text(topic),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        widget.userData.selectedTopics.add(topic);
                      } else {
                        widget.userData.selectedTopics.remove(topic);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // Pass userData to SetupPage3
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SetupPage3(userData: widget.userData),
                    ),
                  );
                },
                child: Text("Next Page"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
