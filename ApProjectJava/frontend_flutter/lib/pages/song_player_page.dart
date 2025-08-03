import 'package:flutter/material.dart';
import '../models/song.dart';

class SongPlayerPage extends StatefulWidget {
  final List<Song> playlist; // لیست آهنگ‌ها (مثلاً پلی‌لیست)
  final int initialIndex; // آهنگ انتخاب‌شده

  SongPlayerPage({required this.playlist, required this.initialIndex});

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage> {
  late int currentIndex;
  bool isPlaying = true;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void _playNext() {
    if (currentIndex < widget.playlist.length - 1) {
      setState(() {
        currentIndex++;
        isPlaying = true;
      });
    }
  }

  void _playPrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.playlist[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // تصویر یا نمای آلبوم
            Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.music_note, color: Colors.white38, size: 100),
            ),
            SizedBox(height: 32),

            // اطلاعات آهنگ
            Text(
              currentSong.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              currentSong.genre,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 32),

            // کنترلر موزیک
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous, size: 36, color: Colors.white),
                  onPressed: _playPrevious,
                ),
                SizedBox(width: 24),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    size: 64,
                    color: Colors.cyanAccent,
                  ),
                  onPressed: _togglePlayPause,
                ),
                SizedBox(width: 24),
                IconButton(
                  icon: Icon(Icons.skip_next, size: 36, color: Colors.white),
                  onPressed: _playNext,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}