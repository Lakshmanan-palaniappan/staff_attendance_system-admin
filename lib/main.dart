import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'screens/admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final loggedIn = prefs.getBool("isAdminLogged") ?? false;

  runApp(AdminApp(initialRoute: loggedIn ? "/home" : "/login"));
}

class AdminApp extends StatelessWidget {
  final String initialRoute;
  const AdminApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Admin Dashboard",
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        "/login": (_) => const AdminLoginPage(),
        "/home": (_) => const AdminHome(),
      },
    );
  }
}
