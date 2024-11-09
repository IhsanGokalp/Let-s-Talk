import 'package:flutter/material.dart';
import '../models/user_data.dart';

class ReviewPage extends StatelessWidget {
  final UserData userData;

  ReviewPage({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Thank You.\nPlease Review The Following",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Main Language Display
            Text(
              "What is your main language?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                userData.selectedLanguage ?? "Not selected",
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),

            // Age Range Display
            Text(
              "How old are you?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                userData.selectedAgeRange ?? "Not selected",
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),

            // Topics of Interest Display
            Text(
              "Which topics are you interested in?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: userData.selectedTopics.isNotEmpty
                  ? userData.selectedTopics.map((topic) {
                      return Chip(
                        label: Text(
                          topic,
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor:
                            Color(0xFF98A882), // Custom green color for chips
                      );
                    }).toList()
                  : [
                      Text("No topics selected",
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700]))
                    ],
            ),
            SizedBox(height: 20),

            // AI Buddy Display
            Text(
              "Your Speaking Buddy:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                userData.selectedBuddy ?? "No buddy selected",
                style: TextStyle(fontSize: 16),
              ),
            ),

            Spacer(),

            // Begin Conversation Button
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the main conversation page or start the conversation
                  Navigator.pushNamed(context,
                      '/mainConversation'); // Replace with actual route if needed
                },
                child: Text("Begin Conversation"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
