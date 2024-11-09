class UserData {
  static final List<String> languages = [
    'Mandarin Chinese',
    'Spanish',
    'Hindi',
    'Arabic',
    'Bengali',
    'Portuguese',
    'Russian',
    'Japanese'
  ];

  static final List<String> ageRanges = [
    '16 - 20',
    '21 - 25',
    '26 - 30',
    '31 - 35',
    '36 - 40',
    '41 - 45',
    '46 - 50',
    '51 - 55'
  ];

  String? selectedLanguage;
  String? selectedAgeRange;
  Set<String> selectedTopics = {}; // Holds the selected topics
  String? selectedBuddy; // Holds the selected AI buddy name
}
