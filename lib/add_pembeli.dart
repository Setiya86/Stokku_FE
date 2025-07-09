import 'package:flutter/material.dart';
import 'dart:convert';
import 'home.dart';
import 'riwayat.dart';
import 'authman.dart';
import 'main.dart';
import 'barang.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class InputDataPembeliPage extends StatefulWidget {
  const InputDataPembeliPage({super.key});

  @override
  _InputDataPembeliPageState createState() => _InputDataPembeliPageState();
}

class _InputDataPembeliPageState extends State<InputDataPembeliPage> {
  final _namaPembeliController = TextEditingController();
  final _noTeleController = TextEditingController();
  final _alamatController = TextEditingController();
  final _catatanController = TextEditingController();

  String? _username;
  String? _selectedRegion;
  int _currentIndex = 0 ;

  final Map<String, String> _regionCodes = {
    'ID (+62)': '+62',
    'US (+1)': '+1',
    'UK (+44)': '+44',
    'IN (+91)': '+91',
    'AU (+61)': '+61',
  };


  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }


  void _onRegionChanged(String? region) {
    setState(() {
      _selectedRegion = region;
      if (_selectedRegion != null) {
        final prefix = _regionCodes[_selectedRegion]!;
        if (!_noTeleController.text.startsWith(prefix)) {
          _noTeleController.text = prefix;
        }
      }
    });
  }

  bool _validateInputs() {
    if (_namaPembeliController.text.isEmpty ||
        _noTeleController.text.isEmpty ||
        _alamatController.text.isEmpty ||
        _catatanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom harus diisi!')),
      );
      return false;
    }

    if (!RegExp(r'^\+\d{1,3}\d{7,13}$').hasMatch(_noTeleController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon tidak valid!')),
      );
      return false;
    }

    return true;
  }

  Future<void> submitData() async {
    if (!_validateInputs()) return;

    try {
      final url = Uri.parse('http://192.168.116.127:5002/api/add_pembeli?username=$_username');
      final response = await http.post(
        url,
        body: json.encode({
          'namapembeli': _namaPembeliController.text,
          'notele': _noTeleController.text,
          'alamat': _alamatController.text,
          'catatan': _catatanController.text,
          'username': _username
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil ditambahkan!')),
        );
        Navigator.pop(context);
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah data: ${responseData['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Data Pembeli')),
      body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _namaPembeliController,
                      decoration: const InputDecoration(labelText: 'Nama Pembeli'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _selectedRegion,
                            items: _regionCodes.keys
                                .map((region) => DropdownMenuItem(
                                      value: region,
                                      child: Text(region),
                                    ))
                                .toList(),
                            onChanged: _onRegionChanged,
                            decoration: const InputDecoration(labelText: 'Region'),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _noTeleController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'No Telepon'),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _alamatController,
                      decoration: const InputDecoration(labelText: 'alamat'),
                    ),
                    TextField(
                      controller: _catatanController,
                      decoration: const InputDecoration(labelText: 'Catatan'),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        submitData(); // Fungsi dipanggil di dalam VoidCallback
                      },
                      child: const Text('Tambah Pembeli'),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) async {
                setState(() {
                  _currentIndex = index;
                });
                switch (index) {
                  case 0:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                    break;
                  case 1:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DaftarProduk()),
                    );
                    break;
                  case 2:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DaftarRiwayat()),
                    );
                    break;
                  case 3:
                    await AuthManager.clearUser();
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyApp()),
                      );
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home, color: Colors.black),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory, color: Colors.black),
                  label: 'Barang',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history, color: Colors.black),
                  label: 'Riwayat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout, color: Colors.black),
                  label: 'Lainnya',
                ),
              ],
            ),
    );
  }
}
