import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int selectedIndex = 2;
  String username = "nova_user";
  String email = "user@example.com";

  void _editProfile() {
    String newUsername = username;
    String newEmail = email;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Edit Profile', style: TextStyle(color: Colors.cyanAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.cyanAccent),
                ),
                controller: TextEditingController(text: username),
                onChanged: (value) => newUsername = value,
              ),
              TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.cyanAccent),
                ),
                controller: TextEditingController(text: email),
                onChanged: (value) => newEmail = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  username = newUsername;
                  email = newEmail;
                });
                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.indigo, Colors.blueAccent, Colors.cyan],
          ).createShader(bounds),
          child: Text('Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.cyanAccent),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/images/meow.png"),
            ),
            SizedBox(height: 20),
            Text(username, style: TextStyle(color: Colors.cyanAccent, fontSize: 20)),
            SizedBox(height: 8),
            Text(email, style: TextStyle(color: Colors.white70)),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: Text('Logout'),
            )
          ],
        ),
      ),
    );
  }
}