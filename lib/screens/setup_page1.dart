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
      appBar: AppBar(
        title: Text("Setup"),
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
              "To Begin,\nWe Need To Know A Little Bit About You...",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Input for Name
            TextField(
              decoration: InputDecoration(
                labelText: "What is your Name?",
                hintText: "Enter your name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                _userData.name = value;
              },
            ),

            SizedBox(height: 20),

            // Dropdown for Language
            Text(
              "What is your main language?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _userData.selectedLanguage,
              hint: Text("Select your language"),
              onChanged: (String? newValue) {
                setState(() {
                  _userData.selectedLanguage = newValue;
                });
              },
              items: UserData.languages
                  .map<DropdownMenuItem<String>>((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),

            SizedBox(height: 20),

            // Dropdown for Age
            Text(
              "How old are you?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _userData.selectedAgeRange,
              hint: Text("Select your age range"),
              onChanged: (String? newValue) {
                setState(() {
                  _userData.selectedAgeRange = newValue;
                });
              },
              items: UserData.ageRanges
                  .map<DropdownMenuItem<String>>((String ageRange) {
                return DropdownMenuItem<String>(
                  value: ageRange,
                  child: Text(ageRange),
                );
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),

            Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // Pass _userData to SetupPage2
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetupPage2(userData: _userData),
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
