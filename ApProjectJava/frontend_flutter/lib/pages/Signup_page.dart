import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'main_page.dart';

class SignupPage extends StatefulWidget {
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String email = '';
  String password = '';
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final socket = await Socket.connect('172.20.194.126', 12344);

      final payload = {
        'username': username.trim(),
        'password': password.trim(),
        'email': email.trim(),
      };

      final request = {
        'action': 'signup',
        'payloadJson': jsonEncode(payload),
      };

      socket.write(jsonEncode(request) + '\n');

      socket.listen((data) {
        final response = utf8.decode(data).trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response)),
        );

        if (response.toLowerCase().contains("success")) {
          // --------- انتقال به MainPage همراه با اطلاعات کاربر ----------
          Future.delayed(Duration(milliseconds: 500), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(
                  username: username.trim(),
                  isDarkMode: true,
                ),
              ),
            );
          });
        }

        socket.destroy();
        setState(() {
          _isLoading = false;
        });
      }, onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Socket error: $error')),
        );
        socket.destroy();
        setState(() {
          _isLoading = false;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/meow.PNG',
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 24),
              Card(
                color: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          "Sign up to start listening",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [
                                  Colors.indigo,
                                  Colors.blueAccent,
                                  Colors.blue,
                                  Colors.cyan
                                ],
                              ).createShader(Rect.fromLTWH(0, 0, 200, 50)),
                          ),
                        ),
                        SizedBox(height: 8),
                        Icon(Icons.music_note, color: Colors.cyanAccent, size: 40),
                        SizedBox(height: 20),
                        TextFormField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: TextStyle(color: Colors.cyanAccent),
                            prefixIcon: Icon(Icons.person, color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.indigo),
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.purple),
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Username is required';
                            }
                            return null;
                          },
                          onChanged: (val) => username = val,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.cyanAccent),
                            prefixIcon: Icon(Icons.email, color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.indigo),
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.purple),
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (val) {
                            if (val == null || !val.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                          onChanged: (val) => email = val,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          obscureText: true,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.cyanAccent),
                            prefixIcon: Icon(Icons.lock, color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.indigo),
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.purple),
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(val)) {
                              return 'Use upper, lower case and digits';
                            }
                            if (val.contains(username)) {
                              return 'Password must not contain your username';
                            }
                            return null;
                          },
                          onChanged: (val) => password = val,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already a member?", style: TextStyle(color: Colors.white)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text("Login now", style: TextStyle(color: Colors.cyanAccent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
