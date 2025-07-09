import 'package:flutter/material.dart';
import 'authman.dart';
import 'home.dart';
import 'riwayat.dart';
import 'main.dart';
import 'profil_pembeli.dart';
import 'barang.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdatePembeliPage extends StatefulWidget {
  const UpdatePembeliPage({super.key});

  @override
  _UpdatePembeliPageState createState() => _UpdatePembeliPageState();
}

class _UpdatePembeliPageState extends State<UpdatePembeliPage> {
  final _namaPembeliController = TextEditingController();
  final _noTeleController = TextEditingController();
  final _alamatController = TextEditingController();
  final _catatanController = TextEditingController();

  String? _username;
  String? _namapembeli;
  String? _selectedRegion;
  int _currentIndex = 0;

  final Map<String, String> _regionCodes = {
    'ID (+62)': '+62',
    'US (+1)': '+1',
    'UK (+44)': '+44',
    'IN (+91)': '+91',
    'AU (+61)': '+61',
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _username = await AuthManager.getUser();
      _namapembeli = await AuthManager.getPembeli();

      if (_username != null && _namapembeli != null) {
        await fetchPembeliData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username atau Nama Vendor kosong')),
        );
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchPembeliData() async {
    if (_username == null || _namapembeli == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.116.127:5002/api/get_update_pembeli?username=$_username&namapembeli=$_namapembeli',
        ),
      );

      if (response.statusCode == 200) {
        final pembeliData = json.decode(response.body);
        setState(() {
          _namaPembeliController.text = pembeliData['namapembeli'] ?? '';
          _noTeleController.text = pembeliData['notele']?? '';
          _alamatController.text = pembeliData['alamat'] ?? '';
          _catatanController.text = pembeliData['catatan'] ?? '';
        });
      } else {
        throw Exception('Failed to load pembeli data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
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
      final url = Uri.parse('http://192.168.116.127:5002/api/update_pembeli?username=$_username&namapembeli=$_namapembeli');
      final response = await http.put(
        url,
        body: json.encode({
          'nama_pembeli': _namaPembeliController.text,
          'notele': _noTeleController.text,
          'alamat': _alamatController.text,
          'catatan': _catatanController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil diperbarui!')),
        );
        await AuthManager.clearPembeli();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PembeliDetailPage()),
        );
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui data: ${responseData['message']}')),
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
      appBar: AppBar(title: const Text('Perbarui Data Pembeli')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _namaPembeliController,
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
                        submitData();
                        Navigator.push( context, MaterialPageRoute(builder: (context) => PembeliDetailPage()),); // Fungsi dipanggil di dalam VoidCallback
                      },
                      child: const Text('Perbarui pembeli'),
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
                await AuthManager.clearPembeli();
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
                  label: 'Users',
                ),
              ],
            ),
    );
  }
}
