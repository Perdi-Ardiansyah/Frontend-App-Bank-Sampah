import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/transaksi_model.dart';
import '../models/produk_model.dart';

// ── Model khusus Admin ────────────────────────────────────────────────────────
class DashboardAdminModel {
  final int totalNasabah;
  final int nasabahHariIni;
  final int totalPoinBeredar;
  final int menungguVerifikasi;
  final double totalSampahKg;
  final int setoranHariIniKg;
  final int setoranHariIniTransaksi;
  final int poinDiberikanHariIni;
  final List<dynamic> grafikMingguan;
  
  // 👇 INI 3 VARIABEL BARU UNTUK MENAMPUNG DETAIL TABEL 👇
  final List<List<String>> detailNasabah;
  final List<List<String>> detailPoin;
  final List<List<String>> detailSampah;

  const DashboardAdminModel({
    required this.totalNasabah,
    required this.nasabahHariIni,
    required this.totalPoinBeredar,
    required this.menungguVerifikasi,
    required this.totalSampahKg,
    required this.setoranHariIniKg,
    required this.setoranHariIniTransaksi,
    required this.poinDiberikanHariIni,
    this.grafikMingguan = const [],
    
    // Default array kosong agar tidak error walau backend belum ngirim
    this.detailNasabah = const [],
    this.detailPoin = const [],
    this.detailSampah = const [],
  });

  factory DashboardAdminModel.fromJson(Map<String, dynamic> json) {
    try {
      print('💡 CEK ISI NASABAH DARI LARAVEL: ${json['detail_nasabah']}');
      final hari = json['setoran_hari_ini'] as Map<String, dynamic>? ?? {};
      
      // 👇 FUNGSI PINTAR UNTUK MENGUBAH DATA JSON MENJADI LIST BERSARANG 👇
      List<List<String>> parseList(String key) {
        if (json[key] == null) return [];
        return (json[key] as List).map((row) {
          return (row as List).map((cell) => cell.toString()).toList();
        }).toList();
      }

      return DashboardAdminModel(
        // Bagian atas tetap sama seperti milik Anda
        totalNasabah:             int.tryParse(json['total_nasabah']?.toString() ?? '0') ?? 0,
        nasabahHariIni:           int.tryParse(json['nasabah_hari_ini']?.toString() ?? '0') ?? 0,
        totalPoinBeredar:         int.tryParse(json['total_poin_beredar']?.toString() ?? '0') ?? 0,
        menungguVerifikasi:       int.tryParse(json['menunggu_verifikasi']?.toString() ?? '0') ?? 0,
        totalSampahKg:            double.tryParse(json['total_sampah_kg']?.toString() ?? '0') ?? 0.0,
        setoranHariIniKg:         (double.tryParse(hari['total_kg']?.toString() ?? '0') ?? 0).toInt(),
        setoranHariIniTransaksi:  int.tryParse(hari['total_transaksi']?.toString() ?? '0') ?? 0,
        poinDiberikanHariIni:     int.tryParse(hari['poin_diberikan']?.toString() ?? '0') ?? 0,
        grafikMingguan:           json['grafik_mingguan'] != null 
                                      ? List<dynamic>.from(json['grafik_mingguan']) 
                                      : [],
                                      
        // 👇 TANGKAP DATANYA DI SINI MENGGUNAKAN FUNGSI PINTAR TADI 👇
        detailNasabah: parseList('detail_nasabah'),
        detailPoin: parseList('detail_poin'),
        detailSampah: parseList('detail_sampah'),
      );
    } catch (e) {
      print('🚨 CRASH SAAT PARSING JSON: $e');
      rethrow;
    }
  }

  String get totalNasabahFormatted => _fmt(totalNasabah);
  String get totalPoinBeredarFormatted => _fmt(totalPoinBeredar);
  String get totalSampahKgFormatted => '${totalSampahKg.toStringAsFixed(0)} kg';

  static String _fmt(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final r = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) r.write(',');
      r.write(s[i]);
    }
    return r.toString();
  }
}
// 👈 Tambahkan ini

class NasabahPendingModel {
  final int id;
  final String namaLengkap;
  final String email;
  final String username;
  final String idNasabah;
  final String tanggalDaftar;
  final String tipeNasabah;
  final String lokasiArea;

  const NasabahPendingModel({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.username,
    required this.idNasabah,
    required this.tanggalDaftar,
    required this.tipeNasabah,
    required this.lokasiArea,
  });

  factory NasabahPendingModel.fromJson(Map<String, dynamic> json) {
    return NasabahPendingModel(
      id:            json['id'] as int,
      namaLengkap:   json['nama_lengkap'] as String,
      email:         json['email'] as String,
      username:      json['username'] as String,
      idNasabah:     json['id_nasabah'] as String? ?? '-',
      tanggalDaftar: json['tanggal_daftar'] as String? ?? '-',
      tipeNasabah:   json['tipe_nasabah'] as String? ?? 'Individu',
      lokasiArea:    json['lokasi_area'] as String? ?? '-',
    );
  }

  String get initials {
    final parts = namaLengkap.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return namaLengkap.substring(0, 2).toUpperCase();
  }
}

class PencairanAdminModel {
  final int id;
  final String namaNasabah;
  final String idNasabah;
  final int nominal;
  final String status;
  final String? metodeCash;
  final String? noRekening;
  final String tanggal;

  const PencairanAdminModel({
    required this.id,
    required this.namaNasabah,
    required this.idNasabah,
    required this.nominal,
    required this.status,
    this.metodeCash,
    this.noRekening,
    required this.tanggal,
  });

  factory PencairanAdminModel.fromJson(Map<String, dynamic> json) {
    return PencairanAdminModel(
      id:          json['id'] as int,
      namaNasabah: json['nama_nasabah'] as String,
      idNasabah:   json['id_nasabah'] as String? ?? '-',
      nominal:     json['nominal'] as int,
      status:      json['status'] as String,
      metodeCash:  json['metode_cash'] as String?,
      noRekening:  json['no_rekening'] as String?,
      tanggal:     json['tanggal'] as String,
    );
  }

  String get nominalFormatted {
    final s = nominal.toString();
    if (s.length <= 3) return 'Rp $s';
    final r = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) r.write('.');
      r.write(s[i]);
    }
    return 'Rp $r';
  }

  String get initials {
    final parts = namaNasabah.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return namaNasabah.substring(0, 2).toUpperCase();
  }
}

class LaporanAdminModel {
  final int totalTransaksi;
  final double volumeKg;
  final int nilaiKonversi;
  final List<Map<String, dynamic>> transaksi;
  final int currentPage;
  final int lastPage;

  const LaporanAdminModel({
    required this.totalTransaksi,
    required this.volumeKg,
    required this.nilaiKonversi,
    required this.transaksi,
    required this.currentPage,
    required this.lastPage,
  });

  factory LaporanAdminModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return LaporanAdminModel(
      totalTransaksi: stats['total_transaksi'] as int? ?? 0,
      volumeKg:       (stats['volume_kg'] as num?)?.toDouble() ?? 0,
      nilaiKonversi:  stats['nilai_konversi'] as int? ?? 0,
      transaksi:      (json['data'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      currentPage:    json['current_page'] as int? ?? 1,
      lastPage:       json['last_page'] as int? ?? 1,
    );
  }
}

class LogAktivitasModel {
  final String id;
  final String admin;
  final String aksi;
  final String waktu;
  final String tanggal;
  final String tipe;

  const LogAktivitasModel({
    required this.id,
    required this.admin,
    required this.aksi,
    required this.waktu,
    required this.tanggal,
    required this.tipe,
  });

  factory LogAktivitasModel.fromJson(Map<String, dynamic> json) {
    return LogAktivitasModel(
      id:      json['id'] as String,
      admin:   json['admin'] as String,
      aksi:    json['aksi'] as String,
      waktu:   json['waktu'] as String,
      tanggal: json['tanggal'] as String,
      tipe:    json['tipe'] as String? ?? 'sistem',
    );
  }
}

// ── AdminService ──────────────────────────────────────────────────────────────

class AdminService {
  final Dio _dio = ApiClient.instance;

  // ── Dashboard ──────────────────────────────────────────────────────────────
  Future<DashboardAdminModel> getDashboard() async {
    final res = await _dio.get('/admin/dashboard');
    // Langsung tembak ke Model, tidak perlu diubah-ubah lagi
    return DashboardAdminModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Setoran ────────────────────────────────────────────────────────────────
  Future<({bool success, String message, int? poinDiberikan})> simpanSetoran({
    required int userId,
    required int kategoriId,
    required double beratKg,
    String? lokasiTps,
    String? catatan,
  }) async {
    try {
      final res = await _dio.post('/admin/setoran', data: {
        'user_id':     userId,
        'kategori_id': kategoriId,
        'berat_kg':    beratKg,
        'lokasi_tps':  lokasiTps,
        'catatan':     catatan,
      });
      final data = res.data as Map<String, dynamic>;
      return (
      success:       true,
      message:       data['message'] as String? ?? 'Berhasil.',
      poinDiberikan: data['poin_diberikan'] as int?,
      );
    } on DioException catch (e) {
      return (success: false, message: _parseError(e), poinDiberikan: null);
    }
  }

  // ── Verifikasi Nasabah ─────────────────────────────────────────────────────
  Future<({List<NasabahPendingModel> data, int totalPending})>
  getNasabahPending() async {
    final res  = await _dio.get('/admin/nasabah-pending');
    final json = res.data as Map<String, dynamic>;
    final list = (json['data'] as List<dynamic>)
        .map((e) => NasabahPendingModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (data: list, totalPending: json['total_pending'] as int? ?? 0);
  }

  Future<({bool success, String message})> aktifkanNasabah(int id) async {
    try {
      final res  = await _dio.post('/admin/nasabah/$id/aktifkan');
      final data = res.data as Map<String, dynamic>;
      return (success: true, message: data['message'] as String? ?? 'Berhasil.');
    } on DioException catch (e) {
      return (success: false, message: _parseError(e));
    }
  }

  // ── Pencairan ──────────────────────────────────────────────────────────────
  Future<({List<PencairanAdminModel> data, int totalTertunda, int lastPage})>
  getPencairan() async {
    final res  = await _dio.get('/admin/pencairan');
    final json = res.data as Map<String, dynamic>;
    final list = (json['data'] as List<dynamic>)
        .map((e) => PencairanAdminModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
    data:          list,
    totalTertunda: json['total_tertunda'] as int? ?? 0,
    lastPage:      json['last_page'] as int? ?? 1,
    );
  }

  Future<({bool success, String message})> selesaikanPencairan(int id) async {
    try {
      final res = await _dio.post('/admin/pencairan/$id/selesai');
      return (success: true, message: (res.data as Map)['message'] as String? ?? 'Berhasil.');
    } on DioException catch (e) {
      return (success: false, message: _parseError(e));
    }
  }

  Future<({bool success, String message})> tolakPencairan(int id) async {
    try {
      final res = await _dio.post('/admin/pencairan/$id/tolak');
      return (success: true, message: (res.data as Map)['message'] as String? ?? 'Berhasil.');
    } on DioException catch (e) {
      return (success: false, message: _parseError(e));
    }
  }

  // ── Laporan ────────────────────────────────────────────────────────────────
  Future<LaporanAdminModel> getLaporan({
    String? dari,
    String? sampai,
    int page = 1,
  }) async {
    final res = await _dio.get('/admin/laporan', queryParameters: {
      if (dari   != null) 'dari':   dari,
      if (sampai != null) 'sampai': sampai,
      'page': page,
    });
    return LaporanAdminModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Log Aktivitas ──────────────────────────────────────────────────────────
  Future<List<LogAktivitasModel>> getLogAktivitas() async {
    final res  = await _dio.get('/admin/log-aktivitas');
    final list = (res.data['data'] as List<dynamic>)
        .map((e) => LogAktivitasModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  // ── Kategori ───────────────────────────────────────────────────────────────
  Future<List<KategoriModel>> getKategori() async {
    final res  = await _dio.get('/kategori');
    final list = (res.data as List<dynamic>)
        .map((e) => KategoriModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<({bool success, String message})> tambahKategori({
    required String nama,
    required String deskripsi,
    required int poinPerKg,
    String? iconName,
  }) async {
    try {
      await _dio.post('/admin/kategori', data: {
        'nama':        nama,
        'deskripsi':   deskripsi,
        'poin_per_kg': poinPerKg,
        'icon_name':   iconName,
      });
      return (success: true, message: 'Kategori berhasil ditambahkan.');
    } on DioException catch (e) {
      return (success: false, message: _parseError(e));
    }
  }

  Future<({bool success, String message})> updateKategori({
    required int id,
    required String nama,
    required String deskripsi,
    required int poinPerKg,
    String? iconName,
  }) async {
    try {
      await _dio.put('/admin/kategori/$id', data: {
        'nama':        nama,
        'deskripsi':   deskripsi,
        'poin_per_kg': poinPerKg,
        'icon_name':   iconName,
      });
      return (success: true, message: 'Kategori berhasil diperbarui.');
    } on DioException catch (e) {
      return (success: false, message: _parseError(e));
    }
  }

  Future<({bool success, String message})> toggleKategori(int id) async {
    try {
      final res = await _dio.patch('/admin/kategori/$id/toggle');
      return (success: true, message: (res.data as Map)['message'] as String? ?? 'Berhasil.');
    } on DioException catch (e) {
      return (success: false, message: _parseError(e));
    }
  }

  // ── Produk ─────────────────────────────────────────────────────────────────
  Future<List<ProdukModel>> getProduk() async {
    final res  = await _dio.get('/produk');
    final list = (res.data as List<dynamic>)
        .map((e) => ProdukModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<({bool success, String message})> tambahProduk({
    required String nama,
    required String deskripsi,
    required int biayaPoin,
    required int stok,
    String? fotoUrl,
  }) async {
    try {
      await _dio.post('/admin/produk', data: {
        'nama':       nama,
        'deskripsi':  deskripsi,
        'biaya_poin': biayaPoin,
        'stok':       stok,
        'foto_url':   fotoUrl,
      });
      return (success: true, message: 'Produk berhasil ditambahkan.');
    } on DioException catch (e) {
      return (success: false, message: _parseError(e));
    }
  }

  Future<({bool success, String message})> updateProduk({
    required int id,
    required String nama,
    required String deskripsi,
    required int biayaPoin,
    required int stok,
    String? fotoUrl,
  }) async {
    try {
      await _dio.put('/admin/produk/$id', data: {
        'nama':       nama,
        'deskripsi':  deskripsi,
        'biaya_poin': biayaPoin,
        'stok':       stok,
        'foto_url':   fotoUrl,
      });
      return (success: true, message: 'Produk berhasil diperbarui.');
    } on DioException catch (e) {
      return (success: false, message: _parseError(e));
    }
  }

  Future<({bool success, String message})> toggleProduk(int id) async {
    try {
      final res = await _dio.patch('/admin/produk/$id/toggle');
      return (success: true, message: (res.data as Map)['message'] as String? ?? 'Berhasil.');
    } on DioException catch (e) {
      return (success: false, message: _parseError(e));
    }
  }

  // ── Daftar Nasabah Aktif ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getNasabahAktif() async {
    final res = await _dio.get('/admin/nasabah-aktif');
    return List<Map<String, dynamic>>.from(res.data);
  }

  // ── Helper ─────────────────────────────────────────────────────────────────
  String _parseError(DioException e) {
    try {
      final data = e.response?.data as Map<String, dynamic>?;
      if (data == null) return 'Terjadi kesalahan. Coba lagi.';
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        return (errors.values.first as List).first as String;
      }
      return data['message'] as String? ?? 'Terjadi kesalahan. Coba lagi.';
    } catch (_) {
      return 'Terjadi kesalahan. Coba lagi.';
    }
  }
}