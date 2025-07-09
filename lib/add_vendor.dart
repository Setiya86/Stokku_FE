import 'package:flutter/material.dart';
import 'dart:convert';
import 'home.dart';
import 'authman.dart';
import 'main.dart';
import 'riwayat.dart';
import 'VendorPage.dart';
import 'barang.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InputDataVendorPage extends StatefulWidget {
  const InputDataVendorPage({super.key});

  @override
  _InputDataVendorPageState createState() => _InputDataVendorPageState();
}
class _InputDataVendorPageState extends State<InputDataVendorPage> {
  final _namaVendorController = TextEditingController();
  final _noTeleController = TextEditingController();
  final _namaBankController = TextEditingController();
  final _noRekController = TextEditingController();
  final _namaAkunBankController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _catatanController = TextEditingController();

  String? _username;
  String? _selectedRegion;
  int _currentIndex = 0;
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
        _noTeleController.text = _regionCodes[_selectedRegion] ?? '';
      }
    });
  }

  bool _validateInputs() {
    if (_namaVendorController.text.isEmpty ||
        _noTeleController.text.isEmpty ||
        _namaBankController.text.isEmpty ||
        _noRekController.text.isEmpty ||
        _namaAkunBankController.text.isEmpty ||
        _kategoriController.text.isEmpty ||
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

  Future<void> submitData(BuildContext context) async {
    if (!_validateInputs()) return;

    try {
      final url = Uri.parse('http://192.168.116.127:5002/api/add_vendor');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'namavendor': _namaVendorController.text,
          'notele': _noTeleController.text,
          'namabank': _namaBankController.text,
          'norek': _noRekController.text,
          'namaakunbank': _namaAkunBankController.text,
          'kategori': _kategoriController.text,
          'catatan': _catatanController.text,
          'username': _username,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil ditambahkan!')),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => DaftarVendor()),);
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan data: ${responseData['message']}')),
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
      appBar: AppBar(title: const Text('Input Data Vendor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _namaVendorController,
                decoration: const InputDecoration(labelText: 'Nama Vendor'),
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
                      onChanged: (value) {
                        if (_selectedRegion != null &&
                            !value.startsWith(_regionCodes[_selectedRegion]!)) {
                          _noTeleController.text = _regionCodes[_selectedRegion]!;
                          _noTeleController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _noTeleController.text.length),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _namaBankController,
                decoration: const InputDecoration(labelText: 'Nama Bank'),
              ),
              TextField(
                controller: _noRekController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'No Rekening'),
              ),
              TextField(
                controller: _namaAkunBankController,
                decoration: const InputDecoration(labelText: 'Nama Akun Bank'),
              ),
              TextField(
                controller: _kategoriController,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              TextField(
                controller: _catatanController,
                decoration: const InputDecoration(labelText: 'Catatan'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => submitData(context),
                child: const Text('Tambah Vendor'),
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
            label: 'Vendor',
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
