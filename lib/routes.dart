import 'package:flutter/material.dart';
import 'screens/welcome_page.dart';
import 'screens/setup_page1.dart';
import 'screens/setup_page2.dart';
import 'screens/setup_page3.dart';
import 'screens/review_page.dart';
import 'models/user_data.dart';
import 'screens/conversation_activity.dart';
import 'screens/conversation_history_screen.dart';
import 'screens/conversation_history_page.dart';

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => WelcomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );

    case '/setup1':
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SetupPage1(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );

    case '/setup2':
      if (settings.arguments is! UserData) return null;
      final userData = settings.arguments as UserData;
      return MaterialPageRoute(builder: (_) => SetupPage2(userData: userData));

    case '/setup3':
      if (settings.arguments is! UserData) return null;
      final userData = settings.arguments as UserData;
      return MaterialPageRoute(builder: (_) => SetupPage3(userData: userData));

    case '/review':
      if (settings.arguments is! UserData) return null;
      final userData = settings.arguments as UserData;
      return MaterialPageRoute(builder: (_) => ReviewPage(userData: userData));

    case '/mainConversation':
      if (settings.arguments is! UserData) return null;
      final userData = settings.arguments as UserData;
      return MaterialPageRoute(
          builder: (_) => ConversationActivity(userData: userData));

    case '/history':
      return MaterialPageRoute(builder: (_) => ConversationHistoryPage());

    default:
      // Return a 404 error page
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('Page not found: ${settings.name}'),
          ),
        ),
      );
  }
}
