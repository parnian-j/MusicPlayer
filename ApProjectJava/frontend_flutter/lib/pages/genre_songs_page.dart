import 'package:flutter/material.dart';
import '../models/song.dart';

class GenreSongsPage extends StatelessWidget {
  final String genre;
  final List<Song> songs;

  const GenreSongsPage({required this.genre, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text('$genre Songs'),
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (ctx, i) {
          final song = songs[i];
          return ListTile(
            title: Text(song.title, style: TextStyle(color: Colors.white)),
            subtitle: Text('Views: ${song.views}, Likes: ${song.likes}',
                style: TextStyle(color: Colors.white70)),
            leading: Icon(Icons.music_note, color: Colors.cyanAccent),
          );
        },
      ),
    );
  }
}