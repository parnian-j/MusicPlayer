import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'song_player_page.dart';

class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;
  final List<Song> allSongs;

  const PlaylistDetailPage({
    Key? key,
    required this.playlist,
    required this.allSongs,
  }) : super(key: key);

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late Playlist playlist;

  @override
  void initState() {
    super.initState();
    playlist = widget.playlist;
  }

  Future<void> _copyPlaylistJson() async {
    Map<String, dynamic> plMap = {
      'id': playlist.id,
      'name': playlist.name,
      'coverImageUrl': playlist.coverImageUrl,
      'songs': playlist.songs.map((s) {
        return {
          'id': s.id,
          'title': s.title,
          'genre': s.genre,
          'likes': s.likes,
          'views': s.views,
          'url': s.url,
          'addedDate': s.addedDate.toIso8601String(),
        };
      }).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(plMap);

    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playlist JSON copied to clipboard')),
    );
  }

  Future<void> _addSongToPlaylist() async {
    final Song? picked = await showDialog<Song>(
      context: context,
      builder: (_) {
        final available = widget.allSongs
            .where((s) => !playlist.songs.any((ps) => ps.id == s.id))
            .toList();

        return SimpleDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Add song to playlist',
              style: TextStyle(color: Colors.cyanAccent)),
          children: available.isEmpty
              ? [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No available songs to add',
                  style: TextStyle(color: Colors.white70)),
            )
          ]
              : available
              .map((s) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, s),
            child: Text(s.title,
                style: const TextStyle(color: Colors.white)),
          ))
              .toList(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        playlist.songs.add(picked);
      });
    }
  }

  void _removeSong(Song s) {
    setState(() {
      playlist.songs.removeWhere((ps) => ps.id == s.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(playlist.name, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.cyanAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            tooltip: 'Share (copy JSON)',
            onPressed: _copyPlaylistJson,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _addSongToPlaylist,
            tooltip: 'Add Song',
          ),
        ],
      ),
      body: playlist.songs.isEmpty
          ? Center(
        child: Text('No songs in this playlist',
            style: TextStyle(color: Colors.grey[400])),
      )
          : ListView.builder(
        itemCount: playlist.songs.length,
        itemBuilder: (context, idx) {
          final song = playlist.songs[idx];
          return ListTile(
            leading:
            const Icon(Icons.music_note, color: Colors.cyanAccent),
            title: Text(song.title,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text('Genre: ${song.genre}',
                style: TextStyle(color: Colors.grey[400])),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _removeSong(song),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SongPlayerPage(
                    playlist: playlist.songs,
                    initialIndex: idx,
                    username: '',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

