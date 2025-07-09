import 'package:flutter/material.dart';
import 'authman.dart';
import 'home.dart';
import 'main.dart';
import 'add_barang.dart';
import 'update_barang.dart';
import 'riwayat.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DaftarProduk extends StatefulWidget {
  const DaftarProduk({super.key});

  @override
  _DaftarProdukState createState() => _DaftarProdukState();
}

class _DaftarProdukState extends State<DaftarProduk> {
  final username = AuthManager.getUser();
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

  Future<List<Map<String, dynamic>>> fetchProducts(String username) async {
    final url = Uri.parse('http://192.168.116.127:5002/api/get_barang?username=$username'); // Sesuaikan endpoint API
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );
  
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final List products = responseData;
      if (products.isEmpty) {
        print("Tidak ada produk ditemukan.");
        return [];
      } else {
        return products.map((product) => product as Map<String, dynamic>).toList();
      }
    } else {
      throw Exception('Gagal mengambil data produk: ${response.statusCode}');
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
        title: const Text('Daftar Produk'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fitur Dalam Tahap Pengembangan')), // Menampilkan pesan dari server
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fitur Dalam Tahap Pengembangan')), // Menampilkan pesan dari server
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fitur Dalam Tahap Pengembangan')), // Menampilkan pesan dari server
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchProducts(_username),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada produk yang ditemukan.'));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                  } else {
                    final products = snapshot.data!;
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        try {
                          final product = products[index];
                          final namaBarang = product['namabarang'] ?? 'Produk Tanpa Nama';
                          final hargaJual = product['hargajual'] ?? 'N/A';
                          final gambar = product['gambar'];
                          final kodeBarang = product['kodebarang'].toString();
                          final initials = getInitials(product['namabarang']);

                          return ListTile(
                            leading: gambar != null
                                ? Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage('http://192.168.116.127:5002/$gambar'),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[300],
                                    ),
                                  )
                                : Container(
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
                                  ),
                            title: Text(namaBarang),
                            subtitle: Text('Harga: Rp. $hargaJual'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () async {
                              await AuthManager.saveBarang(kodeBarang.toString());
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UpdateBarangPage()),
                              );
                                                        },
                          );
                        } catch (e) {
                          print('Kesalahan saat memproses produk di indeks $index: $e');
                          return const SizedBox.shrink();
                        }
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
            MaterialPageRoute(builder: (context) => AddBarangPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Barang'),
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
