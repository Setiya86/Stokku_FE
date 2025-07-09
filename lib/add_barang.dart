import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'authman.dart';
import 'main.dart';
import 'home.dart';
import 'barang.dart';
import 'riwayat.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;



class AddBarangPage extends StatefulWidget {
  const AddBarangPage({super.key});

  @override
  _AddBarangPageState createState() => _AddBarangPageState();
}

class _AddBarangPageState extends State<AddBarangPage> {
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
  String _username = '';// Contoh data
  int _currentIndex = 0;
  final bool _isLoading = false;
  // String _imagePath = '';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _tanggalKadaluarsaController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = imageBytes;
        // _imagePath = ''; // Reset path gambar jika memilih gambar baru
      });
    }
  }


  Future<void> submitData() async {
    if (_selectedImageBytes == null || _kodeBarangController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar dan masukkan kode barang terlebih dahulu!')),
      );
      return;
    }

    try {
      final uri = Uri.parse('http://192.168.116.127:5002/api/add_barang'); // Ganti dengan IP Flask
      final request = http.MultipartRequest('POST', uri);

      request.fields['kodebarang'] = _kodeBarangController.text;
      request.fields['namabarang'] = _namaBarangController.text;
      request.fields['hargamodal'] = _hargaModalController.text;
      request.fields['hargajual'] = _hargaJualController.text;
      request.fields['jumlah'] = _jumlahController.text;
      request.fields['tanggalkadaluarsa'] = _tanggalKadaluarsaController.text;
      request.fields['username'] = _username;
      request.fields['kategori'] = _kategoriController.text;
      request.fields['catatan'] = _catatanController.text;

      final randomCode = generateRandomCode(10); // Panjang kode random
      // Kirim gambar
      request.files.add(http.MultipartFile.fromBytes(
        'gambar',
        _selectedImageBytes!,
        filename: 'uploaded_image$randomCode.png',
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil ditambahkan!')),
        );
       Navigator.push(context,MaterialPageRoute(builder: (context) => DaftarProduk()),);
      } else {
        final responseData = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan data: $responseData')),
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
      appBar: AppBar(title: const Text('Tambah Barang')),
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
                                  fit: BoxFit.cover, // Sesuaikan gambar di dalam container
                                )
                              : null, // Tidak ada gambar, tetap menampilkan placeholder
                          borderRadius: BorderRadius.circular(8),
                          color: _selectedImageBytes == null ? Colors.blue[300] : Colors.transparent, // Warna placeholder saat gambar belum dipilih
                        ),
                        child: _selectedImageBytes == null
                            ? Icon(Icons.camera_alt, color: Colors.grey[700]) // Menampilkan ikon kamera sebagai placeholder
                            : null, // Tidak menampilkan ikon jika gambar sudah dipilih
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
                    child: const Text('Tambah Barang'),
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
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }
}
