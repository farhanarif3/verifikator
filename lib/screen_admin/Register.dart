import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'manage_bidang_page.dart'; // Ganti dengan path yang benar
import 'account_management_page.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool showProgress = false;
  final _formkey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpassController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool _isObscure = true;
  bool _isObscure2 = true;

  var options = ['User', 'Verifikator', 'Admin'];
  var _currentItemSelected = "User";
  var role = "User";

  List<String> bidangOptions = [];
  var _currentBidangSelected;
  var bidang;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBidangOptions();
  }

  Future<void> _fetchBidangOptions() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('bidang').get();
      var bidangList = snapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        bidangOptions = bidangList;
        if (bidangOptions.isNotEmpty) {
          _currentBidangSelected = bidangOptions[0];
          bidang = bidangOptions[0];
        }
        isLoading = false;
      });
    } catch (e) {
      print(e.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        automaticallyImplyLeading: false, // Menyembunyikan tombol back
        actions: [
          IconButton(
            icon: Icon(Icons.manage_accounts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountManagementPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            margin: EdgeInsets.fromLTRB(16, 60, 16, 16),
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  _buildTextFormField(
                    controller: usernameController,
                    hintText: 'Username',
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Username cannot be empty";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  _buildTextFormField(
                    controller: emailController,
                    hintText: 'Email',
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Email cannot be empty";
                      }
                      if (!RegExp("^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]").hasMatch(value)) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 10),
                  _buildPasswordFormField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: _isObscure,
                    onVisibilityPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                    validator: (value) {
                      RegExp regex = RegExp(r'^(?=.*[A-Z])(?=.*[@$!%?&])[A-Za-z\d@$!%?&]{8,}$');
                      if (value!.isEmpty) {
                        return "Password cannot be empty";
                      }
                      if (!regex.hasMatch(value)) {
                        return "Password must be at least 8 characters, include an uppercase letter and a special character";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  _buildPasswordFormField(
                    controller: confirmpassController,
                    hintText: 'Confirm Password',
                    obscureText: _isObscure2,
                    onVisibilityPressed: () {
                      setState(() {
                        _isObscure2 = !_isObscure2;
                      });
                    },
                    validator: (value) {
                      if (confirmpassController.text != passwordController.text) {
                        return "Password did not match";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  _buildTextFormField(
                    controller: phoneController,
                    hintText: 'Phone',
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Phone number cannot be empty";
                      }
                      if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                        return "Please enter a valid phone number";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 10),
                  isLoading
                      ? CircularProgressIndicator()
                      : _buildDropdownRow(
                          title: "Bidang",
                          items: bidangOptions,
                          currentItemSelected: _currentBidangSelected,
                          onChanged: (newValueSelected) {
                            setState(() {
                              _currentBidangSelected = newValueSelected!;
                              bidang = newValueSelected;
                            });
                          },
                        ),
                  SizedBox(height: 10),
                  _buildDropdownRow(
                    title: "Role",
                    items: options,
                    currentItemSelected: _currentItemSelected,
                    onChanged: (newValueSelected) {
                      setState(() {
                        _currentItemSelected = newValueSelected!;
                        role = newValueSelected;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ManageBidangPage()),
                      );
                    },
                    child: Text("Kelola Bidang"),
                    
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formkey.currentState!.validate()) {
                        setState(() {
                          showProgress = true;
                        });

                        _auth.createUserWithEmailAndPassword(
                          email: emailController.text,
                          password: passwordController.text,
                        ).then((userCredential) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userCredential.user!.uid)
                              .set({
                            'username': usernameController.text,
                            'email': emailController.text,
                            'phone': phoneController.text,
                            'role': role,
                            'bidang': bidang,
                          }).then((_) {
                            setState(() {
                              showProgress = false;
                            });
                            _showSuccessDialog();
                          });
                        }).catchError((e) {
                          print(e.toString());
                          setState(() {
                            showProgress = false;
                          });
                        });
                      }
                    },
                    child: Text('Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onVisibilityPressed,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: onVisibilityPressed,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownRow({
    required String title,
    required List<String> items,
    required String? currentItemSelected,
    required void Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: currentItemSelected,
            decoration: InputDecoration(
              labelText: title,
              border: OutlineInputBorder(),
            ),
            items: items.map((String dropDownStringItem) {
              return DropdownMenuItem<String>(
                value: dropDownStringItem,
                child: Text(dropDownStringItem),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: Text('Registrasi Berhasil'),
      content: Text('Anda telah berhasil mendaftar!'),
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