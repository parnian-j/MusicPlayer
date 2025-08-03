import 'package:flutter/material.dart';
import 'pages/Signup_page.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';

void main() {
  runApp(NavaakApp());
}

class NavaakApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navaak App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: Colors.black,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => LoginPage(),
        '/signup': (_) => SignupPage(),
        '/main': (_) => MainPage(), // صفحه اصلی با bottom nav
      },
    );
  }
}