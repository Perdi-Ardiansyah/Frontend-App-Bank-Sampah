import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '/../../core/network/api_client.dart';
import 'lupa_sandi_screen.dart'; // Sesuaikan letaknya jika Anda menyimpannya di sub-folder

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(authProvider.notifier)
        .login(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    switch (result) {
      case LoginResult.successNasabah:
        Navigator.pushReplacementNamed(context, '/home');
        break;

      case LoginResult.successAdmin:
        Navigator.pushReplacementNamed(context, '/admin-home');
        break;

      case LoginResult.pendingVerifikasi:
        Navigator.pushReplacementNamed(context, '/pending');
        break;

      case LoginResult.invalidCredentials:
      case LoginResult.serverError:
        final msg = ref.read(authProvider).errorMessage ?? 'Terjadi kesalahan.';
        _showErrorSnackbar(msg);
        break;
    }
  }

  Future<void> simpanFcmTokenKeServer() async {
    try {
      // 1. Minta izin notifikasi ke HP
      await FirebaseMessaging.instance.requestPermission();

      // 2. Ambil token "Alamat HP" dari Google
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        print('🚀 FCM Token HP ini: $fcmToken');

        // 3. Kirim ke Laravel agar disimpan di database
        await ApiClient.instance.post(
          '/update-fcm-token',
          data: {'fcm_token': fcmToken},
        );
      }
    } catch (e) {
      print('Gagal mengirim token FCM: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Logo & Brand
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Bank Sampah',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 52),

                Text(
                  'Selamat Datang',
                  style: AppTextStyles.headlineXl.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk ke akun Anda untuk mulai mengelola\ntabungan sampah hari ini.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 36),

                AppTextField(
                  label: 'Nama Pengguna atau Email',
                  hintText: 'Masukkan nama pengguna',
                  controller: _usernameCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.outline,
                    size: 20,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Kata Sandi',
                  hintText: 'Masukkan kata sandi',
                  controller: _passwordCtrl,
                  isPassword: true,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.outline,
                    size: 20,
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: isLoading
                                ? null
                                : (v) =>
                                      setState(() => _rememberMe = v ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(
                              color: AppColors.outline.withOpacity(0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ingat saya',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
  onPressed: () {
    Navigator.push(
      context,
      // 👇 Hapus kata 'const' di baris ini
      MaterialPageRoute(builder: (context) => LupaSandiScreen()), 
    );
  },
  child: Text(
    'Lupa Sandi?',
    style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
  ),
),
                  ],
                ),

                const SizedBox(height: 28),

                AppButton(
                  label: 'Masuk',
                  onPressed: isLoading ? null : _handleLogin,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'atau',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  ],
                ),

                const SizedBox(height: 24),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Daftar Sekarang',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
