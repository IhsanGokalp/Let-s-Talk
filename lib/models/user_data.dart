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
  static final List<String> topics = [
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

  static final List<String> buddies = [
    'Emir (Male)',
    'Kerem (Male)',
    'Yusuf (Male)',
    'Elif (Female)',
    'Aylin (Female)',
    'Defne (Female)'
  ];
  // User's name (nullable, will be filled later)
  String? name;

  // Other user-selected fields
  String? selectedLanguage;
  String? selectedAgeRange;
  Set<String> selectedTopics = {};
  String? selectedBuddy;

  UserData({
    this.selectedLanguage,
    this.selectedAgeRange,
    this.selectedBuddy,
    Set<String>? selectedTopics,
  }) : selectedTopics = selectedTopics ?? {};
}
