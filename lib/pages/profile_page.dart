import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
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

  // برای پیست‌کردن JSON پلی‌لیست
  final TextEditingController _playlistPasteCtrl = TextEditingController();
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    _loadProfile();
  }

  // لود اولیه‌ی پروفایل (در صورت داشتن ذخیره‌ی محلی؛ در غیر این صورت می‌تونی با سرور سینک کنی)
  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      email = prefs.getString('profile_email') ?? '';
      password = prefs.getString('profile_password') ?? '';
      final bytesB64 = prefs.getString('profile_image_b64');
      if (bytesB64 != null && bytesB64.isNotEmpty) {
        profileImageBytes = base64Decode(bytesB64);
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // ذخیره‌ی پروفایل فعلی (لوکال؛ در صورت نیاز جایگزین با HTTP/WebSocket)
  Future<void> _updateProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_email', email);
      await prefs.setString('profile_password', password);
      if (profileImageBytes != null) {
        await prefs.setString('profile_image_b64', base64Encode(profileImageBytes!));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() => profileImageBytes = bytes);
    }
  }

  // -----------------------------
  // Import Playlist from pasted JSON
  // -----------------------------

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty')),
      );
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
      // 1) Parse JSON (همون کد قبلی)
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

      final List<Song> songs = songsRaw.map<Song>((e) {
        final m = (e is Map) ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{};
        return Song.fromJson(m);
      }).toList();

      // 2) Save to SharedPreferences (بدون عکس کاور)
      final String baseId = (decoded['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString();
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('playlists');
      List<Playlist> current = [];
      if (stored != null) {
        final arr = jsonDecode(stored) as List;
        current = arr.map<Playlist>((e) => Playlist.fromJson(Map<String, dynamic>.from(e))).toList();
      }

      String uniqueId = baseId;
      if (current.any((p) => p.id == uniqueId)) {
        uniqueId = '${baseId}_${DateTime.now().millisecondsSinceEpoch}';
      }

      final playlist = Playlist(
        id: uniqueId,
        name: name,
        songs: songs,
        coverImageUrl: '', // عمداً خالی تا هیچ Asset لود نشه
      );

      current.add(playlist);
      await prefs.setString('playlists', jsonEncode(current.map((p) => p.toJson()).toList()));

      if (!mounted) return;

      // 3) کیبورد رو ببند، بعد از فریم فعلی ناوبری کن
      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist imported')),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
              (route) => false,
          arguments: {'username': widget.username},
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }


  // -----------------------------
  // UI
  // -----------------------------
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // تصویر پروفایل — بدون AssetImage پیش‌فرض، تا هرگز ارور نده
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey[800],
                backgroundImage:
                profileImageBytes != null ? MemoryImage(profileImageBytes!) : null,
                child: profileImageBytes == null
                    ? const Icon(Icons.person, size: 64, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // نمایش Username و Email (فقط نمایش)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Username'),
                subtitle: Text(widget.username),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(email.isNotEmpty ? email : '—'),
              ),
            ),
            const SizedBox(height: 20),

            // سوییچ تم
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: isDarkMode,
              onChanged: (val) {
                setState(() => isDarkMode = val);
                widget.onThemeChanged?.call(val);
              },
            ),
            const SizedBox(height: 12),

            // دکمه ذخیره پروفایل
            Form(
              key: _formKey,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  child: const Text('Save Changes'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // بخش Import Playlist از JSON
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Paste playlist JSON here...',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  color: Colors.cyanAccent,
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

            // حذف اکانت (رفتار قبلی)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
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
