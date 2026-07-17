/// Model untuk produk penukaran poin (sembako, dll)
class ProdukModel {
  final int id;
  final String nama;
  final String deskripsi;
  final int biayaPoin;
  final int stok;
  final bool isActive;
  final String? fotoUrl;

  ProdukModel({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.biayaPoin,
    required this.stok,
    required this.isActive,
    this.fotoUrl,
  });

  // Logika otomatis untuk mengecek apakah stok habis atau produk dinonaktifkan
  bool get isHabis => stok <= 0 || !isActive;

  // Format ribuan untuk harga poin (contoh: 15000 -> 15,000)
  String get biayaPoinFormatted {
    final s = biayaPoin.toString();
    if (s.length <= 3) return s;
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return result.toString();
  }

  factory ProdukModel.fromJson(Map<String, dynamic> json) {
    // Tangkap URL gambar (sesuaikan field-nya: foto_url, image_url, atau foto)
    String? rawUrl = json['foto_url'] as String? ?? json['foto'] as String? ?? json['image_url'] as String?;
    
    // Perbaikan URL Localhost (Sama seperti Kategori)
    if (rawUrl != null && rawUrl.isNotEmpty && !rawUrl.startsWith('http')) {
      if (rawUrl.startsWith('/')) rawUrl = rawUrl.substring(1);
      if (!rawUrl.startsWith('storage/')) rawUrl = 'storage/$rawUrl';
      
      // 🚨 PENTING: Ganti dengan IP yang sama dengan yang Anda pakai di ApiClient
      rawUrl = 'https://banksampahkita.kotapintar.my.id/$rawUrl'; 
    }

    return ProdukModel(
      id: json['id'] as int? ?? 0,
      nama: json['nama'] as String? ?? '-',
      deskripsi: json['deskripsi'] as String? ?? '',
      biayaPoin: int.tryParse(json['biaya_poin']?.toString() ?? '0') ?? 0,
      stok: int.tryParse(json['stok']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
      fotoUrl: rawUrl, // URL matang dimasukkan ke sini
    );
  }
}

/// Model untuk kategori sampah (katalog harga)
class KategoriModel {
  final int id;
  final String nama;
  final String deskripsi;
  final int poinPerKg;
  final bool isActive;
  final String? iconName;
  final String? imageUrl;

  const KategoriModel({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.poinPerKg,
    required this.isActive,
    this.iconName,
    this.imageUrl,
  });

  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    String? rawUrl = json['image_url'] as String? ?? json['foto'] as String?;
    
    if (rawUrl != null && rawUrl.isNotEmpty && !rawUrl.startsWith('http')) {
      if (rawUrl.startsWith('/')) rawUrl = rawUrl.substring(1);
      if (!rawUrl.startsWith('storage/')) rawUrl = 'storage/$rawUrl';
      
      // Sesuaikan IP ini jika menggunakan HP Fisik (misal: 192.168.1.x)
      rawUrl = 'https://banksampahkita.kotapintar.my.id/$rawUrl'; 
    }

    return KategoriModel(
      id: json['id'] as int? ?? 0,
      nama: json['nama'] as String? ?? '-',
      deskripsi: json['deskripsi'] as String? ?? '',
      poinPerKg: int.tryParse(json['poin_per_kg']?.toString() ?? '0') ?? 0,
      iconName: json['icon_name'] as String?,
      imageUrl: rawUrl, 
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1', // 👈 Telah ditambahkan!
    );
  }
}