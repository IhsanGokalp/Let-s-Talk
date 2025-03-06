import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../services/user_service.dart';

class ReviewPage extends StatefulWidget {
  final UserData userData;

  ReviewPage({required this.userData});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final UserService _userService = UserService();
  String? selectedLanguage;
  String? selectedAgeRange;
  Set<String> selectedTopics = {};
  String? selectedBuddy;

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.userData.selectedLanguage;
    selectedAgeRange = widget.userData.selectedAgeRange;
    selectedTopics = Set.from(widget.userData.selectedTopics);

    // Ensure selectedBuddy is valid or reset to null if not in buddies list
    selectedBuddy = UserData.buddies.contains(widget.userData.selectedBuddy)
        ? widget.userData.selectedBuddy
        : null;
  }

  void updateUserData() {
    widget.userData.selectedLanguage = selectedLanguage;
    widget.userData.selectedAgeRange = selectedAgeRange;
    widget.userData.selectedTopics = selectedTopics;
    widget.userData.selectedBuddy = selectedBuddy;
  }

  void _saveUserAndNavigate() async {
    try {
      await _userService.saveUser(widget.userData);

      // Navigate to conversation
      Navigator.pushNamed(
        context,
        '/mainConversation',
        arguments: widget.userData,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save user data')),
      );
    }
  }

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

            // Editable Main Language
            Text(
              "What is your main language?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: UserData.languages.contains(selectedLanguage)
                  ? selectedLanguage
                  : null,
              hint: Text("Select your language"),
              onChanged: (String? newValue) {
                setState(() {
                  selectedLanguage = newValue;
                  updateUserData();
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

            // Editable Age Range
            Text(
              "How old are you?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: UserData.ageRanges.contains(selectedAgeRange)
                  ? selectedAgeRange
                  : null,
              hint: Text("Select your age range"),
              onChanged: (String? newValue) {
                setState(() {
                  selectedAgeRange = newValue;
                  updateUserData();
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
            SizedBox(height: 20),

            // Editable Topics of Interest
            Text(
              "Which topics are you interested in?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: UserData.topics.map((topic) {
                final isSelected = selectedTopics.contains(topic);
                return ChoiceChip(
                  label: Text(topic),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      isSelected
                          ? selectedTopics.remove(topic)
                          : selectedTopics.add(topic);
                      updateUserData();
                    });
                  },
                  selectedColor: Color(0xFF98A882),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // Editable AI Buddy
            Text(
              "Your Speaking Buddy:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: UserData.buddies.contains(selectedBuddy)
                  ? selectedBuddy
                  : null,
              hint: Text("Select your buddy"),
              onChanged: (String? newValue) {
                setState(() {
                  selectedBuddy = newValue;
                  updateUserData();
                });
              },
              items: UserData.buddies
                  .map<DropdownMenuItem<String>>((String buddy) {
                return DropdownMenuItem<String>(
                  value: buddy,
                  child: Text(buddy),
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

            // Begin Conversation Button
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: _saveUserAndNavigate,
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
