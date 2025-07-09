import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'authman.dart';
import 'home.dart';
import 'riwayat.dart';
import 'barang.dart';
import 'main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class UpdateBarangPage extends StatefulWidget {
  const UpdateBarangPage({super.key});

  @override
  _UpdateBarangPageState createState() => _UpdateBarangPageState();
}

class _UpdateBarangPageState extends State<UpdateBarangPage> {
  final _kodeBarangController = TextEditingController();
  final _namaBarangController = TextEditingController();
  final _hargaModalController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _jumlahController = TextEditingController();
  final TextEditingController _tanggalKadaluarsaController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _catatanController = TextEditingController();

  
  Uint8List? _selectedImageBytes; // Menyimpan data gambar sebagai byte array
  final ImagePicker _picker = ImagePicker();
  String _imagePath = ''; // Menyimpan path gambar yang sudah ada
  String _username = ''; // Data pengguna
  int? _kodebarang; // Ubah tipe menjadi int
  bool _isLoading = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadKodeData();
    _tanggalKadaluarsaController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // Fungsi untuk membuat kode random
  String generateRandomCode(int length) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length)),
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final username = await AuthManager.getUser();
      setState(() {
        _username = username ?? '';
      });
    } catch (e) {
      print('Terjadi kesalahan saat mengambil data pengguna: $e');
    }
  }

  Future<void> _loadKodeData() async {
    try {
      final kodebarang = await AuthManager.getBarang();
      setState(() {
        _kodebarang = int.tryParse(kodebarang!); // Konversi string ke integer
      });
      if (_kodebarang != null) {
        _loadBarangData(); // Muat data barang jika kode valid
      }
    } catch (e) {
      print('Terjadi kesalahan saat mengambil data kode barang: $e');
    }
  }

  Future<void> _loadBarangData() async {
    if (_kodebarang == null) {
      print('Kode barang tidak valid.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (_kodebarang == null || _username.isEmpty) {
      print('Username atau Kode Barang tidak valid.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.116.127:5002/api/get_update_barang?username=$_username&Kodebarang=$_kodebarang'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          // Data sesuai ekspektasi
          print('Data berhasil diambil: $data');
          DateTime? parsedDate;
          if (data['tanggalkadaluarsa'] != null) {
            try {
              final inputFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss z'); // Format string input
              parsedDate = inputFormat.parse(data['tanggalkadaluarsa']);
            } catch (e) {
              parsedDate = null; // Handle invalid date format
            }
          }
          final formattedDate = parsedDate != null
            ? DateFormat('yyyy-MM-dd').format(parsedDate)
            : 'N/A';
          setState(() {
            _kodeBarangController.text = data['kodebarang'].toString();
            _namaBarangController.text = data['namabarang'];
            _hargaModalController.text = data['hargamodal'].toString();
            _hargaJualController.text = data['hargajual'].toString();
            _jumlahController.text = data['jumlah'].toString();
            _tanggalKadaluarsaController.text = formattedDate;
            _kategoriController.text = data['kategori'];
            _catatanController.text = data['catatan'];
            _imagePath = data['gambar'] ?? '';
          });
        }
      } else {
        print('Gagal mengambil data barang: ${response.statusCode}');
      }
    } catch (e) {
      print('Terjadi kesalahan saat mengambil data barang: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk memilih gambar baru
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes(); // Membaca gambar menjadi bytes
      setState(() {
        _selectedImageBytes = imageBytes; // Menyimpan gambar yang dipilih
      });
    }
  }

  Future<void> fetchDeleteBarangData() async {
    if (_username.isEmpty || _kodebarang == null ) {
      debugPrint('fetchPembeliData: Username atau Kode Barang kosong');
      return;
    }

    try {
      debugPrint('fetchVendorData: username=$_username, Kodebarang=$_kodebarang');
      final response = await http.delete(
        Uri.parse(
          'http://192.168.116.127:5002/api/delete_barang?username=$_username&Kodebarang=$_kodebarang',
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Barang berhasil dihapus')), // Menampilkan pesan dari server
        );
      } else {
        throw Exception('Failed to load barang data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> submitData() async {
    final kodeBarangBaru = _kodeBarangController.text.isNotEmpty
        ? int.parse(_kodeBarangController.text)
        : _kodebarang; // Gunakan kode barang lama jika input kosong

    if (_selectedImageBytes == null || kodeBarangBaru == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar dan masukkan kode barang terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });


    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Menampilkan loading indicator saat data sedang diproses
    });

    try {
      final uri = Uri.parse('http://192.168.116.127:5002/api/update_barang?username=$_username&Kodebarang=$_kodebarang');
      final request = http.MultipartRequest('PUT', uri);

      // Menambahkan data form lainnya
      request.fields['kodebarang'] = kodeBarangBaru.toString();
      request.fields['namabarang'] = _namaBarangController.text;
      request.fields['hargamodal'] = _hargaModalController.text;
      request.fields['hargajual'] = _hargaJualController.text;
      request.fields['jumlah'] = _jumlahController.text;
      request.fields['tanggalkadaluarsa'] = _tanggalKadaluarsaController.text;
      request.fields['username'] = _username;
      request.fields['kategori'] = _kategoriController.text;
      request.fields['catatan'] = _catatanController.text;

      // Menambahkan file gambar
      final randomCode = generateRandomCode(10);
      request.files.add(
        http.MultipartFile.fromBytes(
          'gambar', // Nama field yang akan diterima di server
          _selectedImageBytes!,
          filename: 'image$randomCode.jpg',
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil diperbarui!')),
        );
        await AuthManager.clearBarang();
        Navigator.push( context, MaterialPageRoute(builder: (context) => DaftarProduk()),);
      } else {
        final responseData = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui data: $responseData')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Menyembunyikan loading indicator setelah proses selesai
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: 
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text('Update Barang'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Menampilkan dialog konfirmasi
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Apakah Anda yakin ingin menghapus data barang ini?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Tutup dialog
                        },
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          fetchDeleteBarangData(); // Panggil fungsi penghapusan
                          Navigator.push(context,MaterialPageRoute(builder: (context) => DaftarProduk()),); // Tutup dialog
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
               children: [
                 Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Gambar placeholder
                     GestureDetector(
                      onTap: _pickImage, // Fungsi yang dijalankan saat tombol dipilih
                      child: Container(
                        width: 100, // Ukuran tombol gambar
                        height: 100,
                        decoration: BoxDecoration(
                          image: _selectedImageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_selectedImageBytes!), // Menampilkan gambar yang dipilih
                                  fit: BoxFit.cover, // Sesuaikan gambar di dalam kotak
                                )
                              : (_imagePath.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage('http://192.168.116.127:5002/$_imagePath'),
                                      fit: BoxFit.cover, // Menampilkan gambar dari URL jika ada
                                    )
                                  : null), // Tidak ada gambar, tetap menampilkan placeholder
                          borderRadius: BorderRadius.circular(8), // Radius sudut
                          color: _selectedImageBytes == null && _imagePath.isEmpty
                              ? Colors.blue[300] // Warna placeholder jika belum ada gambar
                              : Colors.transparent, // Tidak ada warna jika gambar tersedia
                        ),
                        child: (_selectedImageBytes == null && _imagePath.isEmpty)
                            ? Icon(Icons.camera_alt, color: Colors.grey[700]) // Ikon kamera sebagai placeholder
                            : null, // Tidak menampilkan ikon jika ada gambar
                      ),
                    ),
                     const SizedBox(width: 16.0), // Spasi antar elemen
                     Expanded(
                       child: TextField(
                         controller: _kodeBarangController,
                         decoration: InputDecoration(
                           labelText: 'Kode Barang',
                           suffixIcon: IconButton(
                             icon: Icon(Icons.qr_code_scanner),
                             onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Fitur Dalam Tahap Pengembangan'), // Pesan yang ditampilkan
                                  ),
                                );
                              },
                           ),
                         ),
                       ),
                     ),
                   ],
                 ),
                  TextField(
                    controller: _namaBarangController,
                    decoration: const InputDecoration(labelText: 'Nama Barang'),
                  ),
                  TextField(
                    controller: _hargaModalController,
                    decoration: const InputDecoration(labelText: 'Harga Modal'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _hargaJualController,
                    decoration: const InputDecoration(labelText: 'Harga Jual'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _jumlahController,
                    decoration: const InputDecoration(labelText: 'Jumlah'),
                    keyboardType: TextInputType.number,
                  ),
                 TextField(
                    controller: _tanggalKadaluarsaController,
                    decoration: InputDecoration(
                      labelText: "Tanggal Kadaluarsa",
                      hintText: "yyyy-MM-dd",
                    ),
                    readOnly: true, // Disable editing, allow only date picking
                    onTap: () async {
                      // Show date picker when the user taps on the TextField
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      setState(() {
                        // Format the selected date and update the controller text
                        _tanggalKadaluarsaController.text = DateFormat('yyyy-MM-dd').format(pickedDate!);
                      });
                                        },
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
                    onPressed: submitData,
                    child: const Text('Update Barang'),
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
          await AuthManager.clearBarang();
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

