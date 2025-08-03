import 'package:flutter/material.dart';
import '../models/playlist.dart';
import 'playlist_detail_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Playlist> playlists = [
    Playlist(id: 'all', name: 'All Songs', songs: [], coverImageUrl: ''),
    Playlist(id: 'recents', name: 'Recents', songs: [], coverImageUrl: ''),
    Playlist(id: 'favorites', name: 'Favorites', songs: [], coverImageUrl: ''),
  ];

  void _createNewPlaylist() {
    TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text("New Playlist", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _controller,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter playlist name",
              hintStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.cyanAccent)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Create", style: TextStyle(color: Colors.cyanAccent)),
              onPressed: () {
                final name = _controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    playlists.add(Playlist(
                      id: DateTime.now().toIso8601String(),
                      name: name,
                      songs: [], coverImageUrl: '',
                    ));
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deletePlaylist(Playlist playlist) {
    setState(() {
      playlists.removeWhere((p) => p.id == playlist.id);
    });
  }

  void _openPlaylistDetail(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailPage(
          playlist: playlist,
          allSongs: playlists.firstWhere((p) => p.id == 'all').songs,
        ),
      ),
    );
  }

  bool _isDefaultPlaylist(String id) {
    return id == 'all' || id == 'recents' || id == 'favorites';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Playlists',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [Colors.indigo, Colors.blue, Colors.cyan],
                  ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
                children: [
                  ...playlists.map((playlist) {
                    return GestureDetector(
                      onTap: () => _openPlaylistDetail(playlist),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.cyanAccent),
                            ),
                            padding: EdgeInsets.all(12),
                            child: Center(
                              child: Text(
                                playlist.name,
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          if (!_isDefaultPlaylist(playlist.id))
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _deletePlaylist(playlist),
                                child: Icon(Icons.close, color: Colors.redAccent, size: 20),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  GestureDetector(
                    onTap: _createNewPlaylist,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyanAccent),
                      ),
                      child: Center(
                        child: Icon(Icons.add, size: 40, color: Colors.cyanAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}