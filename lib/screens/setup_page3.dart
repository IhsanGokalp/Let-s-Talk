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
  // List of AI buddies with names and genders, where values may be nullable
  final List<Map<String, String?>> _aiBuddies = [
    {'name': 'Emir', 'gender': 'Male'},
    {'name': 'Kerem', 'gender': 'Male'},
    {'name': 'Yusuf', 'gender': 'Male'},
    {'name': 'Elif', 'gender': 'Female'},
    {'name': 'Aylin', 'gender': 'Female'},
    {'name': 'Defne', 'gender': 'Female'},
    // Example of a buddy with null values
  ];

  String?
      _selectedBuddy; // Holds the selected buddy's name, null by default for no selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Your AI Buddy"),
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
              "Now Let's Create Your Speaking Buddy.",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "What would you like to name your buddy?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20),

            // List of buddies with RadioListTile
            Expanded(
              child: ListView.builder(
                itemCount: _aiBuddies.length,
                itemBuilder: (context, index) {
                  final buddy = _aiBuddies[index];
                  final buddyName = buddy['name'] ??
                      "Unnamed"; // Provide fallback if name is null
                  final buddyGender = buddy['gender'] ??
                      "Unknown"; // Provide fallback if gender is null

                  return RadioListTile<String>(
                    title: Text("$buddyName ($buddyGender)"),
                    value: buddyName, // Non-nullable value for selection
                    groupValue: _selectedBuddy,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedBuddy = value;
                        widget.userData.selectedBuddy =
                            value; // Save selection to UserData
                      });
                    },
                  );
                },
              ),
            ),

            Spacer(),

            // Confirm button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedBuddy != null) {
                    // Proceed to the review page with selected buddy
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReviewPage(userData: widget.userData),
                      ),
                    );
                  } else {
                    // Show a dialog if no buddy is selected
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Selection Required"),
                        content: Text("Please select an AI buddy to proceed."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text("Next Page"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.black, // Use backgroundColor instead of primary
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
