import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/storage_helper.dart';
import '../models/user_model.dart';

/// Hasil login — dibedakan agar LoginScreen tahu harus redirect ke mana
enum LoginResult {
  successNasabah,   // login OK, role nasabah
  successAdmin,     // login OK, role admin
  pendingVerifikasi, // akun belum diverifikasi admin
  invalidCredentials, // username/password salah
  serverError,       // error lain dari server
}

class AuthService {
  final Dio _dio = ApiClient.instance;

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Login ke Laravel API.
  /// Endpoint: POST /api/login
  /// Body: { "username": "...", "password": "..." }
  /// Response sukses: { "token": "...", "user": { ... } }
  Future<({LoginResult result, UserModel? user, String? message})> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'username': username, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user  = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      // Cek apakah akun sudah diverifikasi admin
      if (!user.isVerified) {
        return (
          result: LoginResult.pendingVerifikasi,
          user: null,
          message: 'Akun Anda belum diverifikasi oleh admin.',
        );
      }

      // Simpan token dan info user ke secure storage
      await StorageHelper.saveToken(token);
      await StorageHelper.saveUserInfo(
        role:         user.role,
        username:     user.username,
        userId:       user.id.toString(),
        namaLengkap:  user.namaLengkap,
      );
      // Simpan seluruh objek user untuk akses cepat
      await StorageHelper.saveUserObject(user.toJsonString());

      final result = user.isAdmin
          ? LoginResult.successAdmin
          : LoginResult.successNasabah;

      return (result: result, user: user, message: null);

    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 422) {
        return (
          result: LoginResult.invalidCredentials,
          user: null,
          message: 'Username atau password salah.',
        );
      }
      return (
        result: LoginResult.serverError,
        user: null,
        message: 'Terjadi kesalahan. Coba lagi.',
      );
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  /// Register nasabah baru.
  /// Endpoint: POST /api/register
  /// Body: { "nama_lengkap": "...", "username": "...", "email": "...", "password": "..." }
  Future<({bool success, String message})> register({
    required String namaLengkap,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/register',
        data: {
          'nama_lengkap': namaLengkap,
          'username':     username,
          'email':        email,
          'password':     password,
        },
      );
      return (success: true, message: 'Akun berhasil dibuat. Tunggu verifikasi admin.');
    } on DioException catch (e) {
      final msg = _parseErrorMessage(e);
      return (success: false, message: msg);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// Logout — hapus token di server dan di lokal.
  /// Endpoint: POST /api/logout
  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (_) {
      // Tetap lanjut logout lokal meskipun server error
    } finally {
      await StorageHelper.clearAll();
    }
  }

  // ── Ganti Password ─────────────────────────────────────────────────────────

  /// Ganti password user yang sedang login.
  /// Endpoint: POST /api/change-password
  Future<({bool success, String message})> changePassword({
    required String passwordLama,
    required String passwordBaru,
    required String konfirmasiPassword,
  }) async {
    try {
      await _dio.post(
        '/change-password',
        data: {
          'password_lama':         passwordLama,
          'password_baru':         passwordBaru,
          'konfirmasi_password':   konfirmasiPassword,
        },
      );
      return (success: true, message: 'Password berhasil diubah.');
    } on DioException catch (e) {
      return (success: false, message: _parseErrorMessage(e));
    }
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  String _parseErrorMessage(DioException e) {
    try {
      final data = e.response?.data as Map<String, dynamic>?;
      if (data == null) return 'Terjadi kesalahan. Coba lagi.';

      // Laravel validation error: { "errors": { "email": ["..."] } }
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        return (errors.values.first as List).first as String;
      }

      // Laravel single message: { "message": "..." }
      return data['message'] as String? ?? 'Terjadi kesalahan. Coba lagi.';
    } catch (_) {
      return 'Terjadi kesalahan. Coba lagi.';
    }
  }
}