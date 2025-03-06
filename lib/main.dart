import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/welcome_page.dart';
import 'screens/setup_page1.dart';

Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized first
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    await dotenv.load(fileName: "assets/.env");

    // Add initialization delay only for Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      debugPrint('Running on Android - adding initialization delay');
      await Future.delayed(const Duration(seconds: 2));
    }

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Ensure the app still runs even if there's an initialization error
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Let\'s Talk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomePage(), // Set explicit home widget
      onGenerateRoute: generateRoute,
    );
  }
}
