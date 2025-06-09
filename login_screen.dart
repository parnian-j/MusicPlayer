import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  final LocalAuthentication auth = LocalAuthentication();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login successful')));

      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _loginWithBiometrics() async {
    try {
      bool isAvailable = await auth.canCheckBiometrics;
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric authentication not available')),
        );
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to log in',
        options: AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric authentication successful')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Authentication failed')));
      }
    } catch (e) {
      print("Biometric error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Biometric error occurred')));
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
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.indigo, Colors.blueAccent, Colors.blue, Colors.cyan],
                          ).createShader(bounds),
                          child: Text(
                            "Welcome Back!",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
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
                          validator: (val) =>
                          val == null || val.length < 8
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
                              horizontal: 40,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text("OR", style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loginWithBiometrics,
                          icon: Icon(Icons.fingerprint, color: Colors.black),
                          label: Text("Login with Fingerprint"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                  Text("Not a member?", style: TextStyle(color: Colors.white)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: Text(
                      "Sign up now",
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
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