import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../core/utils/storage_helper.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart'; // Sesuaikan path-nya jika folder Anda berbeda
// ── State ──────────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ── Notifier ───────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkExistingSession();
  }

  // 👇 TAMBAHKAN FUNGSI INI DI DALAM class AuthNotifier 👇

  /// Memperbarui data user secara lokal di UI dan di Storage secara instan
  void updateLocalUser({String? namaLengkap, String? email, String? noHp}) {
    if (state.user == null) return; // Pastikan user sedang login

    final oldUser = state.user!;
    final newUser = UserModel(
      id: oldUser.id,
      username: oldUser.username, // 👈 TAMBAHKAN BARIS INI
      idNasabah: oldUser.idNasabah,
      fotoUrl: oldUser.fotoUrl,
      role: oldUser.role,
      isVerified: oldUser.isVerified,
      totalPoin: oldUser.totalPoin,
      namaLengkap: namaLengkap ?? oldUser.namaLengkap,
      email: email ?? oldUser.email,
      noHp: noHp ?? oldUser.noHp,
    );

    // 1. Update state UI agar layar langsung berubah
    state = state.copyWith(user: newUser);

    // 2. Timpa data user di Storage agar tetap awet saat aplikasi ditutup
    StorageHelper.saveUserObject(newUser.toJsonString());
  }

  // 👆 SAMPAI SINI 👆

  Future<bool> updateProfilTeks({
    required String namaLengkap,
    required String email,
    required String noHp,
  }) async {
    try {
      final res = await ApiClient.instance.post(
        '/user/update-profil',
        data: {'nama_lengkap': namaLengkap, 'email': email, 'no_hp': noHp},
      );

      // 👇 TAMBAHKAN BARIS INI 👇
      // Agar teks profil di layar langsung berubah tanpa perlu fetch ulang
      updateLocalUser(namaLengkap: namaLengkap, email: email, noHp: noHp);

      return true;
    } catch (e) {
      print('🚨 ERROR UPDATE PROFIL: $e');
      return false;
    }
  }

  Future<bool> updateFotoProfil(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final res = await ApiClient.instance.post(
        '/user/update-foto',
        data: formData,
      );

      // BARIS FETCH DIHAPUS DARI SINI
      await fetchUserProfile();
      return true;
    } catch (e) {
      print('🚨 ERROR UPLOAD FOTO: $e');
      return false;
    }
  }

  /// Cek apakah ada sesi tersimpan saat app pertama dibuka
  Future<void> _checkExistingSession() async {
    final isLoggedIn = await StorageHelper.isLoggedIn();
    if (!isLoggedIn) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    // Ada token — load data user dari storage
    final userJson = await StorageHelper.getUserObject();
    if (userJson != null) {
      final user = UserModel.fromJsonString(userJson);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Return LoginResult agar screen bisa navigasi sesuai hasilnya
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _authService.login(
      username: username,
      password: password,
    );

    switch (result.result) {
      case LoginResult.successAdmin:
      case LoginResult.successNasabah:
        state = AuthState(status: AuthStatus.authenticated, user: result.user);
        break;

      case LoginResult.pendingVerifikasi:
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: result.message,
        );
        break;

      case LoginResult.invalidCredentials:
      case LoginResult.serverError:
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: result.message,
        );
        break;
    }

    return result.result;
  }

  /// Register — dipanggil dari RegisterScreen
  Future<({bool success, String message})> register({
    required String namaLengkap,
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _authService.register(
      namaLengkap: namaLengkap,
      username: username,
      email: email,
      password: password,
    );
    state = state.copyWith(status: AuthStatus.unauthenticated);
    return result;
  }

  /// Tarik data user terbaru dari backend (Berguna untuk auto-login / refresh)
  Future<bool> fetchUserProfile() async {
    try {
      // Pastikan endpoint '/user/me' atau '/profil' sesuai dengan route di Laravel Anda
      final response = await ApiClient.instance.get('/user/me');

      // Sesuaikan 'data' dengan bentuk JSON response dari Laravel Anda
      final userData = response.data['data'];

      // Ubah JSON dari API menjadi UserModel
      final updatedUser = UserModel.fromJson(userData);

      // 1. Perbarui state di UI
      state = state.copyWith(
        user: updatedUser,
        status: AuthStatus.authenticated,
      );

      // 2. Timpa data lama di storage lokal agar tetap awet
      await StorageHelper.saveUserObject(updatedUser.toJsonString());

      return true;
    } catch (e) {
      print('🚨 ERROR FETCH PROFILE: $e');
      // Jika error 401 (token mati), Interceptor di api_client.dart Anda otomatis
      // akan menghapus token dan melempar user ke halaman login.
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Ganti password
  Future<({bool success, String message})> changePassword({
    required String passwordLama,
    required String passwordBaru,
    required String konfirmasiPassword,
  }) async {
    return _authService.changePassword(
      passwordLama: passwordLama,
      passwordBaru: passwordBaru,
      konfirmasiPassword: konfirmasiPassword,
    );
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

/// Provider untuk AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider utama untuk auth state — gunakan ini di semua screen
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

/// Shortcut: ambil user yang sedang login
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

/// Shortcut: cek apakah user adalah admin
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isAdmin ?? false;
});
