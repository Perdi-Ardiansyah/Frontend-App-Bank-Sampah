import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../../data/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _namaCtrl      = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();

  @override
  void dispose() {
    _namaCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authProvider.notifier).register(
      namaLengkap: _namaCtrl.text.trim(),
      username:    _usernameCtrl.text.trim(),
      email:       _emailCtrl.text.trim(),
      password:    _passwordCtrl.text,
    );

    if (!mounted) return;

    if (result.success) {
      // Berhasil → redirect ke pending verification
      Navigator.pushReplacementNamed(context, '/pending');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.outlineVariant.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text('Buat Akun Baru',
                                style: AppTextStyles.headlineLg
                                    .copyWith(fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Isi detail di bawah ini untuk mendaftar\nsebagai Nasabah.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                                height: 1.6,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          AppTextField(
                            label: 'Nama Lengkap',
                            hintText: 'Masukkan nama lengkap Anda',
                            controller: _namaCtrl,
                            prefixIcon: const Icon(Icons.person_outline_rounded,
                                color: AppColors.outline, size: 20),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            label: 'Username',
                            hintText: 'pilih username',
                            controller: _usernameCtrl,
                            prefixIcon: const Icon(
                                Icons.alternate_email_rounded,
                                color: AppColors.outline,
                                size: 20),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Wajib diisi';
                              if (v.contains(' ')) return 'Username tidak boleh ada spasi';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            label: 'Email',
                            hintText: 'nama@email.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.mail_outline_rounded,
                                color: AppColors.outline, size: 20),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Wajib diisi';
                              if (!v.contains('@')) return 'Email tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            label: 'Password',
                            hintText: 'Minimal 8 karakter',
                            controller: _passwordCtrl,
                            isPassword: true,
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppColors.outline, size: 20),
                            validator: (v) => (v == null || v.length < 8)
                                ? 'Minimal 8 karakter'
                                : null,
                          ),

                          const SizedBox(height: 24),

                          AppButton(
                            label: 'Daftar',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _handleRegister,
                          ),

                          const SizedBox(height: 20),

                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Sudah memiliki akun? ',
                                    style: AppTextStyles.bodyMd.copyWith(
                                        color: AppColors.onSurfaceVariant)),
                                GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () => Navigator.pop(context),
                                  child: Text('Masuk di sini',
                                      style: AppTextStyles.labelMd
                                          .copyWith(color: AppColors.primary)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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