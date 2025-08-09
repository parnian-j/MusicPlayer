import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class SongPlayerPage extends StatefulWidget {
  final List<Song> playlist;
  final int initialIndex;

  const SongPlayerPage({
    Key? key,
    required this.playlist,
    required this.initialIndex, required String username,
  }) : super(key: key);

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage> {
  late AudioPlayer _player;
  late int currentIndex;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    currentIndex = widget.initialIndex;
    _loadAndPlay(widget.playlist[currentIndex]);
  }

  Future<void> _loadAndPlay(Song song) async {
    setState(() => loading = true);
    try {
      await _player.setUrl(song.url);
      await _player.play();
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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.playlist[currentIndex];

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
            // کاور آهنگ
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

            // عنوان آهنگ
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

            const SizedBox(height: 32),

            if (loading)
              const CircularProgressIndicator(color: Colors.cyanAccent),

            const SizedBox(height: 16),

            // کنترل پخش
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
          ],
        ),
      ),
    );
  }
}