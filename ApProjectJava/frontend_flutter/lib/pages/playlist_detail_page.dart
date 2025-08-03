import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'song_player_page.dart'; // 👈 اضافه شده برای پخش آهنگ

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
  late List<Song> songs;
  List<Song> filteredSongs = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    songs = List.from(widget.playlist.songs);
  }

  void _onSearch(String val) {
    setState(() {
      searchQuery = val;
      filteredSongs = songs
          .where((s) => s.title.toLowerCase().contains(val.toLowerCase()))
          .toList();
    });
  }

  void _addFromServer() async {
    Song? choice = await showDialog<Song>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Select song from server', style: TextStyle(color: Colors.cyanAccent)),
          children: widget.allSongs.map((s) {
            if (songs.contains(s)) return SizedBox();
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, s),
              child: Text(s.title, style: TextStyle(color: Colors.white)),
            );
          }).toList(),
        );
      },
    );
    if (choice != null) {
      setState(() {
        songs.add(choice);
      });
    }
  }

  void _addFromDevice() {
    final newSong = Song(
      id: DateTime.now().toString(),
      title: 'New Device Song',
      genre: '',
      addedDate: DateTime.now(),
      likes: 0,
      views: 0,
    );
    setState(() {
      songs.add(newSong);
    });
  }

  void _deleteSong(Song song) {
    setState(() {
      songs.remove(song);
    });
  }

  @override
  Widget build(BuildContext context) {
    final display = searchQuery.isEmpty ? songs : filteredSongs;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(widget.playlist.name),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            color: Colors.cyanAccent,
            onPressed: () {
              showModalBottomSheet(
                backgroundColor: Colors.grey[900],
                context: context,
                builder: (_) {
                  return Wrap(
                    children: [
                      ListTile(
                        leading: Icon(Icons.cloud_download, color: Colors.white),
                        title: Text('From server', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          _addFromServer();
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.file_upload, color: Colors.white),
                        title: Text('From device', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          _addFromDevice();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search in playlist...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: display.length,
              itemBuilder: (_, idx) {
                final s = display[idx];
                return ListTile(
                  title: Text(s.title, style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${s.genre} • ${s.addedDate.toLocal().toIso8601String().split('T')[0]}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.white),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      )
                    ],
                    onSelected: (v) {
                      if (v == 'delete') _deleteSong(s);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SongPlayerPage(
                          playlist: display,
                          initialIndex: idx,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}