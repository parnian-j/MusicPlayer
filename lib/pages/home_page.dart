import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../pages/song_player_page.dart';
import 'playlist_detail_page.dart';

enum SortOption { likes, addedDate, recent, alphabet }

class HomePage extends StatefulWidget {
  final String username;
  final String socketUrl;

  const HomePage({Key? key, required this.username, required this.socketUrl})
      : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late WebSocketChannel channel;
  late Stream<dynamic> _wsStream;
  List<Song> allSongs = [];
  List<Song> serverSongs = [];
  List<Playlist> playlists = [];

  SortOption selectedSort = SortOption.likes;
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse(widget.socketUrl));
    _wsStream = channel.stream.asBroadcastStream();
    _loadAllSongs();
    unawaited(_loadPlaylists());
    unawaited(_refreshPlaylists());
  }

  Future<void> forceRefresh() async {
    setState(() => loading = true);
    await _refreshPlaylists();
    setState(() => loading = false);
  }

  @override
  void dispose() {
    if (channel != null) {
      channel.sink.close();
    }
    super.dispose();
  }

  Future<void> _loadAllSongs() async {
    if (channel != null) {
      channel.sink.close();
    }
    channel = WebSocketChannel.connect(Uri.parse(widget.socketUrl));
    _wsStream = channel.stream.asBroadcastStream();
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'allSongs_${widget.username}';
      final stored = prefs.getString(key);

      if (stored != null) {
        final decoded = json.decode(stored);
        setState(() {
          allSongs = List<Song>.from(decoded.map((x) => Song.fromJson(x)));
        });
      } else {
        _fetchServerSongs();
      }
    } catch (e) {
      print("Error loading songs: $e");
    }
  }

  Future<void> _saveAllSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'allSongs_${widget.username}';
      final encoded = jsonEncode(allSongs.map((s) => s.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (e) {
      print("Warning: Could not save allSongs locally: $e");
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'playlists_${widget.username}';

      String? stored = prefs.getString(key);
      stored ??= prefs.getString('playlists');

      if (stored != null) {
        final decoded = jsonDecode(stored) as List;
        print("Loaded playlists from prefs: $decoded");
        setState(() {
          playlists =
              decoded
                  .map<Playlist>(
                    (e) => Playlist.fromJson(e as Map<String, dynamic>),
              )
                  .toList();
        });
        if (prefs.containsKey('playlists') && !prefs.containsKey(key)) {
          await prefs.setString(key, stored);
          await prefs.remove('playlists');
        }
      }
    } catch (e) {
      print("Error loading playlists: $e");
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'playlists_${widget.username}';
      final encoded = jsonEncode(playlists.map((p) => p.toJson()).toList());
      await prefs.setString(key, encoded);
      print("Saved playlists to prefs: $encoded");
    } catch (e) {
      print("Error saving playlists: $e");
    }
  }

  void _fetchServerSongs() {
    final request = {"action": "get_explore_songs", "payloadJson": "{}"};
    channel.sink.add(jsonEncode(request));

    _wsStream.listen(
          (data) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is List) {
            final list =
            decoded
                .map<Song>((e) => Song.fromJson(e as Map<String, dynamic>))
                .toList();

            setState(() {
              serverSongs = list;
              loading = false;
            });
          } else {
            setState(() => loading = false);
          }
        } catch (e) {
          print("Error decoding server songs: $e");
          setState(() => loading = false);
        }
      },
      onError: (err) {
        print("WebSocket error: $err");
        setState(() => loading = false);
      },
    );
  }

  List<Song> get _filteredSongs {
    if (searchQuery.isEmpty) return List.from(allSongs);
    return allSongs
        .where((s) => s.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
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
        list.sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
    }
    return list;
  }

  Future<void> _addSongFromServer() async {
    final Song? picked = await showDialog<Song>(
      context: context,
      builder: (_) {
        final available =
        serverSongs
            .where((s) => !allSongs.any((as) => as.id == s.id))
            .toList();

        return SimpleDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Select song from server',
            style: TextStyle(color: Colors.cyanAccent),
          ),
          children:
          available.isEmpty
              ? [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No new songs available on server',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ]
              : available
              .map(
                (s) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, s),
              child: Text(
                s.title.isNotEmpty ? s.title : s.id,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
              .toList(),
        );
      },
    );

    if (picked != null) {
      try {
        setState(() {
          allSongs.add(picked);
        });
        await _saveAllSongs();

        final payload = {'username': widget.username, 'songId': picked.id};

        final request = {
          'action': 'add_song_to_profile',
          'payloadJson': jsonEncode(payload),
        };

        final socket = await Socket.connect('192.168.219.134', 12344);
        socket.write(jsonEncode(request) + '\n');

        String buffer = '';

        socket.listen(
              (data) async {
            buffer += utf8.decode(data);

            if (!buffer.trim().endsWith('}')) return;

            print("Response from server after adding song: $buffer");

            await _refreshPlaylists();

            socket.destroy();
          },
          onError: (error) {
            print("Socket error in _addSongFromServer: $error");
            socket.destroy();
          },
        );
      } catch (e) {
        print("Error adding song from server: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding song to profile')),
        );
      }
    }
  }

  Future<void> _ensureWs() async {
    try {
      channel.sink.add(jsonEncode({"ping": "ok"}));
    } catch (_) {
      channel = WebSocketChannel.connect(Uri.parse(widget.socketUrl));
      _wsStream = channel.stream.asBroadcastStream();
    }
  }

  Future<List<Song>> _fetchServerSongsOnce() async {
    await _ensureWs();

    final req = {"action": "get_explore_songs", "payloadJson": "{}"};
    channel.sink.add(jsonEncode(req));
    final raw = await _wsStream.firstWhere((data) {
      try {
        final d = jsonDecode(data);
        return d is List;
      } catch (_) {
        return false;
      }
    });

    final decoded = jsonDecode(raw) as List;
    final list =
    decoded
        .map<Song>((e) => Song.fromJson(e as Map<String, dynamic>))
        .toList();
    serverSongs = list;
    return list;
  }

  Future<void> _addSongsFromServerMulti() async {
    try {
      final fresh = await _fetchServerSongsOnce();
      final available =
      fresh.where((s) => !allSongs.any((as) => as.id == s.id)).toList();

      if (available.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new songs available on server')),
        );
        return;
      }
      final Set<String> selectedIds = {};
      final List<Song>? selected = await showDialog<List<Song>>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocalState) {
              return AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text(
                  'Select songs to add',
                  style: TextStyle(color: Colors.cyanAccent),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 360,
                  child: ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (_, i) {
                      final s = available[i];
                      final checked = selectedIds.contains(s.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) {
                          setLocalState(() {
                            if (v == true) {
                              selectedIds.add(s.id);
                            } else {
                              selectedIds.remove(s.id);
                            }
                          });
                        },
                        title: Text(
                          s.title.isNotEmpty ? s.title : s.id,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          s.genre,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        activeColor: Colors.cyanAccent,
                        checkColor: Colors.black,
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                  ),
                  TextButton(
                    onPressed:
                    selectedIds.isEmpty
                        ? null
                        : () {
                      final chosen =
                      available
                          .where((s) => selectedIds.contains(s.id))
                          .toList();
                      Navigator.pop(ctx, chosen);
                    },
                    child: const Text(
                      'Add Selected',
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selected == null || selected.isEmpty) return;
      setState(() {
        for (final s in selected) {
          if (!allSongs.any((as) => as.id == s.id)) {
            allSongs.add(s);
          }
        }
      });
      unawaited(_saveAllSongs());
      for (final s in selected) {
        final payload = {'username': widget.username, 'songId': s.id};
        final req = {
          'action': 'add_song_to_profile',
          'payloadJson': jsonEncode(payload),
        };
        await _ensureWs();
        channel.sink.add(jsonEncode(req));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selected.length} song(s) added to your profile'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding from server: $e')));
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final socket = await Socket.connect('192.168.219.134', 12344);

      final payload = {'username': widget.username};
      final request = {
        'action': 'get_profile',
        'payloadJson': jsonEncode(payload),
      };
      socket.write(jsonEncode(request) + '\n');

      String buffer = '';
      final completer = Completer<Map<String, dynamic>?>();

      socket.listen(
            (data) {
          buffer += utf8.decode(data);
          if (!buffer.trim().endsWith('}')) return;

          try {
            String jsonToDecode;
            if (buffer.contains("}{")) {
              jsonToDecode = buffer.split("}{")[0] + "}";
            } else {
              jsonToDecode = buffer.trim();
            }

            final Map<String, dynamic> responseData = jsonDecode(jsonToDecode);
            final playlistDataRaw =
                responseData['playlists'] as List<dynamic>? ?? [];
            final songDataRaw = responseData['songs'] as List<dynamic>? ?? [];

            final playlistData =
            playlistDataRaw
                .map(
                  (e) =>
              e is Map
                  ? Map<String, dynamic>.from(e)
                  : <String, dynamic>{},
            )
                .toList();

            final songData =
            songDataRaw
                .map(
                  (e) =>
              e is Map
                  ? Map<String, dynamic>.from(e)
                  : <String, dynamic>{},
            )
                .toList();

            final profile = {
              'playlists': playlistData,
              'songs': songData,
              'email': responseData['email'] ?? '',
              'theme': responseData['theme'] ?? 'light',
              'password': responseData['password'] ?? '',
            };

            completer.complete(profile);
          } catch (e) {
            print("Error decoding JSON in getProfile: $e");
            completer.complete(null);
          }

          socket.destroy();
        },
        onError: (error) {
          print("Socket error in getProfile: $error");
          socket.destroy();
          completer.complete(null);
        },
      );

      return completer.future;
    } catch (e) {
      print("Error connecting to server in getProfile: $e");
      return null;
    }
  }

  Future<void> _refreshPlaylists() async {
    final profile = await getProfile();
    if (profile == null) {
      print("Failed to load profile");
      return;
    }

    final fetched =
    (profile['playlists'] as List? ?? [])
        .map<Playlist>((e) => Playlist.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      if (fetched.isNotEmpty) {
        playlists = fetched;
      }
    });

    await _savePlaylists();
  }

  Future<void> _addSongFromDevice() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No file selected')));
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error picking file')));
    }
  }

  void _createNewPlaylist() async {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "New Playlist",
          style: TextStyle(color: Colors.cyanAccent),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter playlist name",
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.grey[800],
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.cyanAccent),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "Create",
              style: TextStyle(color: Colors.cyanAccent),
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newPlaylist = Playlist(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  songs: [],
                  coverImageUrl: 'assets/images/playlist_default.jpg',
                );

                setState(() {
                  playlists.add(newPlaylist);
                });

                await _savePlaylists();

                try {
                  final socket = await Socket.connect(
                    '192.168.219.134',
                    12344,
                  );

                  final payload = {
                    'username': widget.username.trim(),
                    'playlistName': name,
                  };

                  final request = {
                    'action': 'create_playlist',
                    'payloadJson': jsonEncode(payload),
                  };

                  socket.write(jsonEncode(request) + '\n');

                  socket.listen(
                        (data) async {
                      final response = utf8.decode(data).trim();

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(response)));
                      socket.destroy();
                    },
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Socket error: $error')),
                      );
                      socket.destroy();
                    },
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Connection error: $e')),
                  );
                }

                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _deletePlaylist(Playlist p) async {
    try {
      final socket = await Socket.connect('192.168.219.134', 12344);

      final payload = {'username': widget.username, 'playlistId': p.id};
      final request = {
        'action': 'delete_playlist',
        'payloadJson': jsonEncode(payload),
      };
      socket.write(jsonEncode(request) + '\n');

      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) async {
          try {
            final Map<String, dynamic> res = jsonDecode(line);
            if (res['status'] == 'success') {
              setState(() {
                playlists.removeWhere(
                      (pl) => pl.id.toString() == p.id.toString(),
                );
              });
              await _savePlaylists();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playlist deleted')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete failed on server')),
              );
            }
          } catch (e) {
            debugPrint('Decode error in _deletePlaylist: $e');
          } finally {
            socket.destroy();
          }
        },
        onError: (err) {
          debugPrint('Socket error in _deletePlaylist: $err');
          socket.destroy();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Connection error')));
        },
      );
    } catch (e) {
      debugPrint('Connection error in _deletePlaylist: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection error: $e')));
    }
  }

  Widget _buildPlaylistCard(Playlist playlist) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                PlaylistDetailPage(playlist: playlist, allSongs: allSongs),
          ),
        );
        await _savePlaylists();
        setState(() {});
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent),
          image:
          playlist.coverImageUrl.isNotEmpty
              ? DecorationImage(
            image: AssetImage(playlist.coverImageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          )
              : null,
        ),
        child: Center(
          child: Text(
            playlist.name,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 50, color: Colors.cyanAccent),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<SortOption>(
      dropdownColor: Colors.grey[900],
      value: selectedSort,
      underline: const SizedBox(),
      iconEnabledColor: Colors.cyanAccent,
      items: const [
        DropdownMenuItem(
          value: SortOption.likes,
          child: Text('Likes', style: TextStyle(color: Colors.white)),
        ),
        DropdownMenuItem(
          value: SortOption.addedDate,
          child: Text('Date Added', style: TextStyle(color: Colors.white)),
        ),
        DropdownMenuItem(
          value: SortOption.recent,
          child: Text('Recent', style: TextStyle(color: Colors.white)),
        ),
        DropdownMenuItem(
          value: SortOption.alphabet,
          child: Text('Alphabetical', style: TextStyle(color: Colors.white)),
        ),
      ],
      onChanged: (v) {
        if (v != null) setState(() => selectedSort = v);
      },
    );
  }

  Future<void> _deleteSong(Song s) async {
    setState(() {
      allSongs.removeWhere((x) => x.id == s.id);
    });
    await _saveAllSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.cyanAccent,
        title: const Text('Home', style: TextStyle(color: Colors.black)),
      ),
      body:
      loading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: playlists.length + 1,
              itemBuilder: (_, idx) {
                if (idx == playlists.length) {
                  return _buildAddPlaylistCard();
                }

                final p = playlists[idx];
                return Stack(
                  key: ValueKey(p.id.toString()),
                  children: [
                    _buildPlaylistCard(p),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
                        onSelected: (value) {
                          if (value == 'delete') _deletePlaylist(p);
                        },
                        itemBuilder:
                            (_) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Playlist'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.cyanAccent,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged:
                        (val) => setState(() => searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                _buildSortDropdown(),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAddSongOptions,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    'Add Song',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
            _sortedSongs.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No songs added yet.\nUse "Add Song" to add songs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
                : ListView.builder(
              itemCount: _sortedSongs.length,
              itemBuilder: (context, idx) {
                final song = _sortedSongs[idx];
                return ListTile(
                  leading: const Icon(
                    Icons.music_note,
                    color: Colors.cyanAccent,
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Genre: ${song.genre} • Likes: ${song.likes} • Added: ${song.addedDate.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.play_arrow,
                          color: Colors.cyanAccent,
                        ),
                        onPressed: () {
                          final playlist = _sortedSongs;
                          final index = playlist.indexOf(song);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => SongPlayerPage(
                                playlist: playlist,
                                initialIndex: index,
                                username: '',
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
                        itemBuilder:
                            (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    final playlist = _sortedSongs;
                    final index = playlist.indexOf(song);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SongPlayerPage(
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

  void _showAddSongOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder:
          (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_download, color: Colors.white),
            title: const Text(
              'Add from server',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _addSongsFromServerMulti();
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload, color: Colors.white),
            title: const Text(
              'Add from device',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _addSongFromDevice();
            },
          ),
        ],
      ),
    );
  }
}

