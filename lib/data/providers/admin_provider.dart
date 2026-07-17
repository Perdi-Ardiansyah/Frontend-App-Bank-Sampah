import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/admin_service.dart';
import '../../data/models/produk_model.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import 'dart:io';

// ── Service Provider ───────────────────────────────────────────────────────
final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

// ══════════════════════════════════════════════════════════════════════════════
// DASHBOARD ADMIN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
class DashboardAdminState {
  final bool isLoading;
  final DashboardAdminModel? data;
  final String? error;

  const DashboardAdminState({this.isLoading = false, this.data, this.error});

  DashboardAdminState copyWith({
    bool? isLoading,
    DashboardAdminModel? data,
    String? error,
  }) => DashboardAdminState(
    isLoading: isLoading ?? this.isLoading,
    data: data ?? this.data,
    error: error,
  );
}

class DashboardAdminNotifier extends StateNotifier<DashboardAdminState> {
  final AdminService _service;

  DashboardAdminNotifier(this._service) : super(const DashboardAdminState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _service.getDashboard();
      state = state.copyWith(isLoading: false, data: data);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat dashboard.',
      );
    }
  }
}

final dashboardAdminProvider =
    StateNotifierProvider<DashboardAdminNotifier, DashboardAdminState>((ref) {
      return DashboardAdminNotifier(ref.read(adminServiceProvider));
    });

// ══════════════════════════════════════════════════════════════════════════════
// SETORAN ADMIN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
class SetoranAdminState {
  final bool isLoading;
  final bool isSubmitting;
  final List<KategoriModel> kategoriList;
  final String? error;
  final String? successMessage;

  const SetoranAdminState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.kategoriList = const [],
    this.error,
    this.successMessage,
  });

  SetoranAdminState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<KategoriModel>? kategoriList,
    String? error,
    String? successMessage,
  }) => SetoranAdminState(
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    kategoriList: kategoriList ?? this.kategoriList,
    error: error,
    successMessage: successMessage,
  );
}

class SetoranAdminNotifier extends StateNotifier<SetoranAdminState> {
  final AdminService _service;

  SetoranAdminNotifier(this._service) : super(const SetoranAdminState()) {
    fetchKategori();
  }

  Future<void> fetchKategori() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _service.getKategori();
      state = state.copyWith(isLoading: false, kategoriList: list);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat kategori.');
    }
  }

  Future<bool> simpanSetoran({
    required int userId,
    required int kategoriId,
    required double beratKg,
    String? lokasiTps,
    String? catatan,
  }) async {
    state = state.copyWith(isSubmitting: true);
    final result = await _service.simpanSetoran(
      userId: userId,
      kategoriId: kategoriId,
      beratKg: beratKg,
      lokasiTps: lokasiTps,
      catatan: catatan,
    );
    state = result.success
        ? state.copyWith(isSubmitting: false, successMessage: result.message)
        : state.copyWith(isSubmitting: false, error: result.message);
    return result.success;
  }
}

final setoranAdminProvider =
    StateNotifierProvider<SetoranAdminNotifier, SetoranAdminState>((ref) {
      return SetoranAdminNotifier(ref.read(adminServiceProvider));
    });

// ══════════════════════════════════════════════════════════════════════════════
// VERIFIKASI NASABAH PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

// Model sederhana untuk menampung data Nasabah dari API
class NasabahPendingModel {
  final int id;
  final String namaLengkap;
  final String email;
  final String tanggalDaftar;
  final String tipeNasabah;
  final String lokasiArea;

  NasabahPendingModel({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.tanggalDaftar,
    required this.tipeNasabah,
    required this.lokasiArea,
  });

  // Getter untuk mengambil inisial nama (contoh: "Budi Santoso" -> "BS")
  String get initials {
    if (namaLengkap.isEmpty) return '?';
    List<String> words = namaLengkap.trim().split(' ');
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return (words[0].substring(0, 1) + words[words.length - 1].substring(0, 1))
        .toUpperCase();
  }

  factory NasabahPendingModel.fromJson(Map<String, dynamic> json) {
    return NasabahPendingModel(
      id: json['id'] ?? 0,
      namaLengkap: json['nama_lengkap'] ?? 'Tanpa Nama',
      email: json['email'] ?? '-',
      // Memotong string waktu (contoh: "2026-06-04 10:00:00" -> "2026-06-04")
      tanggalDaftar: json['created_at'] != null
          ? json['created_at'].toString().split('T')[0]
          : '-',
      tipeNasabah: json['tipe_nasabah'] ?? 'Personal',
      lokasiArea: json['lokasi'] ?? '-',
    );
  }
}

class VerifikasiState {
  final bool isLoading;
  final bool isSubmitting;
  final List<NasabahPendingModel> data;
  final int totalPending;
  final String? error;

  const VerifikasiState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.data = const [],
    this.totalPending = 0,
    this.error,
  });

  VerifikasiState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<NasabahPendingModel>? data,
    int? totalPending,
    String? error,
  }) {
    return VerifikasiState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      data: data ?? this.data,
      totalPending: totalPending ?? this.totalPending,
      error: error,
    );
  }
}

class VerifikasiNotifier extends StateNotifier<VerifikasiState> {
  final AdminService _service;

  VerifikasiNotifier(this._service) : super(const VerifikasiState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Menggunakan ApiClient bawaan Anda untuk menembak endpoint nasabah-pending
      final res = await ApiClient.instance.get('/admin/nasabah-pending');

      // Ambil data array-nya
      List<dynamic> rawData = [];
      if (res.data is List) {
        rawData = res.data;
      } else if (res.data is Map && res.data.containsKey('data')) {
        rawData = res.data['data'];
      } else if (res.data is Map) {
        rawData = res.data.values.toList();
      }

      final list = rawData.map((e) => NasabahPendingModel.fromJson(e)).toList();

      state = state.copyWith(
        isLoading: false,
        data: list,
        totalPending: list.length,
      );
    } catch (e) {
      print('🚨 ERROR FETCH PENDING NASABAH: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data nasabah pending.',
      );
    }
  }

  Future<bool> aktifkan(int id) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await ApiClient.instance.post('/admin/nasabah/$id/aktifkan');
      await fetch(); // Refresh daftar setelah berhasil
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      print('🚨 ERROR AKTIFKAN NASABAH: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Gagal mengaktifkan nasabah.',
      );
      return false;
    }
  }
}

final verifikasiProvider =
    StateNotifierProvider<VerifikasiNotifier, VerifikasiState>((ref) {
      return VerifikasiNotifier(ref.read(adminServiceProvider));
    });

// ══════════════════════════════════════════════════════════════════════════════
// PENCAIRAN ADMIN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class PencairanAdminModel {
  final int id;
  final String namaNasabah;
  final String tanggal;
  final String status;
  final int nominal;
  final String? metodeCash;
  final String? noRekening;
  final String? catatan; // 👈 Tambahkan variabel catatan

  PencairanAdminModel({
    required this.id,
    required this.namaNasabah,
    required this.tanggal,
    required this.status,
    required this.nominal,
    this.metodeCash,
    this.noRekening,
    this.catatan, // 👈 Masukkan ke constructor
  });

  String get initials {
    if (namaNasabah.isEmpty) return '?';
    List<String> words = namaNasabah.trim().split(' ');
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return (words[0].substring(0, 1) + words[words.length - 1].substring(0, 1))
        .toUpperCase();
  }

  String get nominalFormatted {
    final s = nominal.toString();
    String result = '';
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result = '.$result';
      result = s[i] + result;
      count++;
    }
    return 'Rp $result';
  }

  factory PencairanAdminModel.fromJson(Map<String, dynamic> json) {
    print('Intip Data API Admin: Catatan = ${json['catatan']}');
    return PencairanAdminModel(
      id: json['id'] ?? 0,
      namaNasabah:
          json['nasabah']?['nama_lengkap'] ??
          json['nama_nasabah'] ??
          'Tanpa Nama',
      tanggal: json['created_at'] != null
          ? json['created_at'].toString().split('T')[0]
          : '-',
      status: json['status'] ?? 'pending',
      nominal:
          int.tryParse(
            json['nominal']?.toString() ?? json['jumlah']?.toString() ?? '0',
          ) ??
          0,
      metodeCash: json['metode'] ?? json['metode_pencairan'],
      noRekening: json['no_rekening'] ?? json['rekening'],
      catatan:
          json['catatan'] as String?, // 👈 Ambil data catatan dari API Laravel
    );
  }
}

class PencairanAdminState {
  final bool isLoading;
  final bool isSubmitting;
  final int processingId;
  final List<PencairanAdminModel> data;
  final String? error;

  const PencairanAdminState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.processingId = 0,
    this.data = const [],
    this.error,
  });

  // Menghitung otomatis total nominal yang statusnya masih 'pending'
  String get totalTertundaFormatted {
    final total = data
        .where((e) => e.status == 'pending')
        .fold(0, (sum, item) => sum + item.nominal);
    final s = total.toString();
    String result = '';
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result = '.$result';
      result = s[i] + result;
      count++;
    }
    return 'Rp $result';
  }

  PencairanAdminState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    int? processingId,
    List<PencairanAdminModel>? data,
    String? error,
  }) {
    return PencairanAdminState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      processingId: processingId ?? this.processingId,
      data: data ?? this.data,
      error: error,
    );
  }
}

class PencairanAdminNotifier extends StateNotifier<PencairanAdminState> {
  PencairanAdminNotifier() : super(const PencairanAdminState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.instance.get('/admin/pencairan');

      List<dynamic> rawData = [];
      if (res.data is List)
        rawData = res.data;
      else if (res.data is Map && res.data.containsKey('data'))
        rawData = res.data['data'];
      else if (res.data is Map)
        rawData = res.data.values.toList();

      final list = rawData.map((e) => PencairanAdminModel.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, data: list);
    } catch (e) {
      print('🚨 ERROR FETCH PENCAIRAN: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data pencairan.',
      );
    }
  }

  Future<bool> selesaikan(int id) async {
    state = state.copyWith(isSubmitting: true, processingId: id, error: null);
    try {
      await ApiClient.instance.post('/admin/pencairan/$id/selesai');
      await fetch();
      state = state.copyWith(isSubmitting: false, processingId: 0);
      return true;
    } catch (e) {
      print('🚨 ERROR SELESAI PENCAIRAN: $e');
      state = state.copyWith(
        isSubmitting: false,
        processingId: 0,
        error: 'Gagal menyetujui pencairan.',
      );
      return false;
    }
  }

  Future<bool> tolak(int id) async {
    state = state.copyWith(isSubmitting: true, processingId: id, error: null);
    try {
      await ApiClient.instance.post('/admin/pencairan/$id/tolak');
      await fetch();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      print('🚨 ERROR TOLAK PENCAIRAN: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Gagal menolak pencairan.',
      );
      return false;
    }
  }
}

final pencairanAdminProvider =
    StateNotifierProvider<PencairanAdminNotifier, PencairanAdminState>((ref) {
      return PencairanAdminNotifier();
    });

// ══════════════════════════════════════════════════════════════════════════════
// LAPORAN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
class LaporanState {
  final bool isLoading;
  final LaporanAdminModel? data;
  final String dari;
  final String sampai;
  final String? error;

  LaporanState({
    this.isLoading = false,
    this.data,
    String? dari,
    String? sampai,
    this.error,
  }) : dari = dari ?? _defaultDari(),
       sampai = sampai ?? _defaultSampai();

  static String _defaultDari() =>
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-01';
  static String _defaultSampai() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-$lastDay';
  }

  LaporanState copyWith({
    bool? isLoading,
    LaporanAdminModel? data,
    String? dari,
    String? sampai,
    String? error,
  }) => LaporanState(
    isLoading: isLoading ?? this.isLoading,
    data: data ?? this.data,
    dari: dari ?? this.dari,
    sampai: sampai ?? this.sampai,
    error: error,
  );
}

class LaporanNotifier extends StateNotifier<LaporanState> {
  final AdminService _service;

  LaporanNotifier(this._service) : super(LaporanState()) {
    fetch();
  }

  Future<void> fetch({String? dari, String? sampai}) async {
    final d = dari ?? state.dari;
    final s = sampai ?? state.sampai;
    state = state.copyWith(isLoading: true, dari: d, sampai: s);
    try {
      final data = await _service.getLaporan(dari: d, sampai: s);
      state = state.copyWith(isLoading: false, data: data);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat laporan.');
    }
  }
}

final laporanProvider = StateNotifierProvider<LaporanNotifier, LaporanState>((
  ref,
) {
  return LaporanNotifier(ref.read(adminServiceProvider));
});

// ══════════════════════════════════════════════════════════════════════════════
// LOG AKTIVITAS PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
class LogAktivitasState {
  final bool isLoading;
  final List<LogAktivitasModel> data;
  final String? error;

  const LogAktivitasState({
    this.isLoading = false,
    this.data = const [],
    this.error,
  });

  LogAktivitasState copyWith({
    bool? isLoading,
    List<LogAktivitasModel>? data,
    String? error,
  }) => LogAktivitasState(
    isLoading: isLoading ?? this.isLoading,
    data: data ?? this.data,
    error: error,
  );
}

class LogAktivitasNotifier extends StateNotifier<LogAktivitasState> {
  final AdminService _service;

  LogAktivitasNotifier(this._service) : super(const LogAktivitasState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _service.getLogAktivitas();
      state = state.copyWith(isLoading: false, data: list);
    } catch (e, stacktrace) {
      // Tangkap error 'e' dan stacktrace-nya
      print('=== ERROR LOG AKTIVITAS ===');
      print(e.toString());

      // Jika pakai Dio, kita bisa lihat response dari server
      if (e is DioException) {
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
      }
      print('===========================');

      state = state.copyWith(isLoading: false, error: 'Gagal memuat log.');
    }
  }
}

final logAktivitasProvider =
    StateNotifierProvider<LogAktivitasNotifier, LogAktivitasState>((ref) {
      return LogAktivitasNotifier(ref.read(adminServiceProvider));
    });

// ══════════════════════════════════════════════════════════════════════════════
// KATEGORI ADMIN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
class KategoriAdminState {
  final bool isLoading;
  final bool isSubmitting;
  final List<Map<String, dynamic>> data;
  final String? error;

  const KategoriAdminState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.data = const [],
    this.error,
  });

  KategoriAdminState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<Map<String, dynamic>>? data,
    String? error,
  }) {
    return KategoriAdminState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      data: data ?? this.data,
      error: error, // error bisa di-null-kan
    );
  }
}

class KategoriAdminNotifier extends StateNotifier<KategoriAdminState> {
  final AdminService _service;

  KategoriAdminNotifier(this._service) : super(const KategoriAdminState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.instance.get('/kategori');

      List<dynamic> rawData = [];
      if (res.data is List) {
        rawData = res.data;
      } else if (res.data is Map) {
        // Jika Laravel mengembalikan object (associative array)
        if (res.data.containsKey('data')) {
          rawData = res.data['data'];
        } else {
          rawData = res.data.values.toList();
        }
      }

      state = state.copyWith(
        isLoading: false,
        data: List<Map<String, dynamic>>.from(rawData),
      );
    } catch (e) {
      print('🚨 ERROR FETCH KATEGORI: $e');
      state = state.copyWith(isLoading: false, error: 'Gagal memuat kategori.');
    }
  }

  Future<bool> simpanKategori({
    int? id,
    required String nama,
    required String deskripsi,
    required int poin,
    File? imageFile,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      // Menggunakan FormData karena kita akan mengirim file (gambar)
      // Ubah bagian ini di dalam fungsi simpanKategori:
      FormData formData = FormData.fromMap({
        'nama': nama, // 👈 UBAH DARI 'nama_kategori' MENJADI 'nama'
        'deskripsi': deskripsi,
        'poin_per_kg': poin,
      });

      // Jika admin memilih gambar, tambahkan ke dalam FormData
      if (imageFile != null) {
        String fileName = imageFile.path.split('/').last;
        formData.files.add(
          MapEntry(
            'foto', // PENTING: Ganti 'foto' ini jika kolom di Laravel Anda bernama 'image' atau 'gambar'
            await MultipartFile.fromFile(imageFile.path, filename: fileName),
          ),
        );
      }

      if (id == null) {
        // Tambah Kategori Baru
        await ApiClient.instance.post('/admin/kategori', data: formData);
      } else {
        // Edit Kategori (Laravel butuh _method=PUT jika menggunakan FormData)
        formData.fields.add(const MapEntry('_method', 'PUT'));
        await ApiClient.instance.post('/admin/kategori/$id', data: formData);
      }

      await fetch(); // Refresh data setelah berhasil
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      if (e is DioException) {
        // Ini akan mencetak pesan error asli dari Laravel ke Terminal
        print('🚨 ERROR VALIDASI LARAVEL: ${e.response?.data}');
      } else {
        print('🚨 ERROR SIMPAN KATEGORI: $e');
      }

      state = state.copyWith(
        isSubmitting: false,
        error: 'Gagal menyimpan. Cek terminal untuk detail error 422.',
      );
      return false;
    }
  }

  Future<bool> toggleStatus(int id) async {
    try {
      await ApiClient.instance.patch('/admin/kategori/$id/toggle');
      await fetch(); // Refresh data
      return true;
    } catch (e) {
      return false;
    }
  }
}

final kategoriAdminProvider =
    StateNotifierProvider<KategoriAdminNotifier, KategoriAdminState>((ref) {
      return KategoriAdminNotifier(ref.read(adminServiceProvider));
    });

// ══════════════════════════════════════════════════════════════════════════════
// LIST NASABAH AKTIF PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
class ListNasabahState {
  final bool isLoading;
  final List<Map<String, dynamic>> data;
  final String? error;

  const ListNasabahState({
    this.isLoading = false,
    this.data = const [],
    this.error,
  });

  ListNasabahState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? data,
    String? error,
  }) => ListNasabahState(
    isLoading: isLoading ?? this.isLoading,
    data: data ?? this.data,
    error: error,
  );
}

class ListNasabahNotifier extends StateNotifier<ListNasabahState> {
  final AdminService _service;
  ListNasabahNotifier(this._service) : super(const ListNasabahState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _service.getNasabahAktif();
      state = state.copyWith(isLoading: false, data: list);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data nasabah.',
      );
    }
  }
}

final listNasabahProvider =
    StateNotifierProvider<ListNasabahNotifier, ListNasabahState>((ref) {
      return ListNasabahNotifier(ref.read(adminServiceProvider));
    });

// ══════════════════════════════════════════════════════════════════════════════
// PRODUK ADMIN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
class ProdukAdminState {
  final bool isLoading;
  final bool isSubmitting;
  final List<Map<String, dynamic>> data;
  final String? error;

  const ProdukAdminState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.data = const [],
    this.error,
  });

  ProdukAdminState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<Map<String, dynamic>>? data,
    String? error,
  }) {
    return ProdukAdminState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      data: data ?? this.data,
      error: error,
    );
  }
}

class ProdukAdminNotifier extends StateNotifier<ProdukAdminState> {
  ProdukAdminNotifier() : super(const ProdukAdminState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.instance.get('/produk');
      List<dynamic> rawData = [];
      if (res.data is List) {
        rawData = res.data;
      } else if (res.data is Map && res.data.containsKey('data')) {
        rawData = res.data['data'];
      } else if (res.data is Map) {
        rawData = res.data.values.toList();
      }

      state = state.copyWith(
        isLoading: false,
        data: List<Map<String, dynamic>>.from(rawData),
      );
    } catch (e) {
      print('🚨 ERROR FETCH PRODUK: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat katalog produk',
      );
    }
  }

  Future<bool> simpanProduk({
    int? id,
    required String nama,
    required String deskripsi,
    required int poin,
    required int stok,
    File? imageFile,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      // Menggunakan FormData untuk mendukung pengiriman berkas gambar
      FormData formData = FormData.fromMap({
        'nama': nama,
        'deskripsi': deskripsi,
        'biaya_poin': poin, // 👈 UBAH DARI 'poin' MENJADI 'biaya_poin'
        'stok': stok,
      });

      if (imageFile != null) {
        String fileName = imageFile.path.split('/').last;
        formData.files.add(
          MapEntry(
            'foto', // Sesuaikan dengan nama request file di controller Laravel Anda
            await MultipartFile.fromFile(imageFile.path, filename: fileName),
          ),
        );
      }

      if (id == null) {
        await ApiClient.instance.post('/admin/produk', data: formData);
      } else {
        formData.fields.add(const MapEntry('_method', 'PUT'));
        await ApiClient.instance.post('/admin/produk/$id', data: formData);
      }

      await fetch();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      if (e is DioException) {
        // Ini akan mencetak pesan error asli dari Laravel ke Terminal
        print('🚨 ERROR VALIDASI PRODUK LARAVEL: ${e.response?.data}');
      } else {
        print('🚨 ERROR SIMPAN PRODUK: $e');
      }

      state = state.copyWith(
        isSubmitting: false,
        error: 'Gagal menyimpan. Cek terminal untuk detail error 422.',
      );
      return false;
    }
  }

  Future<bool> toggleStatus(int id) async {
    try {
      await ApiClient.instance.patch('/admin/produk/$id/toggle');
      await fetch();
      return true;
    } catch (e) {
      print('🚨 ERROR TOGGLE PRODUK: $e');
      return false;
    }
  }
}

final produkAdminProvider =
    StateNotifierProvider<ProdukAdminNotifier, ProdukAdminState>((ref) {
      return ProdukAdminNotifier();
    });

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFIKASI ADMIN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class NotifikasiModel {
  final int id;
  final String judul;
  final String pesan;
  final String tipe; // contoh: 'verifikasi', 'pencairan', 'sistem'
  final bool isRead;
  final String tanggal;

  NotifikasiModel({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tipe,
    required this.isRead,
    required this.tanggal,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? 'Pemberitahuan Baru',
      pesan: json['pesan'] ?? '-',
      tipe: json['tipe'] ?? 'sistem',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      tanggal: json['created_at'] != null
          ? json['created_at'].toString().split('T')[0]
          : '',
    );
  }
}

class NotifikasiState {
  final bool isLoading;
  final List<NotifikasiModel> data;
  final String? error;

  const NotifikasiState({
    this.isLoading = false,
    this.data = const [],
    this.error,
  });

  NotifikasiState copyWith({
    bool? isLoading,
    List<NotifikasiModel>? data,
    String? error,
  }) {
    return NotifikasiState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class NotifikasiNotifier extends StateNotifier<NotifikasiState> {
  NotifikasiNotifier() : super(const NotifikasiState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.instance.get(
        '/admin/notifikasi',
      ); // Sesuaikan endpoint Laravel Anda
      List<dynamic> rawData = [];
      if (res.data is List)
        rawData = res.data;
      else if (res.data is Map && res.data.containsKey('data'))
        rawData = res.data['data'];

      final list = rawData.map((e) => NotifikasiModel.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, data: list);
    } catch (e) {
      print('🚨 ERROR FETCH NOTIFIKASI: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat notifikasi.',
      );
    }
  }

  Future<void> tandaiSemuaDibaca() async {
    try {
      await ApiClient.instance.patch('/admin/notifikasi/baca');
      // Update state lokal agar isRead menjadi true semua tanpa harus loading ulang dari API
      final updatedData = state.data
          .map(
            (n) => NotifikasiModel(
              id: n.id,
              judul: n.judul,
              pesan: n.pesan,
              tipe: n.tipe,
              tanggal: n.tanggal,
              isRead: true,
            ),
          )
          .toList();
      state = state.copyWith(data: updatedData);
    } catch (e) {
      print('🚨 ERROR TANDAI DIBACA: $e');
    }
  }

  Future<bool> bersihkanNotifikasi() async {
    try {
      // Tembak ke endpoint delete yang baru kita buat
      await ApiClient.instance.delete('/admin/notifikasi/bersihkan');
      
      // Kosongkan data lokal di state agar UI langsung bersih tanpa loading ulang
      state = state.copyWith(data: const []);
      return true;
    } catch (e) {
      print('🚨 ERROR BERSIHKAN NOTIFIKASI: $e');
      return false;
    }
  }
}

final notifikasiProvider =
    StateNotifierProvider<NotifikasiNotifier, NotifikasiState>((ref) {
      return NotifikasiNotifier();
    });

// ══════════════════════════════════════════════════════════════════════════════
// LAPORAN ADMIN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class LaporanAdminData {
  final int totalTransaksi;
  final double volumeKg;
  final int nilaiKonversi;
  
  // 👇 KATEGORI TRANSAKSI YANG SUDAH DIPISAH 👇
  final List<dynamic> setoran;
  final List<dynamic> tukarSembako;
  final List<dynamic> tukarCash;

  LaporanAdminData({
    required this.totalTransaksi,
    required this.volumeKg,
    required this.nilaiKonversi,
    required this.setoran,
    required this.tukarSembako,
    required this.tukarCash,
  });

  factory LaporanAdminData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    final data = json['data'] ?? {};

    return LaporanAdminData(
      totalTransaksi: int.tryParse(stats['total_transaksi']?.toString() ?? '0') ?? 0,
      volumeKg: double.tryParse(stats['volume_kg']?.toString() ?? '0') ?? 0.0,
      nilaiKonversi: int.tryParse(stats['nilai_konversi']?.toString() ?? '0') ?? 0,
      setoran: data['setoran'] as List<dynamic>? ?? const [],
      tukarSembako: data['tukar_sembako'] as List<dynamic>? ?? const [],
      tukarCash: data['tukar_cash'] as List<dynamic>? ?? const [],
    );
  }
}

class LaporanAdminState {
  final bool isLoading;
  final LaporanAdminData? data;
  final String dari;
  final String sampai;
  final String? error;

  const LaporanAdminState({
    this.isLoading = false,
    this.data,
    required this.dari,
    required this.sampai,
    this.error,
  });

  LaporanAdminState copyWith({
    bool? isLoading,
    LaporanAdminData? data,
    String? dari,
    String? sampai,
    String? error,
  }) {
    return LaporanAdminState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      dari: dari ?? this.dari,
      sampai: sampai ?? this.sampai,
      error: error,
    );
  }
}

class LaporanAdminNotifier extends StateNotifier<LaporanAdminState> {
  LaporanAdminNotifier()
    : super(
        LaporanAdminState(
          // Default rentang tanggal: Hari pertama bulan ini sampai hari ini
          dari: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            1,
          ).toString().split(' ')[0],
          sampai: DateTime.now().toString().split(' ')[0],
        ),
      ) {
    fetch();
  }

  Future<void> fetch({String? dari, String? sampai}) async {
    final tglDari = dari ?? state.dari;
    final tglSampai = sampai ?? state.sampai;

    state = state.copyWith(
      isLoading: true,
      dari: tglDari,
      sampai: tglSampai,
      error: null,
    );

    try {
      // Mengirimkan parameter filter ke URL (contoh: /admin/laporan?dari=2026-06-01&sampai=2026-06-30)
      final res = await ApiClient.instance.get(
        '/admin/laporan?dari=$tglDari&sampai=$tglSampai',
      );

      if (res.data != null && res.data is Map<String, dynamic>) {
        final laporanData = LaporanAdminData.fromJson(res.data);
        state = state.copyWith(isLoading: false, data: laporanData);
      } else {
        throw Exception("Format JSON tidak valid");
      }
    } catch (e) {
      print('🚨 ERROR FETCH LAPORAN: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data laporan.',
      );
    }
  }
}

final laporanAdminProvider =
    StateNotifierProvider<LaporanAdminNotifier, LaporanAdminState>((ref) {
      return LaporanAdminNotifier();
    });

// ══════════════════════════════════════════════════════════════════════════════
// PENUKARAN ADMIN PROVIDER (TAMBAHAN BARU)
// ══════════════════════════════════════════════════════════════════════════════

class PenukaranAdminModel {
  final int id;
  final String namaNasabah;
  final String tanggal;
  final String status;
  final int nominal; // Bisa merepresentasikan total poin yang ditukar
  final String? catatan;

  PenukaranAdminModel({
    required this.id,
    required this.namaNasabah,
    required this.tanggal,
    required this.status,
    required this.nominal,
    this.catatan,
  });

  String get initials {
    if (namaNasabah.isEmpty) return '?';
    List<String> words = namaNasabah.trim().split(' ');
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return (words[0].substring(0, 1) + words[words.length - 1].substring(0, 1))
        .toUpperCase();
  }

  // Format tampilan nominal/poin (contoh: 47100 -> 47.100 Poin atau Rp 47.100)
  String get nominalFormatted {
    final s = nominal.toString();
    String result = '';
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result = '.$result';
      result = s[i] + result;
      count++;
    }
    return '$result Poin'; // 👈 Sesuaikan teks penutup (Poin / Rp) sesuai kebutuhan
  }

  factory PenukaranAdminModel.fromJson(Map<String, dynamic> json) {
    return PenukaranAdminModel(
      id: json['id'] ?? 0,
      namaNasabah:
          json['nasabah']?['nama_lengkap'] ??
          json['nama_nasabah'] ??
          'Tanpa Nama',
      tanggal: json['created_at'] != null
          ? json['created_at'].toString().split('T')[0]
          : '-',
      status: json['status'] ?? 'pending',
      nominal: int.tryParse(
            json['poin']?.toString() ?? json['total_poin']?.toString() ?? '0',
          ) ?? 0,
      catatan: json['catatan'] as String?, // Menyimpan rincian barang yang ditukar dari Laravel
    );
  }
}

class PenukaranAdminState {
  final bool isLoading;
  final bool isSubmitting;
  final int processingId;
  final List<PenukaranAdminModel> data;
  final String? error;

  const PenukaranAdminState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.processingId = 0,
    this.data = const [],
    this.error,
  });

  // Menghitung otomatis total poin/nominal penukaran yang masih 'pending'
  String get totalTertundaFormatted {
    final total = data
        .where((e) => e.status == 'pending')
        .fold(0, (sum, item) => sum + item.nominal);
    final s = total.toString();
    String result = '';
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result = '.$result';
      result = s[i] + result;
      count++;
    }
    return '$result Poin';
  }

  PenukaranAdminState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    int? processingId,
    List<PenukaranAdminModel>? data,
    String? error,
  }) {
    return PenukaranAdminState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      processingId: processingId ?? this.processingId,
      data: data ?? this.data,
      error: error,
    );
  }
}

class PenukaranAdminNotifier extends StateNotifier<PenukaranAdminState> {
  PenukaranAdminNotifier() : super(const PenukaranAdminState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 👈 Sesuaikan dengan nama endpoint index penukaran di Laravel Anda
      final res = await ApiClient.instance.get('/admin/penukaran');

      List<dynamic> rawData = [];
      if (res.data is List) {
        rawData = res.data;
      } else if (res.data is Map && res.data.containsKey('data')) {
        rawData = res.data['data'];
      } else if (res.data is Map) {
        rawData = res.data.values.toList();
      }

      final list = rawData.map((e) => PenukaranAdminModel.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, data: list);
    } catch (e) {
      print('🚨 ERROR FETCH PENUKARAN: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data penukaran.',
      );
    }
  }

  Future<bool> selesaikan(int id) async {
    state = state.copyWith(isSubmitting: true, processingId: id, error: null);
    try {
      // 👈 Endpoint menyetujui/menyelesaikan transaksi penukaran poin
      await ApiClient.instance.post('/admin/penukaran/$id/selesai');
      await fetch();
      state = state.copyWith(isSubmitting: false, processingId: 0);
      return true;
    } catch (e) {
      print('🚨 ERROR SETUJUI PENUKARAN: $e');
      state = state.copyWith(
        isSubmitting: false,
        processingId: 0,
        error: 'Gagal menyetujui penukaran.',
      );
      return false;
    }
  }

  Future<bool> tolak(int id) async {
    state = state.copyWith(isSubmitting: true, processingId: id, error: null);
    try {
      // 👈 Endpoint menolak transaksi penukaran poin
      await ApiClient.instance.post('/admin/penukaran/$id/tolak');
      await fetch();
      state = state.copyWith(isSubmitting: false, processingId: 0);
      return true;
    } catch (e) {
      print('🚨 ERROR TOLAK PENUKARAN: $e');
      state = state.copyWith(
        isSubmitting: false,
        processingId: 0,
        error: 'Gagal menolak penukaran.',
      );
      return false;
    }
  }
}

final penukaranAdminProvider =
    StateNotifierProvider<PenukaranAdminNotifier, PenukaranAdminState>((ref) {
  return PenukaranAdminNotifier();
});