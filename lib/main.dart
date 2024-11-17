import 'package:flutter/material.dart';
import 'routes.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load the .env file explicitly for web
  await dotenv.load(fileName: "assets/.env");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Set the initial route
      routes: staticRoutes, // Static routes without arguments
      onGenerateRoute: generateRoute, // Dynamic routes with arguments
    );
  }
}
