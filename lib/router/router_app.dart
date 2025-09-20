import 'package:flutter/material.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/forgot_passwor_page.dart';
import '../screens/auth/reset_password_page.dart';
import '../screens/main/settings_screen.dart';
import '../screens/home_page.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/main/task_screen.dart';
import '../screens/main/profile_screen.dart';
import '../screens/main/friends_screen.dart';
import '../screens/main/edit_profile_page.dart';
import '../screens/auth/network_test_screen.dart';

// Простые маршруты
final routes = {
  '/home': (context) => const TaskListScreen(),
  '/signin': (context) => const SignInPage1(),
  '/settings': (context) => const SettingsPage(),
  '/home_page': (context) => HomePage(),
  '/registration': (context) => RegistrationScreen(),
  '/profile': (context) => const ProfilePage(),
  '/friends': (context) => const FriendsPage(),
  '/forgot_password': (context) => const ForgotPasswordPage(),
  '/reset_password': (context) => const ResetPasswordPage(),
  '/test_con': (context) => const NetworkTestScreen(),
};

// Сложные маршруты (с аргументами)
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/edit_profile':
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => EditProfilePage(profileData: args ?? {}),
      );
    default:
      final pageBuilder = routes[settings.name];
      if (pageBuilder != null) {
        return MaterialPageRoute(
          builder: (context) => pageBuilder(context),
        );
      }
      return null;
  }
}
