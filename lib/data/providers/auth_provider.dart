import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../core/utils/storage_helper.dart';

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
      status:       status ?? this.status,
      user:         user ?? this.user,
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

  /// Login — dipanggil dari LoginScreen
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
        state = AuthState(
          status: AuthStatus.authenticated,
          user:   result.user,
        );
        break;

      case LoginResult.pendingVerifikasi:
        state = AuthState(
          status:       AuthStatus.unauthenticated,
          errorMessage: result.message,
        );
        break;

      case LoginResult.invalidCredentials:
      case LoginResult.serverError:
        state = AuthState(
          status:       AuthStatus.unauthenticated,
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
      username:    username,
      email:       email,
      password:    password,
    );
    state = state.copyWith(status: AuthStatus.unauthenticated);
    return result;
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
      passwordLama:       passwordLama,
      passwordBaru:       passwordBaru,
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