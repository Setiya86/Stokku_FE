import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

class RegisterForm extends StatelessWidget {
  const RegisterForm({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RegisterFormScreen(),
    );
  }
}

class RegisterFormScreen extends StatefulWidget {
  const RegisterFormScreen({super.key});

  @override
  _RegisterFormScreenState createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends State<RegisterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isLoading = false;

  Future<void> _submitRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String apiUrl = 'http://192.168.116.127:5002/api/signup';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _storeNameController.text,
          'username': _emailController.text,
          'password': _confirmPasswordController.text,
          'notele' : 'yy',
          'alamat' : ' yy'
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
        if (response.statusCode == 200) {
          _storeNameController.clear();
          _emailController.clear();
          _passwordController.clear();
          Navigator.push(context, MaterialPageRoute(builder: (context) => LoginForm()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal tersambung ke server')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menambahkan gambar di atas kolom inputan
            Image.asset(
              "assets/images/INTIMART.png", // Path gambar
              height: 200, // Menentukan tinggi gambar
            ),
            SizedBox(height: 20),
            
            // Formulir Register
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Input Nama Toko
              TextFormField(
                controller: _storeNameController,
                decoration: InputDecoration(
                  labelText: "Nama Toko",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Nama toko tidak boleh kosong";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Input Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Email tidak boleh kosong";
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Masukkan email yang valid";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Input Password
              TextFormField(
                controller: _passwordController,
                obscureText: _isPasswordHidden,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Password tidak boleh kosong";
                  } else if (value.length < 8) {
                    return "Password harus minimal 8 karakter";
                  } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(value)) {
                    return "Password harus mengandung huruf dan angka";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Input Konfirmasi Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _isPasswordHidden,
                decoration: InputDecoration(
                  labelText: "Konfirmasi Password",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Konfirmasi password tidak boleh kosong";
                  } else if (value != _passwordController.text) {
                    return "Password tidak cocok";
                  }
                  return null;
                },
              ),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submitRegister,
                          child: Text('Register'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
