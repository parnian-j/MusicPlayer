import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../widgets/playlist_card.dart';
import 'song_player_page.dart';

class ExplorePage extends StatefulWidget {
  final String socketUrl;

  const ExplorePage({Key? key, required this.socketUrl}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late WebSocketChannel channel;
  bool loading = true;

  List<Song> allSongs = [];
  List<Song> popularSongs = [];
  List<Song> mostViewedSongs = [];

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse(widget.socketUrl));
    _fetchSongsFromServer();
  }

  void _fetchSongsFromServer() {
    final request = {
      "action": "get_explore_songs",
      "payloadJson": "{}"
    };
    print("Sending request to server:${jsonEncode(request)}");
    channel.sink.add(jsonEncode(request));

    channel.stream.listen((data) {
      print("Received from server: $data");
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          setState(() {
            allSongs = decoded.map<Song>((e) => Song.fromJson(e)).toList();
            popularSongs = List.from(allSongs)..sort((a, b) => b.likes.compareTo(a.likes));
            popularSongs = popularSongs.take(10).toList();
            mostViewedSongs = List.from(allSongs)..sort((a, b) => b.views.compareTo(a.views));
            mostViewedSongs = mostViewedSongs.take(10).toList();
            loading = false;
          });
        }
      } catch (e) {
        print('Error decoding songs: $e');
        setState(() => loading = false);
      }
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.cyanAccent,
        automaticallyImplyLeading: false,
        title: const Text('Explore', style: TextStyle(color: Colors.black)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بخش Top 10 Popular Songs
            _buildSectionTitle('Top 10 Popular Songs'),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: popularSongs.length,
                itemBuilder: (ctx, i) => PlaylistCard(
                  playlist: Playlist(
                    id: 'popular_$i',
                    name: popularSongs[i].title,
                    songs: [popularSongs[i]],
                    coverImageUrl: 'assets/images/popular.png',
                  ),
                  isSmall: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SongPlayerPage(
                          playlist: popularSongs,
                          initialIndex: i, username: '',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // بخش Top 10 Most Viewed Songs
            _buildSectionTitle('Top 10 Most Viewed Songs'),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: mostViewedSongs.length,
                itemBuilder: (ctx, i) => PlaylistCard(
                  playlist: Playlist(
                    id: 'mostviewed_$i',
                    name: mostViewedSongs[i].title,
                    songs: [mostViewedSongs[i]],
                    coverImageUrl: 'assets/images/view.png',
                  ),
                  isSmall: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SongPlayerPage(
                          playlist: mostViewedSongs,
                          initialIndex: i, username: '',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // بخش All Songs (به جای Genre)
            _buildSectionTitle('All Songs'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allSongs.length,
              itemBuilder: (ctx, i) {
                final song = allSongs[i];
                return ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.cyanAccent),
                  title: Text(song.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(song.genre, style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongPlayerPage(
                            playlist: allSongs,
                            initialIndex: i, username: '',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}