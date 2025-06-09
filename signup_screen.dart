import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = '', email = '', password = '';

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup successful')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/meow.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

              Card(
                color: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 8),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Colors.indigo, Colors.blueAccent, Colors.blue, Colors.cyan],
                              ).createShader(bounds),
                              child: Text(
                                "Sign up to start listening",
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(Icons.music_note, color: Colors.cyanAccent),
                          ],
                        ),
                        SizedBox(height: 20),

                        TextFormField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: TextStyle(color: Colors.cyanAccent),
                            prefixIcon: Icon(Icons.person, color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.indigo),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.purple),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Username is required'
                              : null,
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.purple),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (val) => val == null || !val.contains('@')
                              ? 'Enter a valid email'
                              : null,
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.purple),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (val) => val == null || val.length < 8
                              ? 'Password must be at least 8 characters'
                              : null,
                          onChanged: (val) => password = val,
                        ),
                        SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            shadowColor: Colors.blue[900],
                            elevation: 6,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            animationDuration:
                            Duration(milliseconds: 150),
                          ),
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
                  Text("Already have an account?",
                      style: TextStyle(color: Colors.white)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}