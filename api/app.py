from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.exc import SQLAlchemyError
from flask_cors import CORS  # Import CORS
import bcrypt  # Import bcrypt untuk hashing password
from datetime import datetime
from werkzeug.utils import secure_filename
import time
import os

app = Flask(__name__)

# Enable CORS for all routes
CORS(app)

UPLOAD_FOLDER = 'static/uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)  # Membuat folder jika belum ada
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


# Konfigurasi database
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:@localhost/stokku'
app.config['SQLALCHEMY_ECHO'] = True

# Inisialisasi SQLAlchemy
db = SQLAlchemy(app)

# Model untuk tabel users
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    username = db.Column(db.String(255), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    notele = db.Column(db.String(255))
    alamat = db.Column(db.String)
  
# Model untuk tabel barang    
class Barang(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    kodebarang = db.Column(db.Integer)
    namabarang = db.Column(db.String(255), nullable=False)
    hargamodal = db.Column(db.Integer, nullable=False)
    hargajual = db.Column(db.Integer,nullable=False)
    gambar = db.Column(db.String(255), nullable=False) 
    kategori = db.Column(db.String(255), nullable=False)
    tanggalkadaluarsa = db.Column(db.DateTime, default=datetime.utcnow, nullable=False )
    jumlah = db.Column(db.Integer,nullable=False)
    username = db.Column(db.String(255), nullable=False)
    catatan = db.Column(db.String)

# Model untuk tabel riwayat   
class Riwayat(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    kodebarang = db.Column(db.Integer)
    namabarang = db.Column(db.String(255), nullable=False)
    kegiatan = db.Column(db.String(255), nullable=False)
    jumlah = db.Column(db.Integer,nullable=False)
    username = db.Column(db.String(255), nullable=False)
    tanggal = db.Column(db.DateTime, default=datetime.utcnow, nullable=False )
    namavendor = db.Column(db.String(255))
    namapembeli = db.Column(db.String(255))
    catatan = db.Column(db.String)
  
# Model untuk tabel vendor    
class Vendor(db.Model):
    namavendor = db.Column(db.String(255), primary_key=True, nullable=False)
    username = db.Column(db.String(255), nullable=False)
    notele = db.Column(db.String(255), nullable=False)
    namabank = db.Column(db.String(255),nullable=False)
    norek = db.Column(db.Integer, nullable=False) 
    namaakunbank = db.Column(db.String(255), nullable=False )
    kategori = db.Column(db.String(255), nullable=False)
    catatan = db.Column(db.String)

# Model untuk tabel pembeli    
class Pembeli(db.Model):
    namapembeli = db.Column(db.String(255), primary_key=True, nullable=False)
    username = db.Column(db.String(255), nullable=False)
    notele = db.Column(db.String(255), nullable=False)
    alamat = db.Column(db.String,nullable=False)
    catatan = db.Column(db.String)
    
    
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Membuat tabel jika belum ada
with app.app_context():
    db.create_all()

@app.route('/')
def home():
    return "Hello, Flask is running!"

#daftar akun
@app.route('/api/signup', methods=['POST'])
def signup():
    data = request.json
    name = data.get('name')
    username = data.get('username')
    password = data.get('password')
    notele = data.get('notele')
    alamat = data.get('alamat')
    
    # Cek apakah username sudah ada di database
    existing_user = User.query.filter_by(username=username).first()
    if existing_user:
        return jsonify({'message': 'Username already exists'}), 400
    
    # Hash password
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    
    # Tambahkan pengguna baru ke database
    new_user = User(name=name, username=username, password=hashed_password.decode('utf-8'),notele=notele,alamat=alamat)
    db.session.add(new_user)
    db.session.commit()
    
    return jsonify({'message': 'User created successfully', 'username': username}), 200

#login akun
@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    
    # Cek apakah pengguna ada di database
    user = User.query.filter_by(username=username).first()
    if user:
        # Cek apakah password cocok dengan hash yang ada di database
        if bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
            return jsonify({'message': 'Login successful', 'username': username}), 200
        else:
            return jsonify({'message': 'username atau password salah'}), 401
    else:
        return jsonify({'message': 'Invalid credentials'}), 401
    
#ambil data user
@app.route('/api/get_user', methods=['GET','POST'])
def get_user():
    username = request.args.get('username')  # Ambil parameter 'username'
    print(username)
    # Query data berdasarkan username
    user = User.query.filter_by(username=username).first() 
    if user:
        return jsonify({
            'id': user.id,
            'name':user.name,
            'username': user.username,
            'alamat': user.alamat,
            'notele': user.notele
        })
    else:
        return jsonify({'error': 'User not found'}), 404

#ambil data barang
@app.route('/api/get_barang', methods=['GET','POST'])
def get_barang():
    username = request.args.get('username')  # Mengambil parameter username
    if not username:
        return jsonify({"error": "Username is required"}), 400

    barang_list = Barang.query.filter_by(username=username).all()
    if not barang_list:
        # Jika data tidak ditemukan
        return jsonify({
            'status': 'error',
            'message': f'No data found for username: {username}'
        }), 404
        
    if barang_list:
        result = [
            {"kodebarang": barang.kodebarang,
             "namabarang": barang.namabarang,
             "hargamodal": barang.hargamodal,
             'hargajual': barang.hargajual,
             'jumlah': barang.jumlah,
             'tanggalkadaluarsa': barang.tanggalkadaluarsa,
             'kategori': barang.kategori,
             'gambar': barang.gambar,
             'username': barang.username,
             'catatan': barang.catatan}
            for barang in barang_list
        ]
        print(result)
        return jsonify(result), 200
    else:
        return jsonify({"error": "No items found"}), 404
    
# Fungsi untuk memeriksa ekstensi file
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

#tambah data barang
@app.route('/api/add_barang', methods=['POST'])
def add_barang():
    try:
        data = request.form
        file = request.files.get('gambar')

        # Validasi kolom wajib
        required_fields = ['kodebarang', 'namabarang', 'hargamodal', 'hargajual', 'jumlah', 'tanggalkadaluarsa', 'username', 'kategori']
        if not all(data.get(field) for field in required_fields):
            return jsonify({'error': 'Semua kolom harus diisi!'}), 400

        # Validasi file
        if not file or not allowed_file(file.filename):
            return jsonify({'error': 'Gambar harus diunggah dan dalam format yang didukung (png, jpg, jpeg, gif)!'}), 400

        # Simpan file gambar
        if not os.path.exists(UPLOAD_FOLDER):
            os.makedirs(UPLOAD_FOLDER)
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        # Tambahkan ke database
        barang = Barang(
            kodebarang=data.get('kodebarang'),
            namabarang=data.get('namabarang'),
            hargamodal=float(data.get('hargamodal')),
            hargajual=float(data.get('hargajual')),
            jumlah=int(data.get('jumlah')),
            tanggalkadaluarsa=data.get('tanggalkadaluarsa'),
            gambar=filepath,
            username=data.get('username'),
            kategori=data.get('kategori'),
            catatan=data.get('catatan')
        )
        try:
            db.session.add(barang)
            db.session.commit()
            return jsonify({'message': 'Data berhasil ditambahkan!'}), 200
        except SQLAlchemyError as e:
            error = str(e)
            print(f"Error detail: {error}")
            db.session.rollback()
            return {"error": "Gagal menambahkan barang: " + error}, 500

    except Exception as e:
        return jsonify({'error': str(e)}), 500

#tampil data barang pilihan
@app.route('/api/get_update_barang', methods=['GET'])
def get_update_barang():
    username = request.args.get('username')
    kodebarang = int(request.args.get('Kodebarang'))
    try:
        kodebarang = int(kodebarang)  # Konversi kodebarang ke integer
        print(type(kodebarang))
    except ValueError:
        return jsonify({"error": "Kode barang harus berupa angka"}), 400
    if not username or not kodebarang:
        return jsonify({"error": "Username and Kode barang are required"}), 400
    
    # Query database
    barang = Barang.query.filter_by(username=username, kodebarang=kodebarang).first()
    print(barang.kodebarang)
    
    if barang:
        return jsonify (
            {
                "kodebarang": barang.kodebarang,
                "namabarang": barang.namabarang,
                "hargamodal": barang.hargamodal,
                "hargajual": barang.hargajual,
                "jumlah": barang.jumlah,
                "tanggalkadaluarsa": barang.tanggalkadaluarsa,
                "kategori": barang.kategori,
                "gambar": barang.gambar,
                "username": barang.username,
                "catatan": barang.catatan,
            }
        )
    else:
        return jsonify({"error": "No items found"}), 404

#update data barang
@app.route('/api/update_barang', methods=['PUT'])
def update_barang():
    try:
        # Cek Content-Type
        content_type = request.content_type
        if content_type.startswith('application/json'):
            data = request.json
        elif content_type.startswith('multipart/form-data'):
            data = request.form
        else:
            return jsonify({"error": "Unsupported Content-Type"}), 415

        # Ambil parameter
        kodebarang = int(request.args.get('Kodebarang'))
        username = data.get('username')
        new_kodebarang = data.get('new_kodebarang')

        # Validasi keberadaan barang
        barang = Barang.query.filter_by(username=username, kodebarang=kodebarang).first()
        if not barang:
            return jsonify({'message': 'Barang tidak ditemukan'}), 404

        # Periksa apakah ada perubahan pada kode barang
        if new_kodebarang and int(new_kodebarang) != kodebarang:
            # Update kode barang di tabel terkait (jika ada)
            related_tables = ['tabel_terkait_1', 'tabel_terkait_2']  # Tambahkan nama tabel terkait
            for table in related_tables:
                db.session.execute(
                    f"UPDATE {table} SET kodebarang = :new_kode WHERE kodebarang = :old_kode",
                    {'new_kode': new_kodebarang, 'old_kode': kodebarang},
                )

            barang.kodebarang = int(new_kodebarang)

        # Update data barang lainnya
        barang.namabarang = data['namabarang']
        barang.hargamodal = float(data['hargamodal'])
        barang.hargajual = float(data['hargajual'])
        barang.jumlah = int(data['jumlah'])
        barang.tanggalkadaluarsa = data['tanggalkadaluarsa']
        barang.kategori = data['kategori']
        barang.catatan = data['catatan']

        # Update gambar jika ada
        if 'gambar' in request.files:
            old_image_path = barang.gambar
            if old_image_path and os.path.exists(old_image_path):
                os.remove(old_image_path)

            gambar = request.files['gambar']
            gambar_path = os.path.join(app.config['UPLOAD_FOLDER'], gambar.filename)
            gambar.save(gambar_path)
            barang.gambar = gambar_path

        db.session.commit()
        return jsonify({'message': 'Data barang berhasil diperbarui'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@app.route('/api/delete_barang', methods=['DELETE'])
def delete_barang():
    try:
        # Ambil parameter
        kodebarang = int(request.args.get('Kodebarang'))
        username = request.args.get('username')
        
        # Query database
        barang = Barang.query.filter_by(username=username, kodebarang=kodebarang).first()
        # Menghapus produk
        db.session.delete(barang)
        db.session.commit()

        return jsonify({"message": f"Product {kodebarang} has been deleted"}), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

#stok masuk    
@app.route('/api/stok_masuk', methods=['PUT'])
def stok_masuk():
    content_type = request.content_type
    if content_type.startswith('application/json'):
        data = request.json
    elif content_type.startswith('multipart/form-data'):
        data = request.form
    else:
        return jsonify({"error": "Unsupported Content-Type"}), 415
    
    username = request.args.get('username') 
    kodebarang = int(request.args.get('kodebarang'))
    jumlah = int(data.get('jumlah'))
    
    print(type(jumlah))

    # Validasi input
    if not username or not kodebarang:
        return jsonify({'error': 'Username and Kodebarang are required'}), 400

    barang = Barang.query.filter(Barang.username == username, Barang.kodebarang == kodebarang).first()

    if not barang:
        return jsonify({'error': 'Barang not found'}), 404

    # Update data barang
    try:
        barang.jumlah = barang.jumlah + jumlah

        # Simpan perubahan ke database
        db.session.commit()
        return jsonify({
            'message': 'Barang updated successfully',
            'updated_barang': {
                'jumlah': barang.jumlah,
            }
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update barang: {str(e)}'}), 500
    
#stok audit    
@app.route('/api/stok_audit', methods=['PUT'])
def stok_audit():
    content_type = request.content_type
    if content_type.startswith('application/json'):
        data = request.json
    elif content_type.startswith('multipart/form-data'):
        data = request.form
    else:
        return jsonify({"error": "Unsupported Content-Type"}), 415
    
    username = request.args.get('username') 
    kodebarang = int(request.args.get('kodebarang'))
    jumlah = int(data.get('jumlah'))

    # Validasi input
    if not username or not kodebarang:
        return jsonify({'error': 'Username and Kodebarang are required'}), 400

    barang = Barang.query.filter(Barang.username == username, Barang.kodebarang == kodebarang).first()

    if not barang:
        return jsonify({'error': 'Barang not found'}), 404

    # Update data barang
    try:
        barang.jumlah = jumlah

        # Simpan perubahan ke database
        db.session.commit()
        return jsonify({
            'message': 'Barang updated successfully',
            'updated_barang': {
                'jumlah': barang.jumlah,
            }
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update barang: {str(e)}'}), 500
    
#stok keluar
@app.route('/api/stok_keluar', methods=['PUT'])
def stok_keluar():
    content_type = request.content_type
    if content_type.startswith('application/json'):
        data = request.json
    elif content_type.startswith('multipart/form-data'):
        data = request.form
    else:
        return jsonify({"error": "Unsupported Content-Type"}), 415
    
    username = request.args.get('username') 
    kodebarang = int(request.args.get('kodebarang'))
    jumlah = int(data.get('jumlah'))

    # Validasi input
    if not username or not kodebarang:
        return jsonify({'error': 'Username and Kodebarang are required'}), 400

    barang = Barang.query.filter(Barang.username == username, Barang.kodebarang == kodebarang).first()

    print(type(jumlah))
    
    if not barang:
        return jsonify({'error': 'Barang not found'}), 404

    # Update data barang
    try:
        barang.jumlah = barang.jumlah - jumlah
        print(type(barang.jumlah))

        # Simpan perubahan ke database
        db.session.commit()
        return jsonify({
            'message': 'Barang updated successfully',
            'updated_barang': {
                'jumlah': barang.jumlah,
            }
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update barang: {str(e)}'}), 500

#tambah data riwayat
@app.route('/api/add_riwayat', methods=['POST'])
def add_riwayat():
    data = request.json
    try:
        kodebarang = data['kodebarang']
        namabarang = data['namabarang']
        namavendor = data['namavendor']
        namapembeli = data['namapembeli']
        jumlah = data['jumlah']
        tanggal = data['tanggal']
        username = data['username']
        catatan = data['catatan']
        kegiatan = data['kegiatan']
        catatan = data['catatan']

        # Validasi data
        if not all([kodebarang, namabarang, namapembeli, namavendor, username, catatan, jumlah, kegiatan, tanggal, catatan]):
            return jsonify({'error': 'Semua kolom harus diisi!'}), 400

        # Tambahkan ke database
        riwayat = Riwayat(
            kodebarang=kodebarang,
            namabarang=namabarang,
            namavendor=namavendor,
            namapembeli=namapembeli,
            tanggal=tanggal,
            username=username,
            jumlah=jumlah,
            kegiatan=kegiatan,
            catatan=catatan
        )
        try :
            db.session.add(riwayat)
            db.session.commit()
        except SQLAlchemyError as e:
            error = str(e)
            print(f"Error detail: {error}")
            db.session.rollback()
            return {"error": "Gagal menambahkan barang: " + error}, 500

        return jsonify({'message': 'Data berhasil ditambahkan!'}), 200

    except KeyError as e:
        return jsonify({'error': f'Field {e} tidak ditemukan dalam permintaan'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
#tampil seluruh data riwayat     
@app.route('/api/get_riwayat', methods=['GET','POST'])
def get_riwayat():
    username = request.args.get('username')  # Mengambil parameter username

    if not username:
        return jsonify({"error": "Username is required"}), 400

    riwayat_list = Riwayat.query.filter(Riwayat.username.ilike(username)).all()
    print(f"Query untuk username {username}: {riwayat_list}")
    if riwayat_list:
        result = [
            {"kodebarang": riwayat.kodebarang,
             "namabarang": riwayat.namabarang,
             "namavendor": riwayat.namavendor,
             'tanggal': riwayat.tanggal,
             'namapembeli': riwayat.namapembeli,
             'jumlah': riwayat.jumlah,
             'kegiatan': riwayat.kegiatan,
             'catatan': riwayat.catatan}
            for riwayat in riwayat_list
        ]
        for riwayat in riwayat_list:
            print(vars(riwayat))
        print(f"Query untuk username {username}: {result}")
        return jsonify(result), 200
    else:
        return jsonify({"error": "No items found"}), 404
  
#tampil seluruh data vendor     
@app.route('/api/get_vendor', methods=['GET','POST'])
def get_vendor():
    username = request.args.get('username')  # Mengambil parameter username
    if not username:
        return jsonify({"error": "Username is required"}), 400

    vendor_list = Vendor.query.filter_by(username=username).all()
    if vendor_list:
        result = [
            {"namavendor": vendor.namavendor,
             "notelepon": vendor.notele,
             "namabank": vendor.namabank,
             'norekening': vendor.norek,
             'namaakunbank': vendor.namaakunbank,
             'kategori': vendor.kategori,
             'catatan': vendor.catatan}
            for vendor in vendor_list
        ]
        return jsonify(result), 200
    else:
        return jsonify({"error": "No items found"}), 404
    
#tambah data vendor    
@app.route('/api/add_vendor', methods=['POST'])
def add_vendor():
    try:
        data = request.json  # Ganti request.form dengan request.json
        # Validasi kolom wajib
        required_fields = ['namavendor', 'notele', 'namabank', 'norek', 'namaakunbank', 'kategori', 'username', 'catatan']
        if not all(data.get(field) for field in required_fields):
            return jsonify({'error': 'Semua kolom harus diisi!'}), 400
        # Tambahkan ke database
        vendor = Vendor(
            namavendor=data.get('namavendor'),
            notele=data.get('notele'),
            namabank=data.get('namabank'),
            norek=int(data.get('norek')),
            namaakunbank=data.get('namaakunbank'),
            username=data.get('username'),
            kategori=data.get('kategori'),
            catatan=data.get('catatan')
        )
        try :
            db.session.add(vendor)
            db.session.commit()
        except SQLAlchemyError as e:
            error = str(e)
            print(f"Error detail: {error}")
            db.session.rollback()
            return {"error": "Gagal menambahkan barang: " + error}, 500

        return jsonify({'message': 'Data berhasil ditambahkan!'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

#tampil data vendor pilihan
@app.route('/api/get_update_vendor', methods=['GET','POST'])
def get_update_vendor():
    username = request.args.get('username')
    namavendor = request.args.get('namavendor')
    
    # Validasi input
    if not username or not namavendor:
        return jsonify({"error": "Username and Vendor name are required"}), 400

    # Query database
    vendor = Vendor.query.filter_by(username=username, namavendor=namavendor).first()
    print(vendor.namabank)

    if vendor:
        return jsonify(
            {
                "namavendor": vendor.namavendor,
                "notele": vendor.notele,
                "namabank": vendor.namabank,
                "norek": vendor.norek,
                "namaakunbank": vendor.namaakunbank,
                "kategori": vendor.kategori,
                "username": vendor.username,
                "catatan": vendor.catatan,
            }
        )
    else:
        return jsonify({"error": "Vendor not found"}), 404


#update data vendor
@app.route('/api/update_vendor', methods=['PUT'])
def update_vendor():
    try:
        # Ambil data dari query string
        username = request.args.get('username')
        namavendor = request.args.get('namavendor')  # Nama vendor lama

        # Ambil data dari body JSON
        data = request.json
        new_namavendor = data.get('nama_vendor')

        # Validasi input wajib
        if not username or not namavendor:
            return jsonify({'error': 'Username dan Nama Vendor harus diisi!'}), 400

        # Cari vendor berdasarkan username dan nama vendor
        vendor = Vendor.query.filter_by(username=username, namavendor=namavendor).first()
        if not vendor:
            return jsonify({'message': 'Vendor tidak ditemukan'}), 404

        # Update nama vendor jika nama baru diberikan
        if new_namavendor:
            vendor.namavendor = new_namavendor

        # Update data lainnya jika disediakan
        vendor.notele = data.get('notele', vendor.notele)
        vendor.namabank = data.get('namabank', vendor.namabank)
        vendor.norek = int(data.get('norek', vendor.norek)) if data.get('norek') else vendor.norek
        vendor.namaakunbank = data.get('namaakunbank', vendor.namaakunbank)
        vendor.kategori = data.get('kategori', vendor.kategori)
        vendor.catatan = data.get('catatan', vendor.catatan)

        # Simpan perubahan ke database
        db.session.commit()

        return jsonify({'message': 'Data vendor berhasil diperbarui'}), 200

    except ValueError:
        return jsonify({'error': 'Format data tidak valid!'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@app.route('/api/delete_vendor', methods=['DELETE'])
def delete_vendor():
    try:
        # Ambil parameter
        namavendor = request.args.get('namavendor')
        username = request.args.get('username')
        
        # Query database
        vendor = Vendor.query.filter_by(username=username, namavendor=namavendor).first()
        # Menghapus produk
        db.session.delete(vendor)
        db.session.commit()

        return jsonify({"message": f"Product {namavendor} has been deleted"}), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


#tampil seluruh data pembeli
@app.route('/api/get_pembeli', methods=['GET','POST'])
def get_pembeli():
    username = request.args.get('username')
    print(username)
    if not username:
        return jsonify({"error": "Username is required"}), 400

    pembeli_list = Pembeli.query.filter_by(username=username).all()
    print(pembeli_list)
    if pembeli_list:
        result = [
            {"namapembeli": pembeli.namapembeli,
             "notelepon": pembeli.notele,
             "alamat": pembeli.alamat,
             'catatan': pembeli.catatan}
            for pembeli in pembeli_list
        ]
        print(result)
        return jsonify(result), 200
    else:
        return jsonify({"error": "No items found"}), 404
    
#tambah data pembeli
@app.route('/api/add_pembeli', methods=['POST'])
def add_pembeli():
    data = request.json
    try:
        namapembeli = data['namapembeli']
        notele = data['notele']
        alamat = data['alamat']
        catatan = data['catatan']
        username = data['username']

        # Validasi data
        if not all([namapembeli, notele, alamat, username, catatan]):
            return jsonify({'error': 'Semua kolom harus diisi!'}), 400

        # Tambahkan ke database
        pembeli = Pembeli(
            namapembeli=namapembeli,
            notele=notele,
            alamat=alamat,
            username=username,
            catatan=catatan
        )
        try:
            db.session.add(pembeli)
            db.session.commit()
        except SQLAlchemyError as e:
            error = str(e)
            print(f"Error detail: {error}")
            db.session.rollback()
            return {"error": "Gagal menambahkan barang: " + error}, 500

        return jsonify({'message': 'Data berhasil ditambahkan!'}), 200

    except KeyError as e:
        return jsonify({'error': f'Field {e} tidak ditemukan dalam permintaan'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

#tampil data vendor pilihan
@app.route('/api/get_update_pembeli', methods=['GET','POST'])
def get_update_pembeli():
    username = request.args.get('username')
    namapembeli = request.args.get('namapembeli')
    
    # Validasi input
    if not username or not namapembeli:
        return jsonify({"error": "Username and Vendor name are required"}), 400

    # Query database
    pembeli = Pembeli.query.filter_by(username=username, namapembeli=namapembeli).first()
    print(pembeli.namapembeli)

    if pembeli:
        return jsonify(
            {
                "namapembeli": pembeli.namapembeli,
                "notele": pembeli.notele,
                "alamat": pembeli.alamat,
                "username": pembeli.username,
                "catatan": pembeli.catatan,
            }
        )
    else:
        return jsonify({"error": "pembeli not found"}), 404


#update data pembeli
@app.route('/api/update_pembeli', methods=['PUT'])
def update_pembeli():
    try:
        # Ambil data dari query string
        username = request.args.get('username')
        namapembeli = request.args.get('namapembeli')  # Nama vendor lama

        # Ambil data dari body JSON
        data = request.json
        new_namapembeli = data.get('nama_pembeli')  # Nama vendor baru

        # Validasi input wajib
        if not username or not namapembeli:
            return jsonify({'error': 'Username dan Nama Vendor harus diisi!'}), 400

        # Cari vendor berdasarkan username dan nama vendor
        pembeli = Pembeli.query.filter_by(username=username, namapembeli=namapembeli).first()
        if not pembeli:
            return jsonify({'message': 'Pembeli tidak ditemukan'}), 404

        # Update nama vendor jika nama baru diberikan
        if new_namapembeli:
            pembeli.namapembeli = new_namapembeli

        # Update data lainnya jika disediakan
        pembeli.notele = data.get('notele', pembeli.notele)
        pembeli.alamat = data.get('alamat', pembeli.alamat)
        pembeli.catatan = data.get('catatan', pembeli.catatan)

        # Simpan perubahan ke database
        db.session.commit()

        return jsonify({'message': 'Data vendor berhasil diperbarui'}), 200

    except ValueError:
        return jsonify({'error': 'Format data tidak valid!'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@app.route('/api/delete_pembeli', methods=['DELETE'])
def delete_pembeli():
    try:
        # Ambil parameter
        namapembeli = request.args.get('namapembeli')
        username = request.args.get('username')
        
        # Query database
        pembeli = Pembeli.query.filter_by(username=username, namapembeli=namapembeli).first()
        # Menghapus produk
        db.session.delete(pembeli)
        db.session.commit()

        return jsonify({"message": f"Product {namapembeli} has been deleted"}), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5002)