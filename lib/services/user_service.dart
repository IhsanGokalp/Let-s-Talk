import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/user_data.dart';

class UserService {
  static const String _userKey = 'user_data';
  static const String _userFileName = 'users.csv';

  Future<void> saveUser(UserData userData) async {
    try {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: userData.name ?? '',
        language: userData.selectedLanguage ?? '',
        ageRange: userData.selectedAgeRange ?? '',
        topics: userData.selectedTopics.toList(),
        aiBuddy: userData.selectedBuddy ?? '',
        registrationDate: DateTime.now(),
      );

      // Try to save to SharedPreferences
      await _saveToPreferences(user);

      // Backup to CSV
      await _saveToCSV(user);

      developer.log(
        'User saved successfully to both preferences and CSV',
        name: 'UserService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error saving user',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _saveToPreferences(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = user.toJson();
    await prefs.setString(_userKey, jsonEncode(userJson));
  }

  Future<void> _saveToCSV(User user) async {
    try {
      final directory = await _getLocalDirectory();
      final file = File('${directory.path}/$_userFileName');

      // Create CSV header if file doesn't exist
      if (!await file.exists()) {
        await file.writeAsString(
            'id,name,language,ageRange,topics,aiBuddy,registrationDate\n');
      }

      // Convert user data to CSV line
      final csvLine = '${user.id},"${user.name}","${user.language}",'
          '"${user.ageRange}","${user.topics.join(';')}",'
          '"${user.aiBuddy}","${user.registrationDate.toIso8601String()}"\n';

      // Append to file
      await file.writeAsString(csvLine, mode: FileMode.append);

      developer.log(
        'User saved to CSV',
        name: 'UserService',
        error: {'filePath': file.path},
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error saving to CSV',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Directory> _getLocalDirectory() async {
    try {
      // Try to get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      return appDir;
    } catch (e) {
      // Fallback to temporary directory if documents directory is not available
      return Directory.systemTemp;
    }
  }

  Future<User?> getUser() async {
    try {
      // First try to get from SharedPreferences
      final user = await _getUserFromPreferences();
      if (user != null) {
        developer.log(
          'User retrieved from SharedPreferences',
          name: 'UserService',
          error: {
            'userData': user.toJson(),
            'source': 'SharedPreferences',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        return user;
      }

      // If not found in preferences, try to get last user from CSV
      final csvUser = await _getLastUserFromCSV();
      if (csvUser != null) {
        developer.log(
          'User retrieved from CSV',
          name: 'UserService',
          error: {
            'userData': csvUser.toJson(),
            'source': 'CSV',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        return csvUser;
      }

      developer.log(
        'No user found in any storage',
        name: 'UserService',
      );
      return null;
    } catch (e, stackTrace) {
      developer.log(
        'Error retrieving user',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<User?> _getUserFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        final user = User.fromJson(jsonDecode(userData));
        // Pretty print the raw JSON data
        developer.log(
          'SharedPreferences data found',
          name: 'UserService',
          error: {
            'rawData':
                JsonEncoder.withIndent('  ').convert(jsonDecode(userData)),
            'storagePath': 'SharedPreferences:$_userKey',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        // Detailed user object logging
        developer.log(
          'User retrieved from SharedPreferences',
          name: 'UserService',
          error: {
            'id': user.id,
            'name': user.name,
            'language': user.language,
            'ageRange': user.ageRange,
            'topics': user.topics,
            'aiBuddy': user.aiBuddy,
            'registrationDate': user.registrationDate.toIso8601String(),
            'source': 'SharedPreferences',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        return user;
      }
      return null;
    } catch (e, stackTrace) {
      developer.log(
        'Error reading from SharedPreferences',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<User?> _getLastUserFromCSV() async {
    try {
      final directory = await _getLocalDirectory();
      final file = File('${directory.path}/$_userFileName');

      if (!await file.exists()) {
        developer.log(
          'CSV file not found',
          name: 'UserService',
          error: {'path': file.path},
        );
        return null;
      }

      final lines = await file.readAsLines();
      if (lines.length <= 1) {
        developer.log(
          'CSV file empty or only contains header',
          name: 'UserService',
          error: {'path': file.path},
        );
        return null;
      }

      // Get last line and parse it
      final lastLine = lines.last;
      developer.log(
        'Reading last CSV entry',
        name: 'UserService',
        error: {
          'rawData': lastLine,
          'filePath': file.path,
        },
      );

      final values = lastLine.split(',');
      return User(
        id: values[0],
        name: values[1].replaceAll('"', ''),
        language: values[2].replaceAll('"', ''),
        ageRange: values[3].replaceAll('"', ''),
        topics: values[4].replaceAll('"', '').split(';'),
        aiBuddy: values[5].replaceAll('"', ''),
        registrationDate: DateTime.parse(values[6].replaceAll('"', '')),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error reading from CSV',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> deleteUser() async {
    try {
      // Clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);

      // Optionally, delete CSV file
      final directory = await _getLocalDirectory();
      final file = File('${directory.path}/$_userFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      developer.log('Error deleting user', name: 'UserService', error: e);
    }
  }
}
