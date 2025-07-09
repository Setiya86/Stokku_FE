import 'package:flutter/material.dart';
import 'authman.dart';
import 'StokMasukPage.dart';
import 'AuditPage.dart';
import 'main.dart';
import 'PembeliPage.dart';
import 'StokKeluarPage.dart';
import 'VendorPage.dart';
import 'barang.dart';
import 'riwayat.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _username = '';
  String _name = 'Loading...'; // Nama awal yang akan muncul adalah "Loading..."
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fungsi untuk memuat data user
  Future<void> _loadUserData() async {
    try {
      final username = await AuthManager.getUser(); // Mengambil username langsung sebagai String
      setState(() {
        _username = username ?? ''; // Jika username null, set menjadi kosong
      });

      // Jika username ditemukan, ambil nama pengguna dari API
      if (_username.isNotEmpty) {
        String name = await fetchUserName(_username);
        setState(() {
          _name = name;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Terjadi kesalahan saat mengambil data pengguna: $e');
      setState(() {
        _isLoading = false;
        _name = 'Error loading user data';  // Jika terjadi kesalahan, tampilkan pesan error
      });
    }
  }

  // Fungsi untuk mengambil nama pengguna dari API
  Future<String> fetchUserName(String username) async {
    final String apiUrl = 'http://192.168.116.127:5002/api/get_user?username=$_username'; // Ganti dengan URL API yang sesuai
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['name'] ?? 'Unknown';  // Mengembalikan nama atau 'Unknown' jika tidak ditemukan
      } else {
        throw Exception('Gagal memuat nama pengguna');
      }
    } catch (e) {
      print('Terjadi kesalahan saat mengambil nama pengguna: $e');
      return 'Error loading name';  // Jika terjadi kesalahan, kembalikan nilai default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? CircularProgressIndicator() // Menampilkan indikator loading saat mengambil data
            : Text('Toko $_name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian "Data hari ini"
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data hari ini',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DataColumn('Stok Masuk', '*', Colors.green),
                        DataColumn('Stok Keluar', '*', Colors.red),
                        DataColumn('Omset', '*', Colors.blue),
                        DataColumn('Untung', '*', Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            // Tombol Laporan Stok dan Keuangan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.assignment),
                  label: Text('Laporan Stok'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.bar_chart),
                  label: Text('Laporan Keuangan'),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Menu bawah: Stok Masuk, Stok Keluar, Audit, dll.
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  MenuButton('Stok Masuk', Icons.download, Colors.green, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StokMasukPage()),
                    );
                  }),
                  MenuButton('Stok Keluar', Icons.upload, Colors.red, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StokKeluarPage()),
                    );
                  }),
                  MenuButton('Audit', Icons.check, Colors.orange, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StokAuditPage()),
                    );
                  }),
                  MenuButton('Staff', Icons.person, Colors.purple, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fitur Dalam Tahap Pengembangan')), // Menampilkan pesan dari server
                    );
                  }),
                  MenuButton('Vendor', Icons.local_shipping, Colors.blue, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DaftarVendor()),
                    );
                  }),
                  MenuButton('Pembeli', Icons.group, Colors.indigo, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DaftarPembeli()),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() async {
            _currentIndex = index;
            // Logika untuk navigasi ke halaman yang sesuai
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
          });
        },
        items: [
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

class DataColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const DataColumn(this.label, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MenuButton(this.label, this.icon, this.color, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            SizedBox(height: 10),
            Text(label, style: TextStyle(color: color, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
