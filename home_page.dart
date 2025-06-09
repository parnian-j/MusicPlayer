import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home_page extends StatefulWidget {
  const Home_page({super.key});

  @override
  State<Home_page> createState() => _Home_pageState();
}

class _Home_pageState extends State<Home_page> {
  final List<String> _customPlaylists = [];
  final List<String> _defaultPlaylists = [
    'All Songs',
    'Favourites',
    'Recently Played',
  ];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlaylists = prefs.getStringList('custom_playlists') ?? [];
    setState(() {
      _customPlaylists.addAll(savedPlaylists);
    });
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_playlists', _customPlaylists);
  }

  void _createNewPlaylist() {
    showDialog(
      context: context,
      builder: (context) {
        String newName = '';
        return AlertDialog(
          title: const Text('Create Playlist'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter playlist name'),
            onChanged: (value) => newName = value.trim(),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (newName.isEmpty) return;
                final allPlaylists = [..._defaultPlaylists, ..._customPlaylists];
                if (allPlaylists.contains(newName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name already exists')),
                  );
                  return;
                }
                setState(() {
                  _customPlaylists.insert(0, newName); // به جای بعد ➕ بیاد قبلش
                });
                await _savePlaylists();
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _playlistTile(String name, {bool isAdd = false}) {
    return GestureDetector(
      onTap: isAdd ? _createNewPlaylist : () {},
      child: Container(
        decoration: BoxDecoration(
          color: isAdd ? Colors.transparent : Colors.cyanAccent.withOpacity(0.2),
          border: Border.all(color: Colors.cyanAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isAdd
              ? const Icon(Icons.add, size: 40, color: Colors.cyanAccent)
              : Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _defaultTiles = _defaultPlaylists.map((name) => _playlistTile(name)).toList();
    final _customTiles = _customPlaylists.map((name) => _playlistTile(name)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meowbeat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            ..._defaultTiles,
            ..._customTiles,
            _playlistTile('', isAdd: true),
          ],
        ),
      ),
    );
  }
}