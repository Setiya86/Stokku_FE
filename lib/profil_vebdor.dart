import 'package:flutter/material.dart';
import 'dart:convert';
import 'update_vendor.dart';
import 'VendorPage.dart';
import 'main.dart';
import 'home.dart';
import 'riwayat.dart';
import 'barang.dart';
import 'authman.dart';
import 'package:http/http.dart' as http;

class VendorDetailPage extends StatefulWidget {
  const VendorDetailPage({super.key});
  @override
  State<VendorDetailPage> createState() => _VendorDetailPageState();
}

class _VendorDetailPageState extends State<VendorDetailPage> {
  Map<String, dynamic>? vendorData;
  bool isLoading = true;
  String _username = ''; // Data pengguna
  String _namavendor = ''; // Data pengguna
  int _currentIndex = 0;

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
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadVendorData() async {
    try {
      final namavendor = await AuthManager.getVendor();
      setState(() {
        _namavendor = namavendor ?? '';
      });
      debugPrint('Load Vendor Data: $_namavendor');
    } catch (e) {
      debugPrint('Error loading vendor data: $e');
    }
  }

  Future<void> _initializeData() async {
    debugPrint('Initializing data...');
    await _loadUserData();
    await _loadVendorData();
    debugPrint('Data initialized: username=$_username, namavendor=$_namavendor');

    if (_username.isNotEmpty && _namavendor.isNotEmpty) {
      fetchVendorData();
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username atau Nama Vendor kosong')),
      );
    }
  }

  Future<void> fetchDeleteVendorData() async {
    if (_username.isEmpty || _namavendor.isEmpty) {
      debugPrint('fetchVendorData: Username atau Nama Vendor kosong');
      return;
    }

    try {
      debugPrint('fetchVendorData: username=$_username, namavendor=$_namavendor');
      final response = await http.delete(
        Uri.parse(
          'http://192.168.116.127:5002/api/delete_vendor?username=$_username&namavendor=$_namavendor',
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vendor berhasil dihapus')), // Menampilkan pesan dari server
        );
      } else {
        throw Exception('Failed to load vendor data');
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

  Future<void> fetchVendorData() async {
    if (_username.isEmpty || _namavendor.isEmpty) {
      debugPrint('fetchVendorData: Username atau Nama Vendor kosong');
      return;
    }

    try {
      debugPrint('fetchVendorData: username=$_username, namavendor=$_namavendor');
      final response = await http.get(
        Uri.parse(
          'http://192.168.116.127:5002/api/get_update_vendor?username=$_username&namavendor=$_namavendor',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          vendorData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load vendor data');
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
    final initials = getInitials(_namavendor);
    return Scaffold(
      appBar: 
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text('Detail Vendor'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Menampilkan dialog konfirmasi
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Apakah Anda yakin ingin menghapus data Vendor ini?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Tutup dialog
                        },
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          fetchDeleteVendorData(); // Panggil fungsi penghapusan
                          Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DaftarVendor()),
                              ); // Tutup dialog
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
          : vendorData == null
              ? const Center(child: Text('Vendor not found'))
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
                                vendorData!['namavendor'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                vendorData!['notele'].toString(),
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
                                MaterialPageRoute(builder: (context) => UpdateVendorPage()),
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
                                'Detail Bank',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(vendorData!['namabank']),
                              const Text('Nama Bank'),
                              const SizedBox(height: 8),
                              Text(vendorData!['namaakunbank']),
                              const Text('Nama Pemilik'),
                              const SizedBox(height: 8),
                              Text(vendorData!['norek'].toString()),
                              const Text('Nomor Rekening'),
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
                              Text(vendorData!['catatan'] ?? '(Tidak ada)'),
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
                      label: 'Users',
                    ),
                  ],
                ),
    );
  }
}
