import 'package:flutter/material.dart';
import 'screens/welcome_page.dart';
import 'screens/setup_page1.dart';
import 'screens/setup_page2.dart';
import 'screens/setup_page3.dart';
import 'screens/review_page.dart';
import 'models/user_data.dart';
import '../screens/conversation_activity.dart';

/// Define the initial route and any routes that do not require arguments
final Map<String, WidgetBuilder> staticRoutes = {
  '/': (context) => WelcomePage(),
  '/setup1': (context) => SetupPage1(),
};

/// Generate routes dynamically, especially for pages that require arguments
Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/setup2':
      final userData = settings.arguments as UserData;
      return MaterialPageRoute(builder: (_) => SetupPage2(userData: userData));

    case '/setup3':
      final userData = settings.arguments as UserData;
      return MaterialPageRoute(builder: (_) => SetupPage3(userData: userData));

    case '/review':
      final userData = settings.arguments as UserData;
      return MaterialPageRoute(builder: (_) => ReviewPage(userData: userData));

    case '/mainConversation':
      final userData = settings.arguments as UserData;
      return MaterialPageRoute(
        builder: (_) => ConversationActivity(
            userData: userData), // Pass UserData to ConversationActivity
      );
    // Pass user data

    default:
      return null; // If the route is not defined, return null.
  }
}
