import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/explore_screen.dart';
import '../screens/profile_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

void main() {
  runApp(const MeowbeatApp());
}

class MeowbeatApp extends StatelessWidget {
  const MeowbeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meowbeat',
      theme: ThemeData.dark(),

      initialRoute: '/login',

      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => const MainPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Home_page(),
    ExploreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.cyanAccent,
        backgroundColor: Colors.black,
        unselectedItemColor: Colors.white54,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}