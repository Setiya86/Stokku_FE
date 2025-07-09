import 'package:flutter/material.dart';
import 'dart:convert';
import 'home.dart';
import 'main.dart';
import 'barang.dart';
import 'authman.dart';
import 'package:intl/intl.dart';
import 'profil_vebdor.dart';
import 'package:http/http.dart' as http;


class DaftarRiwayat extends StatefulWidget {
  const DaftarRiwayat({super.key});

  @override
  _DaftarRiwayatState createState() => _DaftarRiwayatState();
}

class _DaftarRiwayatState extends State<DaftarRiwayat> {
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
  Future<List<Map<String, dynamic>>> fetchRiwayat(String username) async {
    final url = Uri.parse('http://192.168.116.127:5002/api/get_riwayat?username=$_username'); // Sesuaikan endpoint API
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List riwayts = json.decode(response.body);
      print('Data Riwayat: $riwayts'); 
      return riwayts.map((riwayt) => riwayt as Map<String, dynamic>).toList();
    } else {
      throw Exception('Gagal mengambil data riwayt: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts(String username) async {
    final url = Uri.parse('http://192.168.116.127:5002/api/get_barang?username=$_username'); // Sesuaikan endpoint API
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List products = json.decode(response.body);
      return products.map((product) => product as Map<String, dynamic>).toList();
    } else {
      throw Exception('Gagal mengambil data produk: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> fetchAllData(String username) async {
    return await Future.wait([
      fetchRiwayat(_username),
      fetchProducts(_username),
    ]);
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
        title: const Text('Daftar Riwayat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fitur Dalam Tahap Pengembangan')), // Menampilkan pesan dari server
              );
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
              child: FutureBuilder<List<dynamic>>(
                future: fetchAllData(_username),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada riwayat yang ditemukan'));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                  } else {
                    final riwayats = snapshot.data![0] as List<Map<String, dynamic>>;
                    final products = snapshot.data![1] as List<Map<String, dynamic>>;
                
                    return ListView.builder(
                      itemCount: riwayats.length,
                      itemBuilder: (context, index) {
                        final riwayat = riwayats[index];
                        print('Riwayat: $riwayat');
                        final productList = products.where(
                          (p) => p['kodebarang'] == riwayat['kodebarang'],
                        ).toList();

                        // Tangani kasus ketika tidak ada produk ditemukan untuk riwayat yang diberikan
                        final product = productList.isNotEmpty ? productList.first : null;
                
                        // Initials for placeholder
                        final initials = getInitials(riwayat['namabarang'] ?? 'Barang');
                
                        // Parse and format the date
                        DateTime? parsedDate;
                        if (riwayat['tanggal'] != null) {
                          try {
                            parsedDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss z').parse(riwayat['tanggal']);
                          } catch (_) {
                            parsedDate = null;
                          }
                        }
                        final formattedDate = parsedDate != null
                            ? DateFormat('dd-MM-yyyy').format(parsedDate)
                            : 'N/A';
                
                        return ListTile(
                          leading: _buildLeadingWidget(product, initials),
                          title: Text(riwayat['namabarang'] ?? 'Barang Tanpa Nama'),
                          subtitle: Text('Tanggal: $formattedDate'),
                          trailing: _buildTrailingWidget(riwayat),
                          onTap: () async {
                            await AuthManager.saveVendor(riwayat['namavendor']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => VendorDetailPage()),
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

Widget _buildLeadingWidget(Map<String, dynamic>? product, String initials) {
  if (product == null) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  } else {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('http://192.168.116.127:5002/${product['gambar']}'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
    );
  }
}


Widget _buildTrailingWidget(Map<String, dynamic> riwayat) {
  final jumlah = riwayat['jumlah'] ?? 'N/A';
  final kegiatan = riwayat['kegiatan'] ?? 'N/A';

  Color statusColor;
  if (kegiatan == 'Stok Masuk') {
    statusColor = Colors.green;
  } else if (kegiatan == 'Stok Keluar') {
    statusColor = Colors.red;
  } else {
    statusColor = Colors.blue;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        kegiatan == 'Stok Masuk'
            ? '+$jumlah'
            : kegiatan == 'Stok Keluar'
                ? '-$jumlah'
                : jumlah.toString(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
      Text(
        kegiatan,
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: statusColor,
        ),
      ),
    ],
  );
}
