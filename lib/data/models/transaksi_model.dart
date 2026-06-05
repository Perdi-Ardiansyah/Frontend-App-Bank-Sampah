class SetoranModel {
  final int id;
  final String kategoriNama;
  final String kategoriIcon;
  final double beratKg;
  final int poinDidapat;
  final String status;
  final String? lokasiTps;
  final String? catatan;
  final DateTime tanggal;

  SetoranModel({
    required this.id,
    required this.kategoriNama,
    required this.kategoriIcon,
    required this.beratKg,
    required this.poinDidapat,
    required this.status,
    this.lokasiTps,
    this.catatan,
    required this.tanggal,
  });

  // 1. Menerjemahkan JSON dari Database Laravel ke Flutter
  factory SetoranModel.fromJson(Map<String, dynamic> json) {
    return SetoranModel(
      id: json['id'] as int? ?? 0,
      kategoriNama: json['kategori_nama'] as String? ?? '-',
      kategoriIcon: json['kategori_icon'] as String? ?? 'recycling',
      // Memastikan tipe data angka aman meskipun DB mengirim String atau Int
      beratKg: double.tryParse(json['berat_kg']?.toString() ?? '0') ?? 0.0,
      poinDidapat: int.tryParse(json['poin_didapat']?.toString() ?? '0') ?? 0,
      status: json['status'] as String? ?? 'pending',
      lokasiTps: json['lokasi_tps'] as String?,
      catatan: json['catatan'] as String?,
      // Mengubah string ISO tanggal dari Laravel menjadi objek DateTime Flutter
      tanggal: json['tanggal'] != null 
          ? DateTime.parse(json['tanggal']).toLocal() 
          : DateTime.now(),
    );
  }

  // 2. Getter untuk menyesuaikan format UI di riwayat_screen.dart
  String get poinFormatted {
    final s = poinDidapat.toString();
    if (s.length <= 3) return '+$s';
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return '+${result.toString()}'; // Menambahkan tanda plus (+) untuk setoran
  }

  String get beratFormatted {
    // Jika 5.0 kg, akan tampil "5 kg". Jika 5.5 kg, tampil "5.5 kg"
    return '${beratKg.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} Kg';
  }
}

// ══════════════════════════════════════════════════════════════════════════════

class PenukaranModel {
  final int id;
  final String produkNama;
  final int jumlah;
  final int totalPoin;
  final String status;
  final String tipe;
  final DateTime tanggal;

  PenukaranModel({
    required this.id,
    required this.produkNama,
    required this.jumlah,
    required this.totalPoin,
    required this.status,
    required this.tipe,
    required this.tanggal,
  });

  // 1. Menerjemahkan JSON dari Database Laravel ke Flutter
  factory PenukaranModel.fromJson(Map<String, dynamic> json) {
    return PenukaranModel(
      id: json['id'] as int? ?? 0,
      produkNama: json['produk_nama'] as String? ?? 'Pencairan Dana',
      jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
      totalPoin: int.tryParse(json['total_poin']?.toString() ?? '0') ?? 0,
      status: json['status'] as String? ?? 'pending',
      tipe: json['tipe'] as String? ?? 'produk',
      tanggal: json['tanggal'] != null 
          ? DateTime.parse(json['tanggal']).toLocal() 
          : DateTime.now(),
    );
  }

  // 2. Getter untuk menyesuaikan format UI di riwayat_screen.dart
  String get poinFormatted {
    final s = totalPoin.toString();
    if (s.length <= 3) return '-$s';
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return '-${result.toString()}'; // Menambahkan tanda minus (-) untuk penukaran
  }
}