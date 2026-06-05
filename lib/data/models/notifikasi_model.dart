/// Model untuk notifikasi nasabah
class NotifikasiModel {
  final int id;
  final String judul;
  final String pesan;
  final String tipe; // 'setoran', 'penukaran', 'sistem', 'promo'
  final bool isRead;
  final DateTime createdAt;

  const NotifikasiModel({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tipe,
    required this.isRead,
    required this.createdAt,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      id:        json['id'] as int,
      judul:     json['judul'] as String,
      pesan:     json['pesan'] as String,
      tipe:      json['tipe'] as String? ?? 'sistem',
      isRead:    (json['is_read'] == 1 || json['is_read'] == true),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Format waktu relatif: "10 menit yang lalu", "Kemarin", dll
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1)   return 'Baru saja';
    if (diff.inMinutes < 60)  return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24)    return '${diff.inHours} jam yang lalu';
    if (diff.inDays == 1)     return 'Kemarin';
    if (diff.inDays < 7)      return '${diff.inDays} hari yang lalu';
    return '${createdAt.day} ${_bulan(createdAt.month)} ${createdAt.year}';
  }

  static String _bulan(int m) {
    const list = ['','Jan','Feb','Mar','Apr','Mei','Jun',
                     'Jul','Agu','Sep','Okt','Nov','Des'];
    return list[m];
  }
}