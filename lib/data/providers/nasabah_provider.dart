import 'package:bank_sampah_fiks/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaksi_model.dart';
import '../../data/models/produk_model.dart';
import '../../data/models/notifikasi_model.dart';
import '../../data/services/nasabah_service.dart';

// ── Service Provider ───────────────────────────────────────────────────────
final nasabahServiceProvider = Provider<NasabahService>((ref) => NasabahService());

// ══════════════════════════════════════════════════════════════════════════════
// DASHBOARD PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
class DashboardState {
  final bool isLoading;
  final int totalPoin;
  final List<dynamic> transaksiTerakhir;
  final String? error;
  // 👇 DUA PROPERTI BARU UNTUK LEVEL NASABAH 👇
  final double totalSetoran; 
  final String level;

  const DashboardState({
    this.isLoading = false,
    this.totalPoin = 0,
    this.transaksiTerakhir = const [],
    this.error,
    this.totalSetoran = 0.0, // Default 0 kg
    this.level = 'Bronze',   // Default level terendah
  });

  DashboardState copyWith({
    bool? isLoading,
    int? totalPoin,
    List<dynamic>? transaksiTerakhir,
    String? error,
    double? totalSetoran,
    String? level,
  }) =>
      DashboardState(
        isLoading:         isLoading ?? this.isLoading,
        totalPoin:         totalPoin ?? this.totalPoin,
        transaksiTerakhir: transaksiTerakhir ?? this.transaksiTerakhir,
        error:             error,
        totalSetoran:      totalSetoran ?? this.totalSetoran,
        level:             level ?? this.level,
      );

  /// Format totalPoin dengan separator koma: 24500 → "24,500"
  String get totalPoinFormatted {
    final s = totalPoin.toString();
    if (s.length <= 3) return s;
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return result.toString();
  }

  /// Konversi poin ke rupiah: 1 poin = Rp 1
  String get nilaiRupiah {
    final rp = totalPoin;
    if (rp >= 1000000) return 'Rp ${(rp / 1000000).toStringAsFixed(1)}Jt';
    if (rp >= 1000)    return 'Rp ${(rp / 1000).toStringAsFixed(0)}rb';
    return 'Rp $rp';
  }

  // 👇 GETTER BARU: Merapikan tampilan total berat sampah (Contoh: 12.5 kg) 👇
  String get totalSetoranFormatted {
    return '${totalSetoran.toStringAsFixed(1).replaceAll('.', ',')} kg';
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final NasabahService _service;

  DashboardNotifier(this._service) : super(const DashboardState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _service.getDashboard();
      
      // 👇 SESUAIKAN MAP DATA DARI RESULT SERVICE ANDA 👇
      state = state.copyWith(
        isLoading:         false,
        totalPoin:         result.totalPoin,
        transaksiTerakhir: result.transaksiTerakhir,
        totalSetoran:      double.tryParse(result.totalSetoran?.toString() ?? '0') ?? 0.0, // 👈 Ambil total setoran
        level:             result.level ?? 'Bronze', // 👈 Ambil level nasabah
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     'Gagal memuat data.',
      );
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.read(nasabahServiceProvider));
});

// ══════════════════════════════════════════════════════════════════════════════
// RIWAYAT PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class RiwayatState {
  final bool isLoading;
  final List<SetoranModel> setoran;
  final List<PenukaranModel> penukaran;
  final int totalPoin;
  final int poinBulanIni;
  final int currentPage;
  final int lastPage;
  final int? filterBulan;
  final int? filterTahun;
  final String? error;

  const RiwayatState({
    this.isLoading = false,
    this.setoran = const [],
    this.penukaran = const [],
    this.totalPoin = 0,
    this.poinBulanIni = 0,
    this.currentPage = 1,
    this.lastPage = 1,
    this.filterBulan,
    this.filterTahun,
    this.error,
  });

  RiwayatState copyWith({
    bool? isLoading,
    List<SetoranModel>? setoran,
    List<PenukaranModel>? penukaran,
    int? totalPoin,
    int? poinBulanIni,
    int? currentPage,
    int? lastPage,
    int? filterBulan,
    int? filterTahun,
    String? error,
  }) =>
      RiwayatState(
        isLoading:    isLoading    ?? this.isLoading,
        setoran:      setoran      ?? this.setoran,
        penukaran:    penukaran    ?? this.penukaran,
        totalPoin:    totalPoin    ?? this.totalPoin,
        poinBulanIni: poinBulanIni ?? this.poinBulanIni,
        currentPage:  currentPage  ?? this.currentPage,
        lastPage:     lastPage     ?? this.lastPage,
        filterBulan:  filterBulan  ?? this.filterBulan,
        filterTahun:  filterTahun  ?? this.filterTahun,
        error:        error,
      );

  String get totalPoinFormatted {
    final s = totalPoin.toString();
    if (s.length <= 3) return s;
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return result.toString();
  }

  String get poinBulanIniFormatted =>
      '+${poinBulanIni.toString()} bulan ini';
}

class RiwayatNotifier extends StateNotifier<RiwayatState> {
  final NasabahService _service;

  RiwayatNotifier(this._service) : super(const RiwayatState()) {
    fetchSetoran();
  }

  Future<void> fetchSetoran({int page = 1}) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _service.getRiwayatSetoran(
        page:  page,
        bulan: state.filterBulan,
        tahun: state.filterTahun,
      );
      state = state.copyWith(
        isLoading:    false,
        setoran:      result.data,
        totalPoin:    result.totalPoin,
        poinBulanIni: result.poinBulanIni,
        currentPage:  page,
        lastPage:     result.lastPage,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat riwayat.');
    }
  }

  Future<void> fetchPenukaran({int page = 1}) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _service.getRiwayatPenukaran(
        page:  page,
        bulan: state.filterBulan,
        tahun: state.filterTahun,
      );
      state = state.copyWith(
        isLoading:   false,
        penukaran:   result.data,
        currentPage: page,
        lastPage:    result.lastPage,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat riwayat.');
    }
  }

  void setFilter({int? bulan, int? tahun}) {
    state = state.copyWith(
      filterBulan: bulan,
      filterTahun: tahun,
      currentPage: 1,
    );
    fetchSetoran();
  }
}

final riwayatProvider =
    StateNotifierProvider<RiwayatNotifier, RiwayatState>((ref) {
  return RiwayatNotifier(ref.read(nasabahServiceProvider));
});

// ══════════════════════════════════════════════════════════════════════════════
// TUKAR PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class TukarState {
  final bool isLoading;
  final bool isSubmitting;
  final List<ProdukModel> produk;
  final String? error;
  final String? successMessage;

  const TukarState({
    this.isLoading    = false,
    this.isSubmitting = false,
    this.produk       = const [],
    this.error,
    this.successMessage,
  });

  TukarState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<ProdukModel>? produk,
    String? error,
    String? successMessage,
  }) =>
      TukarState(
        isLoading:      isLoading      ?? this.isLoading,
        isSubmitting:   isSubmitting   ?? this.isSubmitting,
        produk:         produk         ?? this.produk,
        error:          error,
        successMessage: successMessage,
      );
}

class TukarNotifier extends StateNotifier<TukarState> {
  final NasabahService _service;
  final Ref _ref;

  TukarNotifier(this._service, this._ref) : super(const TukarState()) {
    fetchProduk();
  }

  Future<void> fetchProduk() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _service.getProduk();
      state = state.copyWith(isLoading: false, produk: list);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat produk.');
    }
  }

  Future<bool> tukarProduk({required int produkId, required int jumlah}) async {
    state = state.copyWith(isSubmitting: true);
    final result = await _service.tukarProduk(
        produkId: produkId, jumlah: jumlah);
    if (result.success) {
      // Refresh dashboard agar saldo poin terupdate
      _ref.read(dashboardProvider.notifier).fetch();
      state = state.copyWith(
          isSubmitting: false, successMessage: result.message);
    } else {
      state = state.copyWith(isSubmitting: false, error: result.message);
    }
    return result.success;
  }

  Future<bool> tukarCash({
    required int nominal,
    required String metode,
    String? tipeTransfer,
    String? namaBankEwallet,
    String? nomorRekening,
  }) async {
    state = state.copyWith(isSubmitting: true);
    final result = await _service.tukarCash(
      nominal: nominal,
      metode: metode,
      tipeTransfer: tipeTransfer,
      namaBankEwallet: namaBankEwallet,
      nomorRekening: nomorRekening,
    );
    if (result.success) {
      _ref.read(dashboardProvider.notifier).fetch();
      state = state.copyWith(isSubmitting: false, successMessage: result.message);
    } else {
      state = state.copyWith(isSubmitting: false, error: result.message);
    }
    return result.success;
  }
}

final tukarProvider =
    StateNotifierProvider<TukarNotifier, TukarState>((ref) {
  return TukarNotifier(ref.read(nasabahServiceProvider), ref);
});

// ══════════════════════════════════════════════════════════════════════════════
// KATALOG PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class KatalogState {
  final bool isLoading;
  final List<KategoriModel> kategori;
  final String? error;

  const KatalogState({
    this.isLoading = false,
    this.kategori  = const [],
    this.error,
  });

  KatalogState copyWith({
    bool? isLoading,
    List<KategoriModel>? kategori,
    String? error,
  }) =>
      KatalogState(
        isLoading: isLoading ?? this.isLoading,
        kategori:  kategori  ?? this.kategori,
        error:     error,
      );
}

class KatalogNotifier extends StateNotifier<KatalogState> {
  final NasabahService _service;

  KatalogNotifier(this._service) : super(const KatalogState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _service.getKategori();
      state = state.copyWith(isLoading: false, kategori: list);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat katalog.');
    }
  }
}

final katalogProvider =
    StateNotifierProvider<KatalogNotifier, KatalogState>((ref) {
  return KatalogNotifier(ref.read(nasabahServiceProvider));
});

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFIKASI PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class NotifikasiState {
  final bool isLoading;
  final List<NotifikasiModel> items;
  final int unreadCount;
  final String? error;

  const NotifikasiState({
    this.isLoading   = false,
    this.items       = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotifikasiState copyWith({
    bool? isLoading,
    List<NotifikasiModel>? items,
    int? unreadCount,
    String? error,
  }) =>
      NotifikasiState(
        isLoading:   isLoading   ?? this.isLoading,
        items:       items       ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        error:       error,
      );
}

class NotifikasiNotifier extends StateNotifier<NotifikasiState> {
  final NasabahService _service;

  NotifikasiNotifier(this._service) : super(const NotifikasiState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _service.getNotifikasi();
      state = state.copyWith(
        isLoading:   false,
        items:       result.data,
        unreadCount: result.unreadCount,
      );
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Gagal memuat notifikasi.');
    }
  }

  Future<void> markAllRead() async {
    await _service.markAllNotifikasiRead();
    state = state.copyWith(
      unreadCount: 0,
      items: state.items.map((n) => NotifikasiModel(
        id:        n.id,
        judul:     n.judul,
        pesan:     n.pesan,
        tipe:      n.tipe,
        isRead:    true,
        createdAt: n.createdAt,
      )).toList(),
    );
  }

  // 👇 TAMBAHKAN FUNGSI INI DI SINI 👇
  Future<bool> bersihkanNotifikasi() async {
    try {
      // 1. Panggil API delete melalui ApiClient langsung (karena endpoint baru)
      await ApiClient.instance.delete('/nasabah/notifikasi/bersihkan');
      
      // 2. Kosongkan state lokal list items & unreadCount menjadi 0 secara instan
      state = state.copyWith(
        items: const [],
        unreadCount: 0,
      );
      return true;
    } catch (e) {
      print('🚨 ERROR BERSIHKAN NOTIFIKASI NASABAH: $e');
      return false;
    }
  }
}

final notifikasiProvider =
    StateNotifierProvider<NotifikasiNotifier, NotifikasiState>((ref) {
  return NotifikasiNotifier(ref.read(nasabahServiceProvider));
});

/// Shortcut untuk badge unread count di AppBar
final unreadNotifCountProvider = Provider<int>((ref) {
  return ref.watch(notifikasiProvider).unreadCount;
});