class User {
  final String id;
  final String name;
  final String language;
  final String ageRange;
  final List<String> topics;
  final String aiBuddy;
  final DateTime registrationDate;

  User({
    required this.id,
    required this.name,
    required this.language,
    required this.ageRange,
    required this.topics,
    required this.aiBuddy,
    required this.registrationDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'language': language,
        'ageRange': ageRange,
        'topics': topics,
        'aiBuddy': aiBuddy,
        'registrationDate': registrationDate.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        language: json['language'],
        ageRange: json['ageRange'],
        topics: List<String>.from(json['topics']),
        aiBuddy: json['aiBuddy'],
        registrationDate: DateTime.parse(json['registrationDate']),
      );
}
