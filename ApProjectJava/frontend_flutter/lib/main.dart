import 'package:flutter/material.dart';
import 'pages/Signup_page.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';

void main() {
  runApp(NavaakApp());
}

class NavaakApp extends StatefulWidget {
  @override
  State<NavaakApp> createState() => _NavaakAppState();
}

class _NavaakAppState extends State<NavaakApp> {
  bool isDarkMode = true;

  void _toggleTheme(bool isDark) {
    setState(() {
      isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navaak App',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: Colors.black,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: Colors.white,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => LoginPage(),
        '/signup': (_) => SignupPage(),
        '/main': (context) {
          // گرفتن username از arguments
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          String username = args != null && args['username'] != null
              ? args['username']
              : 'user123';
          return MainPage(
            username: username,
            isDarkMode: isDarkMode,
            onThemeChanged: _toggleTheme,
          );
        },
      },
    );
  }
}