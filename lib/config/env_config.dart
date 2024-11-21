// lib/config/env_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get openAiApiKey =>
      dotenv.env['OPENAI_API_KEY'] ??
      ''; // Return empty string or some default value if key is not found
}
