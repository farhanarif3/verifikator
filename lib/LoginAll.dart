import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ta/screen_user/home_user.dart';
import 'package:ta/screen_verif/home_verif.dart';
import 'package:ta/screen_admin/home_admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(LoginApp());
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("Email: ${_emailController.text}");
      print("Password: ${_passwordController.text}");

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String userRole = userDoc['role'];
          
          switch (userRole) {
            case 'Admin':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeAdmin()),
              );
              break;
            case 'Verifikator':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VerifPage()),
              );
              break;
            case 'User':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeUser()),
              );
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unknown user role')),
              );
              break;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User data not found')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed')),
        );
      }
    } catch (e) {
      print("Login error: $e");
      if (e is FirebaseAuthException) {
        String errorMessage;
        if (e.code == 'wrong-password') {
          errorMessage = 'Password yang Anda masukkan salah';
        } else if (e.code == 'user-not-found') {
          errorMessage = 'Email belum terdaftar';
        } else {
          errorMessage = 'Email atau password yang Anda masukkan salah';
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(errorMessage),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _resetPassword() async {
    final TextEditingController resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reset Password'),
          content: TextField(
            controller: resetEmailController,
            decoration: InputDecoration(
              labelText: 'Enter your registered email',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Send'),
              onPressed: () async {
                try {
                  await _auth.sendPasswordResetEmail(
                      email: resetEmailController.text);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset link sent!')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: _isObscure,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _login,
                  child: Text('Login'),
                ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: _resetPassword,
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
