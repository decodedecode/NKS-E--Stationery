import 'package:flutter/material.dart';
import 'package:nks/pages/onboarding.dart';
import 'package:nks/pages/signup.dart';
import '../pages/homepage.dart';
import '../pages/login.dart';


class Routes {
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePageScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingApp());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage()); // Default to login
    }
  }
}
