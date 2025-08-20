// lib/pages/home_page.dart

// ------------------------------
// Dart SDK
// ------------------------------
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ------------------------------
// Flutter & Packages
// ------------------------------
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http; // این خط را اضافه کنید

// ------------------------------
// Project Files (Models / Pages / Services)
// ------------------------------
import '../models/playlist.dart';
import '../models/song.dart';
import '../pages/song_player_page.dart';
import '../services/socket_services.dart';
import '../services/socket_services.dart' as tcp;
import 'main_page.dart';
import 'playlist_detail_page.dart';

// -----------------------------------------------------------------------------
// Enums
// -----------------------------------------------------------------------------
enum SortOption { likes, addedDate, recent, alphabet }

// -----------------------------------------------------------------------------
// Widget: HomePage
// -----------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  final String username;
  final String socketUrl;

  const HomePage({
    Key? key,
    required this.username,
    required this.socketUrl,
  }) : super(key: key);

  @override
  HomePageState createState() => HomePageState(); // ← این
}

// -----------------------------------------------------------------------------
// State: HomePageState
// -----------------------------------------------------------------------------
class HomePageState extends State<HomePage> {
  // ------------------------------
  // Sockets
  // ------------------------------
  late WebSocketChannel channel;

  // ------------------------------
  // Data
  // ------------------------------
  /// آهنگ‌هایی که کاربر در هوم اضافه می‌کند (مجزا از پلی‌لیست‌ها)
  List<Song> allSongs = [];

  /// آهنگ‌های موجود در سرور (برای انتخاب هنگام Add from server)
  List<Song> serverSongs = [];

  /// پلی‌لیست‌ها (بخش جدا، فعلاً کاری به add-song نداره)
  List<Playlist> playlists = [];

  // ------------------------------
  // UI State
  // ------------------------------
  SortOption selectedSort = SortOption.likes;
  bool loading = true;
  String searchQuery = '';

  // ------------------------------
  // Lifecycle
  // ------------------------------
  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse(widget.socketUrl));

    _fetchServerSongs();
    _loadAllSongs(); // برای لیست Explore/آهنگ‌ها

    // اگر می‌خوای منبع حقیقت فقط سرور باشه، این یکی رو حذف کن:
    // await _loadPlaylists();

    // ⬇️ دفعه اول ورود به Home، از بک‌اند پلی‌لیست‌ها رو بکش (نیازی نیست منتظرش بمونی)
    // برای استفاده از unawaited، مطمئن شو dart:async ایمپورت شده.
    unawaited(_refreshPlaylists());
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  // ------------------------------
  // Public API (callable from MainPage)
  // ------------------------------
  /// ⬇️ متد عمومی که از MainPage صداش می‌زنیم تا از بک‌اند رفرش کنه
  Future<void> forceRefresh() async {
    setState(() => loading = true);
    await _refreshPlaylists(); // همون متدی که از سرور پروفایل/پلی‌لیست‌ها رو می‌خونه
    setState(() => loading = false);
  }

  // -----------------------------------------------------------------------------
  // Persistence — allSongs
  // -----------------------------------------------------------------------------
  Future<void> _loadAllSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('allSongs');
      if (stored != null) {
        final decoded = jsonDecode(stored) as List;
        setState(() {
          allSongs = decoded
              .map<Song>((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      print("Error loading allSongs: $e");
    }
  }

  Future<void> _saveAllSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(allSongs.map((s) => s.toJson()).toList());
      await prefs.setString('allSongs', encoded);
    } catch (e) {
      print("Warning: Could not save allSongs locally: $e");
    }
  }

  // -----------------------------------------------------------------------------
  // Persistence — playlists
  // -----------------------------------------------------------------------------
  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('playlists');
      if (stored != null) {
        final decoded = jsonDecode(stored) as List;
        setState(() {
          playlists = decoded
              .map<Playlist>(
                (e) => Playlist.fromJson(e as Map<String, dynamic>),
          )
              .toList();
        });
      }
    } catch (e) {
      print("Error loading playlists: $e");
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(playlists.map((p) => p.toJson()).toList());
      await prefs.setString('playlists', encoded);
    } catch (e) {
      print("Error saving playlists: $e");
    }
  }

  // -----------------------------------------------------------------------------
  // WebSocket — گرفتن لیست سرور (Explore)
  // -----------------------------------------------------------------------------
  void _fetchServerSongs() {
    final request = {"action": "get_explore_songs", "payloadJson": "{}"};
    channel.sink.add(jsonEncode(request));

    channel.stream.listen(
          (data) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is List) {
            final list = decoded
                .map<Song>((e) => Song.fromJson(e as Map<String, dynamic>))
                .toList();

            setState(() {
              serverSongs = list;
              // مثل Explore، مستقیماً همون لیست رو نشون بده
              allSongs = list;
              loading = false;
            });

            // ذخیره‌ی لوکال، اختیاری و غیر بحرانی
            _saveAllSongs().catchError((_) {});
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

  // -----------------------------------------------------------------------------
  // Helpers — Search & Sort
  // -----------------------------------------------------------------------------
  List<Song> get _filteredSongs {
    if (searchQuery.isEmpty) return List.from(allSongs);
    return allSongs
        .where(
          (s) => s.title.toLowerCase().contains(searchQuery.toLowerCase()),
    )
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
              (a, b) =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
    }
    return list;
  }

  // -----------------------------------------------------------------------------
  // Add Song — From Server (single)
  // -----------------------------------------------------------------------------
  Future<void> _addSongFromServer() async {
    final Song? picked = await showDialog<Song>(
      context: context,
      builder: (_) {
        final available = serverSongs
            .where((s) => !allSongs.any((as) => as.id == s.id))
            .toList();

        return SimpleDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Select song from server',
            style: TextStyle(color: Colors.cyanAccent),
          ),
          children: available.isEmpty
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
        // اضافه کردن آهنگ به لیست محلی
        setState(() {
          allSongs.add(picked);
        });
        await _saveAllSongs();

        // --- ارسال اطلاعات به سرور با TCP ---
        final payload = {
          'username': widget.username,
          'songId': picked.id,
        };

        final request = {
          'action': 'add_song_to_profile',
          'payloadJson': jsonEncode(payload),
        };

        final socket = await Socket.connect('192.168.251.134', 12344);
        socket.write(jsonEncode(request) + '\n');

        String buffer = '';

        socket.listen(
              (data) async {
            buffer += utf8.decode(data);

            // فقط وقتی JSON کامل شد پردازش می‌کنیم
            if (!buffer.trim().endsWith('}')) return;

            print("Response from server after adding song: $buffer");

            // بعد از اضافه کردن آهنگ، پروفایل دوباره خوانده شود
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

  // -----------------------------------------------------------------------------
  // WebSocket Utilities
  // -----------------------------------------------------------------------------
  /// 1) کمک‌متد: اطمینان از باز بودن WS
  Future<void> _ensureWs() async {
    try {
      // ساده‌ترین تست: اگر send شکست خورد، ری‌کانکت کن
      channel.sink.add(jsonEncode({"ping": "ok"}));
    } catch (_) {
      channel = WebSocketChannel.connect(Uri.parse(widget.socketUrl));
    }
  }

  /// 2) کمک‌متد: یک‌بار دریافت لیست آهنگ‌ها از سرور (همون لحظه)
  Future<List<Song>> _fetchServerSongsOnce() async {
    await _ensureWs();

    final req = {"action": "get_explore_songs", "payloadJson": "{}"};
    channel.sink.add(jsonEncode(req));

    // اولین پیام معتبر که لیست باشد را برگردان
    final raw = await channel.stream.firstWhere((data) {
      try {
        final d = jsonDecode(data);
        return d is List;
      } catch (_) {
        return false;
      }
    });

    final decoded = jsonDecode(raw) as List;
    final list = decoded
        .map<Song>((e) => Song.fromJson(e as Map<String, dynamic>))
        .toList();

    // کش داخلی اختیاری
    serverSongs = list;
    return list;
  }

  /// 3) متد اصلی: هر بار «Add from server» → رفرش، نمایش، افزودن (چندتایی)
  Future<void> _addSongsFromServerMulti() async {
    try {
      // 1) تازه‌ترین لیست آهنگ‌های سرور
      final fresh = await _fetchServerSongsOnce();

      // فقط آهنگ‌هایی که از قبل تو allSongs نیستن
      final available =
      fresh.where((s) => !allSongs.any((as) => as.id == s.id)).toList();

      if (available.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new songs available on server')),
        );
        return;
      }

      // 2) دیالوگ چندانتخابی
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
                    onPressed: selectedIds.isEmpty
                        ? null
                        : () {
                      final chosen = available
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

      // 3) فوری به UI اضافه کن (فقط انتخاب‌ها)
      setState(() {
        for (final s in selected) {
          if (!allSongs.any((as) => as.id == s.id)) {
            allSongs.add(s);
          }
        }
      });
      unawaited(_saveAllSongs());

      // 4) اطلاع به سرور برای هر آهنگ انتخاب‌شده (WebSocket)
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
        SnackBar(content: Text('${selected.length} song(s) added to your profile')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding from server: $e')),
      );
    }
  }

  // -----------------------------------------------------------------------------
  // Profile / Playlists — Fetch & Refresh
  // -----------------------------------------------------------------------------
  /*Future<void> _refreshPlaylists() async {
    try {
      print("--------------------------------------------------------------------------------------------------------------------");
      final socket = await Socket.connect('192.168.251.134', 12344);

      final payload = {'username': widget.username};
      final request = {'action': 'get_profile', 'payloadJson': jsonEncode(payload)};
      socket.write(jsonEncode(request) + '\n');

      String buffer = ''; // جمع‌کننده chunk ها

      socket.listen((data) async {
        buffer += utf8.decode(data); // جمع chunkها

        // بررسی اینکه JSON کامل است
        if (!buffer.trim().endsWith('}')) return;

        try {
          // فقط اولین بلوک معتبر JSON را decode می‌کنیم
          String jsonToDecode;
          if (buffer.contains("}{")) {
            jsonToDecode = buffer.split("}{")[0] + "}";
          } else {
            jsonToDecode = buffer.trim();
          }

          final Map<String, dynamic> responseData = jsonDecode(jsonToDecode);

          // خواندن مستقیم پلی‌لیست و آهنگ‌ها
          final playlistDataRaw = responseData['playlists'] as List<dynamic>? ?? [];
          final songDataRaw = responseData['songs'] as List<dynamic>? ?? [];

          final playlistData = playlistDataRaw
              .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList();

          final songData = songDataRaw
              .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList();

          setState(() {
            playlists = playlistData.map((e) => Playlist.fromJson(e)).toList();
            allSongs = songData.map((e) => Song.fromJson(e)).toList();
          });

          await _savePlaylists();
          await _saveAllSongs();

          print("Playlists and songs successfully loaded.");
        } catch (e) {
          print("Error decoding JSON: $e");
        }

        socket.destroy();
      }, onError: (error) {
        print("Socket error: $error");
        socket.destroy();
      });
    } catch (e) {
      print("Error refreshing playlists: $e");
    }
  }*/

  // متد جدید برای گرفتن پروفایل از سرور
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final socket = await Socket.connect('192.168.251.134', 12344);

      final payload = {'username': widget.username};
      final request = {'action': 'get_profile', 'payloadJson': jsonEncode(payload)};
      socket.write(jsonEncode(request) + '\n');

      String buffer = '';
      final completer = Completer<Map<String, dynamic>?>();

      socket.listen(
            (data) {
          buffer += utf8.decode(data);

          // اگر JSON کامل نیست، صبر کن
          if (!buffer.trim().endsWith('}')) return;

          try {
            // جدا کردن اولین بلوک JSON معتبر
            String jsonToDecode;
            if (buffer.contains("}{")) {
              jsonToDecode = buffer.split("}{")[0] + "}";
            } else {
              jsonToDecode = buffer.trim();
            }

            final Map<String, dynamic> responseData = jsonDecode(jsonToDecode);

            // خواندن پلی‌لیست‌ها و آهنگ‌ها از ریشه JSON
            final playlistDataRaw = responseData['playlists'] as List<dynamic>? ?? [];
            final songDataRaw = responseData['songs'] as List<dynamic>? ?? [];

            final playlistData = playlistDataRaw
                .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
                .toList();

            final songData = songDataRaw
                .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
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

  // نسخه جدید _refreshPlaylists که از getProfile استفاده می‌کند
  Future<void> _refreshPlaylists() async {
    final profile = await getProfile();
    if (profile == null) {
      print("Failed to load profile");
      return;
    }

    setState(() {
      playlists = profile['playlists']
          .map<Playlist>((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList();

      allSongs = profile['songs']
          .map<Song>((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    await _savePlaylists();
    await _saveAllSongs();

    print("Playlists and songs successfully refreshed from profile.");
  }

  // -----------------------------------------------------------------------------
  // Add Song — From Device
  // -----------------------------------------------------------------------------
  /// افزودن آهنگ به allSongs — از دیوایس (با file_picker)
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking file')),
      );
    }
  }

  // -----------------------------------------------------------------------------
  // Playlists — Create / Delete / Card UI
  // -----------------------------------------------------------------------------
  /// ارسال پلی‌لیست جدید به سرور
  void _createNewPlaylist() async {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            child: const Text("Cancel", style: TextStyle(color: Colors.cyanAccent)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Create", style: TextStyle(color: Colors.cyanAccent)),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                // 1. ساخت پلی‌لیست در UI
                final newPlaylist = Playlist(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  songs: [],
                  coverImageUrl: 'assets/images/playlist_default.jpg',
                );

                setState(() {
                  playlists.add(newPlaylist);
                });

                // ذخیره پلی‌لیست‌ها در دستگاه
                await _savePlaylists();

                // 2. ارسال پلی‌لیست به سرور
                try {
                  final socket = await Socket.connect('192.168.251.134', 12344);

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

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response)),
                      );

                      /*if (response.toLowerCase().contains("success")) {
                        // --------- انتقال به صفحه پلی‌لیست ----------
                        Future.delayed(Duration(milliseconds: 500), () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainPage(
                                username: widget.username,
                                isDarkMode: true,
                              ),
                            ),
                          );
                        });
                      }*/

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
      // ارسال درخواست به سرور برای حذف پلی‌لیست
      final socket = await Socket.connect('192.168.251.134', 12344);

      final payload = {
        'username': widget.username,
        'playlistId': p.id,
      };

      final request = {
        'action': 'delete_playlist',
        'payloadJson': jsonEncode(payload),
      };

      socket.write(jsonEncode(request) + '\n');

      socket.listen(
            (data) async {
          final response = utf8.decode(data).trim();
          print("Response from server: $response");

          try {
            final Map<String, dynamic> responseData = jsonDecode(response);
            if (responseData['status'] == 'success') {
              setState(() {
                playlists.removeWhere((pl) => pl.id == p.id);
              });
              await _savePlaylists();
            } else {
              print("Error deleting playlist from server");
            }
          } catch (e) {
            print("Error decoding response: $e");
          }

          socket.destroy();
        },
        onError: (error) {
          print("Socket error: $error");
          socket.destroy();
        },
      );
    } catch (e) {
      print("Error deleting playlist: $e");
    }
  }

  Widget _buildPlaylistCard(Playlist playlist) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailPage(
              playlist: playlist,
              allSongs: allSongs,
            ),
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
          image: playlist.coverImageUrl.isNotEmpty
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

  // -----------------------------------------------------------------------------
  // Songs — Delete (local)
  // -----------------------------------------------------------------------------
  Future<void> _deleteSong(Song s) async {
    setState(() {
      allSongs.removeWhere((x) => x.id == s.id);
    });
    await _saveAllSongs();
  }

  // -----------------------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.cyanAccent,
        title: const Text('Home', style: TextStyle(color: Colors.black)),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------
          // PLAYLISTS HORIZONTAL
          // ------------------------------
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
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'delete') _deletePlaylist(p);
                        },
                        itemBuilder: (_) => const [
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

          // ------------------------------
          // SEARCH + SORT + ADD SONG
          // ------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                _buildSortDropdown(),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAddSongOptions,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text('Add Song', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------
          // SONGS LIST
          // ------------------------------
          Expanded(
            child: _sortedSongs.isEmpty
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
                  leading: const Icon(Icons.music_note, color: Colors.cyanAccent),
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
                        icon: const Icon(Icons.play_arrow, color: Colors.cyanAccent),
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
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.redAccent),
                            ),
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

  // -----------------------------------------------------------------------------
  // Bottom Sheet — Add song options
  // -----------------------------------------------------------------------------
  void _showAddSongOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_download, color: Colors.white),
            title: const Text('Add from server', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _addSongsFromServerMulti(); // ⬅️ اینجا
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload, color: Colors.white),
            title: const Text('Add from device', style: TextStyle(color: Colors.white)),
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
