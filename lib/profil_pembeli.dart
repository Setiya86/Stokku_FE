import 'package:flutter/material.dart';
import 'dart:convert';
import 'update_pembeli.dart';
import 'home.dart';
import 'main.dart';
import 'riwayat.dart';
import 'barang.dart';
import 'PembeliPage.dart';
import 'authman.dart';
import 'package:http/http.dart' as http;

class PembeliDetailPage extends StatefulWidget {
  const PembeliDetailPage({super.key});
  @override
  State<PembeliDetailPage> createState() => _PembeliDetailPageState();
}

class _PembeliDetailPageState extends State<PembeliDetailPage> {
  Map<String, dynamic>? pembeliData;
  bool isLoading = true;
  String _username = ''; // Data pengguna
  String _namapembeli = '';
  int _currentIndex = 0 ; //Data pengguna

  @override
  void initState() {
    super.initState();
    _initializeData(); // Pastikan semua data selesai di-load sebelum fetchVendorData
  }

  // Fungsi untuk mengambil inisial nama vendor
  String getInitials(String? name) {
    if (name == null || name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  Future<void> _loadUserData() async {
    try {
      final username = await AuthManager.getUser();
      setState(() {
        _username = username ?? '';
      });
      debugPrint('Load User Data: $_username');
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadPembeliData() async {
    try {
      final namapembeli = await AuthManager.getPembeli();
      setState(() {
        _namapembeli = namapembeli ?? '';
      });
      debugPrint('Load Vendor Data: $_namapembeli');
    } catch (e) {
      debugPrint('Error loading vendor data: $e');
    }
  }

  Future<void> _initializeData() async {
    debugPrint('Initializing data...');
    await _loadUserData();
    await _loadPembeliData();
    debugPrint('Data initialized: username=$_username, namapembeli=$_namapembeli');

    if (_username.isNotEmpty && _namapembeli.isNotEmpty) {
      fetchPembeliData();
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username atau Nama Pembeli kosong')),
      );
    }
  }

  Future<void> fetchDeletePembeliData() async {
    if (_username.isEmpty || _namapembeli.isEmpty) {
      debugPrint('fetchPembeliData: Username atau Nama Pembeli kosong');
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse(
          'http://192.168.116.127:5002/api/delete_pembeli?username=$_username&namapembeli=$_namapembeli',
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pembeli berhasil dihapus')), // Menampilkan pesan dari server
        );
      } else {
        throw Exception('Failed to load pembeli data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> fetchPembeliData() async {
    if (_username.isEmpty || _namapembeli.isEmpty) {
      debugPrint('fetchPembeliData: Username atau Nama Pembeli kosong');
      return;
    }

    try {
      debugPrint('fetchPembeliData: username=$_username, namapembeli=$_namapembeli');
      final response = await http.get(
        Uri.parse(
          'http://192.168.116.127:5002/api/get_update_pembeli?username=$_username&namapembeli=$_namapembeli',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          pembeliData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load pembeli data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(_namapembeli);
    return Scaffold(
      appBar: 
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text('Detail Pembeli'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Menampilkan dialog konfirmasi
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Apakah Anda yakin ingin menghapus data pembeli ini?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Tutup dialog
                        },
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          fetchDeletePembeliData(); // Panggil fungsi penghapusan
                          Navigator.push(context,MaterialPageRoute(builder: (context) => DaftarPembeli()),); // Tutup dialog
                        },
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pembeliData == null
              ? const Center(child: Text('Pembeli not found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue, // Warna latar belakang avatar
                            radius: 40, // Ukuran avatar
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white, // Warna teks
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pembeliData!['namapembeli'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                pembeliData!['notele'].toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UpdatePembeliPage()),
                              );
                            },
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alamat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(pembeliData!['alamat']),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(pembeliData!['catatan'] ?? '(Tidak ada)'),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                      label: 'Users',
                    ),
                  ],
                ),
    );
  }
}
