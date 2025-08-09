import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';

  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // تلاش برای اتصال به سرور
      Socket socket = await Socket.connect('192.168.1.9', 12344, timeout: Duration(seconds: 5));
      print('Connected to server');

      // آماده سازی درخواست به صورت JSON
      final request = jsonEncode({
        "action": "login",
        "payloadJson": jsonEncode({
          "username": username.trim(),
          "password": password.trim(),
        }),
      });

      // ارسال درخواست
      socket.write(request + '\n');  // \n برای جدا کردن پیام‌ها

      // گوش دادن به پاسخ سرور
      socket.listen((data) {
        final response = utf8.decode(data);
        print('Received response: $response');

        if (response.toLowerCase().contains('welcome')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login successful')),
          );
          // ناوبری به صفحه اصلی بعد از 500 میلی ثانیه
          Future.delayed(Duration(milliseconds: 500), () {
            Navigator.pushReplacementNamed(context, '/main');
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: $response')),
          );
        }
        socket.destroy();  // بستن اتصال
        setState(() {
          _isLoading = false;
        });
      },
          onError: (error) {
            print('Socket error: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Socket error: $error')),
            );
            socket.destroy();
            setState(() {
              _isLoading = false;
            });
          },
          onDone: () {
            print('Socket closed');
            setState(() {
              _isLoading = false;
            });
          });
    } catch (e) {
      print('Connection error: $e');
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
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/meow.png',
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
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [
                                  Colors.indigo,
                                  Colors.blueAccent,
                                  Colors.blue,
                                  Colors.cyan
                                ],
                              ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          keyboardType: TextInputType.text,
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
                            if (val == null || val.trim().isEmpty) {
                              return 'Enter your username';
                            }
                            return null;
                          },
                          onChanged: (val) => username = val,
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
                            "Login",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text("OR", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Not a member?", style: TextStyle(color: Colors.white)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: Text("Sign up now", style: TextStyle(color: Colors.cyanAccent)),
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
