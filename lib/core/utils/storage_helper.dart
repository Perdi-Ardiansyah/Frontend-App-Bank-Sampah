import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// StorageHelper — wrapper untuk flutter_secure_storage.
/// Gunakan ini untuk semua operasi simpan/baca data sensitif.
/// JANGAN simpan password di sini, hanya token dan info user.
class StorageHelper {
  StorageHelper._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ── Keys ───────────────────────────────────────────────────────────────────
  static const _keyToken       = 'jwt_token';
  static const _keyRole        = 'user_role';
  static const _keyUsername    = 'username';
  static const _keyUserId      = 'user_id';
  static const _keyNamaLengkap = 'nama_lengkap';
  static const _keyUserObject  = 'user_object'; // full JSON user

  // ── Token ──────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() async =>
      _storage.read(key: _keyToken);

  static Future<void> deleteToken() async =>
      _storage.delete(key: _keyToken);

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }

  // ── User Info ──────────────────────────────────────────────────────────────

  static Future<void> saveUserInfo({
    required String role,
    required String username,
    required String userId,
    required String namaLengkap,
  }) async {
    await _storage.write(key: _keyRole,        value: role);
    await _storage.write(key: _keyUsername,    value: username);
    await _storage.write(key: _keyUserId,      value: userId);
    await _storage.write(key: _keyNamaLengkap, value: namaLengkap);
  }

  static Future<String?> getRole()        async => _storage.read(key: _keyRole);
  static Future<String?> getUsername()    async => _storage.read(key: _keyUsername);
  static Future<String?> getUserId()      async => _storage.read(key: _keyUserId);
  static Future<String?> getNamaLengkap() async => _storage.read(key: _keyNamaLengkap);

  // ── Full User Object ───────────────────────────────────────────────────────

  /// Simpan seluruh objek UserModel sebagai JSON string
  static Future<void> saveUserObject(String userJsonString) async =>
      _storage.write(key: _keyUserObject, value: userJsonString);

  /// Ambil JSON string user (untuk restore sesi)
  static Future<String?> getUserObject() async =>
      _storage.read(key: _keyUserObject);

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// Hapus semua data (dipanggil saat logout atau token expired)
  static Future<void> clearAll() async => _storage.deleteAll();
}