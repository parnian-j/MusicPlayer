import 'package:flutter/material.dart';
import 'home_page.dart';
import 'explore_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  final String username;
  final bool isDarkMode;
  final Function(bool)? onThemeChanged;

  const MainPage({
    Key? key,
    required this.username,
    required this.isDarkMode,
    this.onThemeChanged,
  }) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late bool _isDarkMode;

  // ⬇️ کلید برای دسترسی به State هوم
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>(); // ← این

  // ⬇️ صفحات را یک‌بار می‌سازیم
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;

    _pages = [
      HomePage(
        key: _homeKey,
        socketUrl: 'ws://172.20.194.126:12345',
        username: widget.username,
      ),
      ExplorePage(socketUrl: 'ws://172.20.194.126:12345'),
      ProfilePage(
        username: widget.username,
        isDarkMode: _isDarkMode,
        onThemeChanged: (val) {
          setState(() {
            _isDarkMode = val;
          });
          widget.onThemeChanged?.call(val);
        },
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _homeKey.currentState?.forceRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color _bgColor = _isDarkMode ? Colors.black : Colors.white;
    final Color _selectedColor = Colors.cyanAccent;
    final Color _unselectedColor = _isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: _bgColor,

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: _bgColor,
        selectedItemColor: _selectedColor,
        unselectedItemColor: _unselectedColor,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}


