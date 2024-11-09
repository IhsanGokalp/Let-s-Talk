class UserData {
  // Define static lists for language and age range options
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

  // User's name (nullable, will be filled later)
  String? name;

  // Other user-selected fields
  String? selectedLanguage;
  String? selectedAgeRange;
  Set<String> selectedTopics = {}; // User's interests (topics)
  String? selectedBuddy; // AI buddy name

  // Constructor (optional, could add default values if necessary)
  UserData({
    this.name,
    this.selectedLanguage,
    this.selectedAgeRange,
    this.selectedBuddy,
    Set<String>? selectedTopics,
  }) : selectedTopics = selectedTopics ?? {};
}
