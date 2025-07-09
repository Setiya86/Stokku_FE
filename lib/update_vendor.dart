import 'package:flutter/material.dart';
import 'authman.dart';
import 'profil_vebdor.dart';
import 'home.dart';
import 'main.dart';
import 'riwayat.dart';
import 'barang.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateVendorPage extends StatefulWidget {
  const UpdateVendorPage({super.key});

  @override
  _UpdateVendorPageState createState() => _UpdateVendorPageState();
}

class _UpdateVendorPageState extends State<UpdateVendorPage> {
  final _namaVendorController = TextEditingController();
  final _noTeleController = TextEditingController();
  final _namaBankController = TextEditingController();
  final _noRekController = TextEditingController();
  final _namaAkunBankController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _catatanController = TextEditingController();

  String? _username;
  String? _namavendor;
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
      _namavendor = await AuthManager.getVendor();

      if (_username != null && _namavendor != null) {
        await fetchVendorData();
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

  Future<void> fetchVendorData() async {
    if (_username == null || _namavendor == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.116.127:5002/api/get_update_vendor?username=$_username&namavendor=$_namavendor',
        ),
      );

      if (response.statusCode == 200) {
        final vendorData = json.decode(response.body);
        setState(() {
          _namaVendorController.text = vendorData['namavendor'] ?? '';
          _noTeleController.text = vendorData['notele']?.toString() ?? '';
          _namaBankController.text = vendorData['namabank'] ?? '';
          _noRekController.text = vendorData['norek']?.toString() ?? '';
          _namaAkunBankController.text = vendorData['namaakunbank'] ?? '';
          _kategoriController.text = vendorData['kategori'] ?? '';
          _catatanController.text = vendorData['catatan'] ?? '';
        });
      } else {
        throw Exception('Failed to load vendor data');
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

  Future<void> submitData() async {
    if (!_validateInputs()) return;

    try {
      final url = Uri.parse('http://192.168.116.127:5002/api/update_vendor?username=$_username&namavendor=$_namavendor');
      final response = await http.put(
        url,
        body: json.encode({
          'nama_vendor': _namaVendorController.text,
          'notele': _noTeleController.text,
          'namabank': _namaBankController.text,
          'norek': _noRekController.text,
          'namaakunbank': _namaAkunBankController.text,
          'kategori': _kategoriController.text,
          'catatan': _catatanController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil diperbarui!')),
        );
        await AuthManager.clearVendor();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VendorDetailPage()),
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
      appBar: AppBar(title: const Text('Perbarui Data Vendor')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                      onPressed: () {
                        submitData(); // Fungsi dipanggil di dalam VoidCallback
                        Navigator.push( context, MaterialPageRoute(builder: (context) => VendorDetailPage()),);
                      },
                      child: const Text('Perbarui Vendor'),
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
                await AuthManager.clearVendor();
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
