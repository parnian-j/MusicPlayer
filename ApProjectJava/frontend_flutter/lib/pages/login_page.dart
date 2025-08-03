import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful')),
      );
      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pushReplacementNamed(context, '/main');
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
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
                                ).createShader(
                                  Rect.fromLTWH(0, 0, 200, 70),
                                )),
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
                                borderSide:
                                BorderSide(color: Colors.indigo),
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                BorderSide(color: Colors.purple),
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
                                borderSide:
                                BorderSide(color: Colors.indigo),
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                BorderSide(color: Colors.purple),
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
                                .hasMatch(val)) {
                              return 'Use upper, lower case and digits';
                            }
                            if (val.contains(email.split('@')[0])) {
                              return 'Password must not contain your email';
                            }
                            return null;
                          },
                          onChanged: (val) => password = val,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            "Login",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
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