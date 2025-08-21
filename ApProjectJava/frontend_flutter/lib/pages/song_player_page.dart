import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart'; // اضافه شده
import '../models/song.dart';

class SongPlayerPage extends StatefulWidget {
  final List<Song> playlist;
  final int initialIndex;
  final String username;

  const SongPlayerPage({
    Key? key,
    required this.playlist,
    required this.initialIndex,
    required this.username,
  }) : super(key: key);

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage> {
  late AudioPlayer _player;
  late int currentIndex;
  bool loading = true;

  final Set<String> likedSongIds = {};

  Timer? _viewTimer;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    currentIndex = widget.initialIndex;

    _loadLikedSongsFromPrefs().then((_) {
      _loadAndPlay(widget.playlist[currentIndex]);
    });
  }

  Future<void> _loadLikedSongsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final likedList = prefs.getStringList('likedSongs_${widget.username}') ?? [];
    setState(() {
      likedSongIds.addAll(likedList);
    });
  }

  Future<void> _saveLikedSongsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('likedSongs_${widget.username}', likedSongIds.toList());
  }

  Future<void> _sendTcpCommand(String action, String payload) async {
    try {
      Socket socket = await Socket.connect("192.168.251.134", 12344);
      final req = {
        "action": action,
        "payloadJson": jsonEncode(payload),
      };
      socket.write(jsonEncode(req) + "\n");
      await socket.flush();
      await socket.close();
    } catch (e) {
      print("TCP error: $e");
    }
  }

  Future<void> _loadAndPlay(Song song) async {
    setState(() => loading = true);
    _viewTimer?.cancel();

    try {
      await _player.setUrl(song.url);
      await _player.play();

      _viewTimer = Timer(Duration(seconds: 10), () {
        _sendTcpCommand("increment_view", song.id);
        setState(() {
          song.views++;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing song: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _playNext() {
    if (currentIndex < widget.playlist.length - 1) {
      currentIndex++;
      _loadAndPlay(widget.playlist[currentIndex]);
    }
  }

  void _playPrevious() {
    if (currentIndex > 0) {
      currentIndex--;
      _loadAndPlay(widget.playlist[currentIndex]);
    }
  }

  void _togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _toggleLikeCurrentSong() {
    final song = widget.playlist[currentIndex];

    if (likedSongIds.contains(song.id)) {
      likedSongIds.remove(song.id);
      _sendTcpCommand("unlike_song", song.id);
      setState(() {
        song.likes = (song.likes > 0) ? song.likes - 1 : 0;
      });
    } else {
      likedSongIds.add(song.id);
      _sendTcpCommand("like_song", song.id);
      setState(() {
        song.likes++;
      });
    }

    // بعد از تغییر لایک‌ها ذخیره‌شون کن
    _saveLikedSongsToPrefs();
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.playlist[currentIndex];
    final isLiked = likedSongIds.contains(song.id);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(song.title),
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.music_note, size: 100, color: Colors.white30),
            ),
            const SizedBox(height: 24),
            Text(
              song.title,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(song.genre, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text("${song.likes}", style: const TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                Icon(Icons.remove_red_eye, color: Colors.cyanAccent),
                const SizedBox(width: 4),
                Text("${song.views}", style: const TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 32),
            if (loading)
              const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                  onPressed: _playPrevious,
                ),
                const SizedBox(width: 24),
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 64,
                        color: Colors.cyanAccent,
                      ),
                      onPressed: _togglePlayPause,
                    );
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                  onPressed: _playNext,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _toggleLikeCurrentSong,
              icon: Icon(Icons.favorite, color: isLiked ? Colors.white : Colors.grey[300]),
              label: Text(isLiked ? "Liked" : "Like", style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLiked ? Colors.redAccent : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}