import 'package:flutter/material.dart';
import 'authman.dart';
import 'riwayat.dart';
import 'main.dart';
import 'home.dart';
import 'barang.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StokAuditPage extends StatefulWidget {
  const StokAuditPage({super.key});

  @override
  _StokAuditPageState createState() => _StokAuditPageState();
}

class _StokAuditPageState extends State<StokAuditPage> {
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();

  String? _selectedBarang;
  String? _selectedKodeBarang;
  String _username = '';
  bool _isLoading = false;
  int _currentIndex = 0;

  List<Map<String, dynamic>> _barangList = [];

  final String _tanggal = DateTime.now().toLocal().toString().split(' ')[0];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final username = await AuthManager.getUser();
      setState(() {
        _username = username ?? '';
      });
      _fetchData();
    } catch (e) {
      print('Terjadi kesalahan saat mengambil data pengguna: $e');
    }
  }

  Future<void> _fetchData() async {
    try {
      await _fetchBarang();
    } catch (e) {
      print('Error saat mengambil data: $e');
    }
  }

  Future<void> _fetchBarang() async {
    try {
      final url = Uri.parse('http://192.168.116.127:5002/api/get_barang?username=$_username');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List barangData = json.decode(response.body);
        setState(() {
          _barangList = barangData.map((barang) {
            return {
              'kodebarang': barang['kodebarang'].toString(),
              'namabarang': barang['namabarang'].toString(),
            };
          }).toList();
        });
      } else {
        throw Exception('Gagal mengambil data barang.');
      }
    } catch (e) {
      print('Error pada _fetchBarang: $e');
    }
  }

  Future<void> _submitData() async {
    if (_selectedBarang == null || _selectedKodeBarang == null || _jumlahController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode barang, barang, dan jumlah harus diisi!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Menyimpan ke riwayat
      final response = await http.post(
        Uri.parse('http://192.168.116.127:5002/api/add_riwayat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "kodebarang": _selectedKodeBarang,
          "namabarang": _selectedBarang,
          "namavendor": " ",
          "namapembeli": " ",
          "tanggal": _tanggal,
          "jumlah": _jumlahController.text,
          "catatan": _catatanController.text,
          "kegiatan": "Stok Audit",
          "username": _username
        }),
      );

      if (response.statusCode != 200) {
        final responseData = json.decode(response.body);
        throw Exception('Gagal menyimpan data: ${responseData['message']}');
      }

      // Memperbarui stok barang
      final uri = Uri.parse('http://192.168.116.127:5002/api/stok_audit?username=$_username&kodebarang=$_selectedKodeBarang');
      final request = http.MultipartRequest('PUT', uri);
      request.fields['jumlah'] = _jumlahController.text;
      final responsed = await request.send();
      if (responsed.statusCode == 200) {
        print('Data stok berhasil diperbarui.');
      } else {
        print('Gagal memperbarui stok: ${response.reasonPhrase}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil disimpan!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stok Audit')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedBarang,
                items: _barangList
                    .map((barang) => DropdownMenuItem(
                          value: '${barang['namabarang']}',
                          child: Text('${barang['kodebarang']} - ${barang['namabarang']}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBarang = value;
                    _selectedKodeBarang = _barangList.firstWhere((barang) => barang['namabarang'] == value)['kodebarang'];
                  });
                },
                decoration: const InputDecoration(labelText: 'Barang'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                initialValue: _tanggal,
                decoration: const InputDecoration(labelText: 'Tanggal'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(labelText: 'Catatan'),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan'),
                ),
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
            label: 'Users',
          ),
        ],
      ),
    );
  }
}
