import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static Future<void> saveUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username); // Save username
    print("Data saved: username=$username");
  }

  static Future<String?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    return username; // Return the username as a string
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username'); // Remove username
    print("User data cleared");
  }

  static Future<void> saveBarang(String kodebarang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kodebarang', kodebarang); // Save username
    print("Data saved: kodebarang=$kodebarang");
  }

  static Future<String?> getBarang() async {
    final prefs = await SharedPreferences.getInstance();
    final kodebarang = prefs.getString('kodebarang');
    return kodebarang; // Return the username as a string
  }

  static Future<void> clearBarang() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kodebarang'); // Remove username
    print("User data cleared");
  }

  static Future<void> saveVendor(String namavendor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('namavendor', namavendor); // Save username
    print("Data saved: namavendor=$namavendor");
  }

  static Future<String?> getVendor() async {
    final prefs = await SharedPreferences.getInstance();
    final namavendor = prefs.getString('namavendor');
    return namavendor; // Return the username as a string
  }

  static Future<void> clearVendor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('namavendor'); // Remove username
    print("User data cleared");
  }

  static Future<void> savePembeli(String namapembeli) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('namapembeli', namapembeli); // Save username
    print("Data saved: namapembeli=$namapembeli");
  }

  static Future<String?> getPembeli() async {
    final prefs = await SharedPreferences.getInstance();
    final namapembeli = prefs.getString('namapembeli');
    return namapembeli; // Return the username as a string
  }

  static Future<void> clearPembeli() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('namapembeli'); // Remove username
    print("User data cleared");
  }
}
