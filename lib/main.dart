import 'package:flutter/material.dart';
import 'routes.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() async {
  // Add this line to initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

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
