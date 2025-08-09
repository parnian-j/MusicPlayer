// lib/pages/home_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:file_picker/file_picker.dart';

import '../models/song.dart';
import '../models/playlist.dart';
import '../pages/song_player_page.dart';
import 'playlist_detail_page.dart';

enum SortOption { likes, addedDate, recent, alphabet }

class HomePage extends StatefulWidget {
  final String socketUrl;
  const HomePage({Key? key, required this.socketUrl}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late WebSocketChannel channel;

  // آهنگ‌هایی که کاربر در هوم اضافه می‌کند (مجزا از پلی‌لیست‌ها)
  List<Song> allSongs = [];

  // آهنگ‌های موجود در سرور (برای انتخاب هنگام Add from server)
  List<Song> serverSongs = [];

  // پلی‌لیست‌ها (بخش جدا، فعلاً کاری به add-song نداره)
  List<Playlist> playlists = [];

  SortOption selectedSort = SortOption.likes;
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse(widget.socketUrl));
    _loadAllSongs();
    _loadPlaylists();
    _fetchServerSongs();
  }

  // ---------------------------------------
  // persistence برای allSongs
  Future<void> _loadAllSongs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('allSongs');
      if (stored != null) {
        final decoded = jsonDecode(stored) as List;
        setState(() {
          allSongs = decoded.map<Song>((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (e) {
      print("Error loading allSongs: $e");
    }
  }

  Future<void> _saveAllSongs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(allSongs.map((s) => s.toJson()).toList());
      await prefs.setString('allSongs', encoded);
    } catch (e) {
      print("Error saving allSongs: $e");
    }
  }

  // ---------------------------------------
  // persistence برای playlists
  Future<void> _loadPlaylists() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('playlists');
      if (stored != null) {
        final decoded = jsonDecode(stored) as List;
        setState(() {
          playlists = decoded.map<Playlist>((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (e) {
      print("Error loading playlists: $e");
    }
  }

  Future<void> _savePlaylists() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(playlists.map((p) => p.toJson()).toList());
      await prefs.setString('playlists', encoded);
    } catch (e) {
      print("Error saving playlists: $e");
    }
  }

  // ---------------------------------------
  // وب‌سوکت — گرفتن لیست سرور
  void _fetchServerSongs() {
    final request = {"action": "get_explore_songs", "payloadJson": "{}"};
    channel.sink.add(jsonEncode(request));

    channel.stream.listen((data) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          setState(() {
            serverSongs = decoded.map<Song>((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
            loading = false;
          });
        } else {
          setState(() => loading = false);
        }
      } catch (e) {
        print("Error decoding server songs: $e");
        setState(() => loading = false);
      }
    }, onError: (err) {
      print("WebSocket error: $err");
      setState(() => loading = false);
    });
  }

  // ---------------------------------------
  // helper برای سرچ و سورت روی allSongs
  List<Song> get _filteredSongs {
    if (searchQuery.isEmpty) return List.from(allSongs);
    return allSongs.where((s) => s.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  List<Song> get _sortedSongs {
    final list = List<Song>.from(_filteredSongs);
    switch (selectedSort) {
      case SortOption.likes:
        list.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case SortOption.addedDate:
      case SortOption.recent:
        list.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
      case SortOption.alphabet:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return list;
  }

  // ---------------------------------------
  // افزودن آهنگ به allSongs — از سرور
  Future<void> _addSongFromServer() async {
    final Song? picked = await showDialog<Song>(
      context: context,
      builder: (_) {
        final available = serverSongs.where((s) => !allSongs.any((as) => as.id == s.id)).toList();
        return SimpleDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Select song from server', style: TextStyle(color: Colors.cyanAccent)),
          children: available.isEmpty
              ? [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No new songs available on server', style: TextStyle(color: Colors.white70)),
            )
          ]
              : available
              .map((s) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, s),
            child: Text(s.title, style: TextStyle(color: Colors.white)),
          ))
              .toList(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        allSongs.add(picked);
      });
      await _saveAllSongs();
    }
  }

  // افزودن آهنگ به allSongs — از دیوایس (با file_picker)
  Future<void> _addSongFromDevice() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: false);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final newSong = Song(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: file.name,
          genre: '',
          addedDate: DateTime.now(),
          likes: 0,
          views: 0,
          url: file.path ?? '',
        );
        setState(() {
          allSongs.add(newSong);
        });
        await _saveAllSongs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No file selected')));
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file')));
    }
  }

  void _showAddSongOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.cloud_download, color: Colors.white),
            title: Text('Add from server', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _addSongFromServer();
            },
          ),
          ListTile(
            leading: Icon(Icons.file_upload, color: Colors.white),
            title: Text('Add from device', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _addSongFromDevice();
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------
  // Playlist management (top row)
  void _createNewPlaylist() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("New Playlist", style: TextStyle(color: Colors.cyanAccent)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter playlist name",
            hintStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.grey[800],
          ),
        ),
        actions: [
          TextButton(child: Text("Cancel", style: TextStyle(color: Colors.cyanAccent)), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: Text("Create", style: TextStyle(color: Colors.cyanAccent)),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  playlists.add(Playlist(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, songs: [], coverImageUrl: 'assets/images/playlist_default.jpg'));
                });
                _savePlaylists();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _deletePlaylist(Playlist p) {
    setState(() {
      playlists.removeWhere((pl) => pl.id == p.id);
    });
    _savePlaylists();
  }

  Widget _buildPlaylistCard(Playlist playlist) {
    return GestureDetector(
      onTap: () async {
        // باز کردن صفحه جزئیات پلی‌لیست (در این نسخه تغییرات پلی‌لیست مستقل از allSongs)
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlaylistDetailPage(playlist: playlist, allSongs: allSongs)),
        );
        // بعد از برگشت سعی کن ذخیره کنی (اگر PlaylistDetail داخل خود Playlist رو ویرایش کنه)
        await _savePlaylists();
        setState(() {}); // رفرش
      },
      child: Container(
        width: 140,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent),
          image: playlist.coverImageUrl.isNotEmpty
              ? DecorationImage(
            image: AssetImage(playlist.coverImageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
          )
              : null,
        ),
        child: Center(
          child: Text(
            playlist.name,
            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildAddPlaylistCard() {
    return GestureDetector(
      onTap: _createNewPlaylist,
      child: Container(
        width: 140,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent, width: 2),
        ),
        child: Center(child: Icon(Icons.add, size: 50, color: Colors.cyanAccent)),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<SortOption>(
      dropdownColor: Colors.grey[900],
      value: selectedSort,
      underline: SizedBox(),
      iconEnabledColor: Colors.cyanAccent,
      items: [
        DropdownMenuItem(value: SortOption.likes, child: Text('Likes', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: SortOption.addedDate, child: Text('Date Added', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: SortOption.recent, child: Text('Recent', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: SortOption.alphabet, child: Text('Alphabetical', style: TextStyle(color: Colors.white))),
      ],
      onChanged: (v) {
        if (v != null) setState(() => selectedSort = v);
      },
    );
  }

  // ---------------------------------------
  // حذف آهنگ از allSongs و ذخیره
  Future<void> _deleteSong(Song s) async {
    setState(() {
      allSongs.removeWhere((x) => x.id == s.id);
    });
    await _saveAllSongs();
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  // ---------------------------------------
  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(backgroundColor: Colors.cyanAccent, title: Text('Home', style: TextStyle(color: Colors.black))),
      body: loading
          ? Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PLAYLISTS HORIZONTAL
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: playlists.length + 1,
              itemBuilder: (_, idx) {
                if (idx == playlists.length) return _buildAddPlaylistCard();
                final p = playlists[idx];
                return Stack(
                  children: [
                    _buildPlaylistCard(p),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'delete') _deletePlaylist(p);
                        },
                        itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text('Delete Playlist'))],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // SEARCH + SORT + ADD SONG
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      prefixIcon: Icon(Icons.search, color: Colors.cyanAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                ),
                SizedBox(width: 12),
                _buildSortDropdown(),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAddSongOptions,
                  icon: Icon(Icons.add, color: Colors.black),
                  label: Text('Add Song', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                ),
              ],
            ),
          ),

          // SONGS LIST
          Expanded(
            child: _sortedSongs.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('No songs added yet.\nUse "Add Song" to add songs.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
              ),
            )
                : ListView.builder(
              itemCount: _sortedSongs.length,
              itemBuilder: (context, idx) {
                final song = _sortedSongs[idx];
                return ListTile(
                  leading: Icon(Icons.music_note, color: Colors.cyanAccent),
                  title: Text(song.title, style: TextStyle(color: Colors.white)),
                  subtitle: Text('Genre: ${song.genre} • Likes: ${song.likes} • Added: ${song.addedDate.toLocal().toString().split(' ')[0]}', style: TextStyle(color: Colors.grey[400])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.play_arrow, color: Colors.cyanAccent),
                        onPressed: () {
                          final playlist = _sortedSongs;
                          final index = playlist.indexOf(song);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SongPlayerPage(
                                playlist: playlist,
                                initialIndex: index,
                                username: '', // در صورت نیاز مقدار مناسب بذار
                              ),
                            ),
                          );
                        },
                      ),
                      PopupMenuButton<String>(
                        color: Colors.grey[900],
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await _deleteSong(song);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    // لمس لیست‌آیتم هم رفتن به پلیر
                    final playlist = _sortedSongs;
                    final index = playlist.indexOf(song);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SongPlayerPage(
                          playlist: playlist,
                          initialIndex: index,
                          username: '',
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