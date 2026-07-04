import 'dart:convert';

/// Model data user yang dikembalikan oleh Laravel API setelah login
class UserModel {
  final int id;
  final String username;
  final String namaLengkap;
  final String email;
  final String role; // 'nasabah' atau 'admin'
  final bool isVerified;
  final int totalPoin;
  final String? noHp;
  final String? idNasabah;
  final String? fotoUrl; // contoh: BS-20231012

  const UserModel({
    required this.id,
    required this.username,
    required this.namaLengkap,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.totalPoin,
    this.noHp,
    this.idNasabah,
    this.fotoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('📦 DATA MENTAH DARI LARAVEL: $json');
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      namaLengkap: json['nama_lengkap'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isVerified: (json['is_verified'] == 1 || json['is_verified'] == true),
      totalPoin: json['total_poin'] as int? ?? 0,
      noHp: json['no_hp'] as String?,
      idNasabah: json['id_nasabah'] as String?,

      // 👇 KEMBALIKAN MENJADI SEDERHANA SEPERTI INI 👇
      fotoUrl: json['foto_profil'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'nama_lengkap': namaLengkap,
    'email': email,
    'role': role,
    'is_verified': isVerified,
    'total_poin': totalPoin,
    'no_hp': noHp,
    'id_nasabah': idNasabah,
    'foto_profil': fotoUrl, // 👇 TAMBAHKAN BARIS INI 👇
  };

  /// Simpan ke String untuk disimpan di secure storage
  String toJsonString() => jsonEncode(toJson());

  /// Baca dari String yang tersimpan di secure storage
  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  bool get isAdmin => role == 'admin';
  bool get isNasabah => role == 'nasabah';
}
