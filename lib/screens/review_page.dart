import 'package:flutter/material.dart';
import '../models/user_data.dart';

class ReviewPage extends StatelessWidget {
  final UserData userData;

  ReviewPage({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Review Your Setup"),
            SizedBox(height: 20),

            // Display selected language
            Text(
                "Main Language: ${userData.selectedLanguage ?? 'Not selected'}"),

            // Display age range
            Text("Age Range: ${userData.selectedAgeRange ?? 'Not selected'}"),

            // Display selected topics
            Wrap(
              children: userData.selectedTopics.isNotEmpty
                  ? userData.selectedTopics
                      .map((topic) => Chip(label: Text(topic)))
                      .toList()
                  : [Text("No topics selected")],
            ),

            // Display selected AI buddy
            Text("AI Buddy: ${userData.selectedBuddy ?? 'No buddy selected'}"),

            Spacer(),
            ElevatedButton(
              onPressed: () {
                // Proceed to main conversation screen
              },
              child: Text("Begin Conversation"),
            ),
          ],
        ),
      ),
    );
  }
}
