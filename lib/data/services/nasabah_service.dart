import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/transaksi_model.dart';
import '../models/produk_model.dart';
import '../models/notifikasi_model.dart';

class NasabahService {
  final Dio _dio = ApiClient.instance;

  // ── Dashboard ──────────────────────────────────────────────────────────────

  /// Ambil total poin + 3 transaksi terakhir untuk HomeScreen
  /// GET /api/nasabah/dashboard
  Future<({int totalPoin, List<dynamic> transaksiTerakhir})>
  getDashboard() async {
    final res = await _dio.get('/nasabah/dashboard');
    final data = res.data as Map<String, dynamic>;
    return (
      totalPoin: data['total_poin'] as int,
      transaksiTerakhir: data['transaksi_terakhir'] as List<dynamic>,
    );
  }

  // ── Katalog Harga ──────────────────────────────────────────────────────────

  /// Ambil daftar kategori sampah aktif
  /// GET /api/kategori
  Future<List<KategoriModel>> getKategori() async {
    final res = await _dio.get('/kategori');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => KategoriModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Riwayat ────────────────────────────────────────────────────────────────

  /// Ambil riwayat setoran dengan pagination & filter bulan
  /// GET /api/nasabah/riwayat-setoran?bulan=10&tahun=2023&page=1
  Future<
    ({List<SetoranModel> data, int totalPoin, int poinBulanIni, int lastPage})
  >
  getRiwayatSetoran({int page = 1, int? bulan, int? tahun}) async {
    final res = await _dio.get(
      '/nasabah/riwayat-setoran',
      queryParameters: {
        'page': page,
        if (bulan != null) 'bulan': bulan,
        if (tahun != null) 'tahun': tahun,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => SetoranModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      data: items,
      totalPoin: int.tryParse(data['total_poin']?.toString() ?? '0') ?? 0,
      poinBulanIni:
          int.tryParse(data['poin_bulan_ini']?.toString() ?? '0') ?? 0,
      lastPage: int.tryParse(data['last_page']?.toString() ?? '1') ?? 1,
    );
  }

  /// Ambil riwayat penukaran dengan pagination & filter bulan
  /// GET /api/nasabah/riwayat-penukaran?bulan=10&tahun=2023&page=1
  Future<({List<PenukaranModel> data, int lastPage})> getRiwayatPenukaran({
    int page = 1,
    int? bulan,
    int? tahun,
  }) async {
    final res = await _dio.get(
      '/nasabah/riwayat-penukaran',
      queryParameters: {
        'page': page,
        if (bulan != null) 'bulan': bulan,
        if (tahun != null) 'tahun': tahun,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => PenukaranModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      data: items,
      lastPage: int.tryParse(data['last_page']?.toString() ?? '1') ?? 1,
    );
  }

  // ── Tukar Poin ─────────────────────────────────────────────────────────────

  /// Ambil daftar produk aktif untuk halaman Tukar
  /// GET /api/produk
  Future<List<ProdukModel>> getProduk() async {
    final res = await _dio.get('/produk');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ProdukModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Tukar poin dengan produk (sembako)
  /// POST /api/nasabah/tukar-produk
  /// Body: { "produk_id": 1, "jumlah": 2 }
  Future<({bool success, String message, int? sisaPoin})> tukarProduk({
    required int produkId,
    required int jumlah,
  }) async {
    try {
      final res = await _dio.post(
        '/nasabah/tukar-produk',
        data: {'produk_id': produkId, 'jumlah': jumlah},
      );
      final data = res.data as Map<String, dynamic>;
      return (
        success: true,
        message: data['message'] as String? ?? 'Penukaran berhasil.',
        sisaPoin: data['sisa_poin'] as int?,
      );
    } on DioException catch (e) {
      final msg = _parseError(e);
      return (success: false, message: msg, sisaPoin: null);
    }
  }

  /// Tukar poin menjadi uang tunai (cash)
  /// POST /api/nasabah/tukar-cash
  /// Body: { "nominal": 50000 }
  /// Tukar poin menjadi uang tunai (cash/transfer)
  /// POST /api/nasabah/tukar-cash
  Future<({bool success, String message, int? sisaPoin})> tukarCash({
    required int nominal,
    required String metode, // 'Cash' atau 'Transfer'
    String? tipeTransfer, // 'Bank' atau 'e-Wallet'
    String? namaBankEwallet, // Contoh: 'BCA', 'Dana', 'Gopay'
    String? nomorRekening, // Nomor rekening atau nomor HP
  }) async {
    try {
      final res = await _dio.post(
        '/nasabah/tukar-cash',
        data: {
          'nominal': nominal,
          'metode': metode,
          'tipe_transfer': tipeTransfer,
          'nama_bank_ewallet': namaBankEwallet,
          'nomor_rekening': nomorRekening,
        },
      );
      final data = res.data as Map<String, dynamic>;
      return (
        success: true,
        message: data['message'] as String? ?? 'Permintaan pencairan dikirim.',
        sisaPoin: data['sisa_poin'] as int?,
      );
    } on DioException catch (e) {
      return (success: false, message: _parseError(e), sisaPoin: null);
    }
  }

  // ── Notifikasi ─────────────────────────────────────────────────────────────

  /// Ambil daftar notifikasi
  /// GET /api/nasabah/notifikasi
  Future<({List<NotifikasiModel> data, int unreadCount})>
  getNotifikasi() async {
    final res = await _dio.get('/nasabah/notifikasi');

    final data = res.data as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => NotifikasiModel.fromJson(e as Map<String, dynamic>))
        .toList();
    print('=== CEK API NOTIFIKASI ===');
    print('Status Code: ${res.statusCode}');
    print('Response Data: ${res.data}');
    print('==========================');
    return (data: items, unreadCount: data['unread_count'] as int? ?? 0);
  }

  /// Tandai semua notifikasi sebagai sudah dibaca
  /// POST /api/nasabah/notifikasi/read-all
  Future<void> markAllNotifikasiRead() async {
    await _dio.post('/nasabah/notifikasi/read-all');
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
