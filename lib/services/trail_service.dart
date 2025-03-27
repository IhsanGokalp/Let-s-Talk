import 'package:shared_preferences/shared_preferences.dart';

class TrialService {
  static const String _trialCountKey = 'trial_count';
  static const int maxTrials = 2;

  static Future<int> getTrialCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_trialCountKey) ?? 0;
  }

  static Future<void> incrementTrialCount() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(_trialCountKey) ?? 0;
    await prefs.setInt(_trialCountKey, currentCount + 1);
  }

  static Future<bool> hasTrialRemaining() async {
    final trialCount = await getTrialCount();
    return trialCount < maxTrials;
  }
}
