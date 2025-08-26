import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final bool isDarkMode;
  final Function(bool)? onThemeChanged;

  const ProfilePage({
    Key? key,
    required this.username,
    required this.isDarkMode,
    this.onThemeChanged,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  late bool isDarkMode;
  Uint8List? profileImageBytes;

  final TextEditingController _playlistPasteCtrl = TextEditingController();
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('profile_email') ?? '';
    password = prefs.getString('profile_password') ?? '';
    final bytesB64 = prefs.getString('profile_image_b64');
    if (bytesB64 != null && bytesB64.isNotEmpty) {
      profileImageBytes = base64Decode(bytesB64);
    }
    setState(() {});
  }

  Future<String> _updateProfileOnServer({
    required String username,
    required String email,
    required String password,
  }) async {
    final socket = await Socket.connect("192.168.219.134", 12344,
        timeout: const Duration(seconds: 5));

    final payload = {'username': username, 'email': email, 'password': password};
    final request = {
      'action': 'update_profile',
      'payloadJson': jsonEncode(payload),
    };

    socket.writeln(jsonEncode(request));
    await socket.flush();

    final responseLine = await socket
        .transform(utf8.decoder as StreamTransformer<Uint8List, dynamic>)
        .transform(const LineSplitter())
        .first;

    await socket.close();
    return responseLine;
  }

  Future<void> _updateProfile() async {
    try {
      final resp = await _updateProfileOnServer(
        username: widget.username,
        email: email,
        password: password,
      );

      if (resp.contains('profile updated')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_email', email);
        await prefs.setString('profile_password', password);

        if (profileImageBytes != null) {
          await prefs.setString(
            'profile_image_b64',
            base64Encode(profileImageBytes!),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated on server')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $resp')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => profileImageBytes = bytes);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      return;
    }
    setState(() {
      _playlistPasteCtrl.text = text;
    });
  }

  Future<void> _importPastedPlaylist() async {
    if (_playlistPasteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste playlist JSON first')),
      );
      return;
    }

    setState(() => _importing = true);
    try {
      final raw = _playlistPasteCtrl.text.trim();
      dynamic decoded = jsonDecode(raw);
      if (decoded is Map && decoded['payloadJson'] != null) {
        final payload = decoded['payloadJson'];
        decoded = payload is String ? jsonDecode(payload) : payload;
      }
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid playlist format (expecting JSON object)');
      }

      final String name = (decoded['name'] ?? '').toString();
      final songsRaw = decoded['songs'];
      if (name.isEmpty || songsRaw is! List) {
        throw Exception('Playlist must contain "name" and "songs":[...]');
      }

      final List<Song> songs =
      songsRaw.map<Song>((e) {
        final m =
        (e is Map)
            ? Map<String, dynamic>.from(e as Map)
            : <String, dynamic>{};
        return Song.fromJson(m);
      }).toList();

      final String baseId =
      (decoded['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
          .toString();
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('playlists');
      List<Playlist> current = [];
      if (stored != null) {
        final arr = jsonDecode(stored) as List;
        current =
            arr
                .map<Playlist>(
                  (e) => Playlist.fromJson(Map<String, dynamic>.from(e)),
            )
                .toList();
      }

      String uniqueId = baseId;
      if (current.any((p) => p.id == uniqueId)) {
        uniqueId = '${baseId}_${DateTime.now().millisecondsSinceEpoch}';
      }

      final playlist = Playlist(
        id: uniqueId,
        name: name,
        songs: songs,
        coverImageUrl: '',
      );

      current.add(playlist);
      await prefs.setString(
        'playlists',
        jsonEncode(current.map((p) => p.toJson()).toList()),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Playlist imported')));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
              (route) => false,
          arguments: {'username': widget.username},
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              setState(() => isDarkMode = !isDarkMode);
              widget.onThemeChanged?.call(isDarkMode);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 80,
                backgroundColor:
                isDarkMode ? Colors.grey[800] : Colors.grey[300],
                backgroundImage:
                profileImageBytes != null
                    ? MemoryImage(profileImageBytes!)
                    : null,
                child:
                profileImageBytes == null
                    ? Icon(
                  Icons.person,
                  size: 64,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter email';
                      if (!val.contains('@')) return 'Enter valid email';
                      return null;
                    },
                    onChanged: (val) => email = val,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter password';
                      if (val.length < 4) return 'Password too short';
                      return null;
                    },
                    onChanged: (val) => password = val,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _updateProfile();
                        }
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Import playlist from JSON',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _playlistPasteCtrl,
              maxLines: 8,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Paste playlist JSON here...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black45,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  color: Colors.cyan,
                  onPressed: _pasteFromClipboard,
                  tooltip: 'Paste from clipboard',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _importing ? null : _importPastedPlaylist,
                icon: const Icon(Icons.playlist_add, color: Colors.black),
                label: Text(
                  _importing ? 'Importing...' : 'Import playlist',
                  style: const TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    final socket = await Socket.connect("192.168.219.134", 12344,
                        timeout: const Duration(seconds: 5));

                    final request = {
                      "action": "delete_account",
                      "payloadJson": widget.username,
                    };

                    socket.writeln(jsonEncode(request));
                    await socket.flush();

                    final responseLine = await socket
                        .cast<List<int>>()
                        .transform(utf8.decoder)
                        .transform(const LineSplitter())
                        .first;

                    await socket.close();

                    if (responseLine.trim() == "success") {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Delete failed: $responseLine")),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error deleting account: $e")),
                    );
                  }
                },


                child: const Text('Delete Account'),
              ),
            ),

          ],
        ),
      ),
    );
  }
}


