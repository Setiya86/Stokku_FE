import 'package:flutter/material.dart';
import 'dart:convert';
import 'home.dart';
import 'riwayat.dart';
import 'barang.dart';
import 'main.dart';
import 'authman.dart';
import 'add_pembeli.dart';
import 'profil_pembeli.dart';
import 'package:http/http.dart' as http;


class DaftarPembeli extends StatefulWidget {
  const DaftarPembeli({super.key});

  @override
  _DaftarPembeliState createState() => _DaftarPembeliState();
}

class _DaftarPembeliState extends State<DaftarPembeli> {
  String _username = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      final username = await AuthManager.getUser(); // Mengambil username langsung sebagai String
      setState(() {
        _username = username ?? ''; // Jika username null, set menjadi kosong
      });

    } catch (e) {
      print('Terjadi kesalahan saat mengambil data pengguna: $e');
     }
  }
  Future<List<Map<String, dynamic>>> fetchVendors(String username) async {
    final url = Uri.parse('http://192.168.116.127:5002/api/get_pembeli?username=$_username'); // Sesuaikan endpoint API
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List pembelis = json.decode(response.body);
      return pembelis.map((pembeli) => pembeli as Map<String, dynamic>).toList();
    } else {
      throw Exception('Gagal mengambil data pembeli: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Daftar Pembeli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              print('Download button pressed');
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "Unduh",
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchVendors(_username),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada pembeli yang ditemukan'));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                  } else {
                    final pembelis = snapshot.data!;
                    return ListView.builder(
                      itemCount: pembelis.length,
                      itemBuilder: (context, index) {
                        final pembeli = pembelis[index];
                        final initials = getInitials(pembeli['namapembeli']);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue, // Warna latar belakang avatar
                            radius: 20, // Ukuran avatar
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white, // Warna teks
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(pembeli['namapembeli'] ?? 'Vendor Tanpa Nama'),
                          subtitle: Text('No Telepon: ${pembeli['notelepon'] ?? 'N/A'}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () async {
                            await AuthManager.savePembeli(pembeli['namapembeli']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PembeliDetailPage()),
                            );
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => InputDataPembeliPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Pembeli'),
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

