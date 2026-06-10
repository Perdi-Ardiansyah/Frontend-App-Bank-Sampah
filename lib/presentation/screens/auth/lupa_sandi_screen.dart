import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '/../../core/network/api_client.dart'; // Sesuaikan path jika perlu
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class LupaSandiScreen extends StatefulWidget {
  const LupaSandiScreen({super.key});

  @override
  State<LupaSandiScreen> createState() => _LupaSandiScreenState();
}

class _LupaSandiScreenState extends State<LupaSandiScreen> {
  // Pengontrol Langkah (1 = Email, 2 = OTP, 3 = Password Baru)
  int _currentStep = 1;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── 1. API: KIRIM OTP ──
  Future<void> _kirimOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar('Email wajib diisi!', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Pastikan endpoint '/kirim-otp' sesuai dengan route di Laravel Anda
      final res = await ApiClient.instance.post('/kirim-otp', data: {'email': email});
      _showSnackbar(res.data['message'] ?? 'OTP berhasil dikirim!');
      setState(() => _currentStep = 2); // Pindah ke layar OTP
    } catch (e) {
      String err = 'Gagal mengirim OTP.';
      if (e is DioException && e.response != null) {
        err = e.response?.data['message'] ?? err;
      }
      _showSnackbar(err, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── 2. API: VERIFIKASI OTP ──
  Future<void> _verifikasiOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showSnackbar('Kode OTP wajib diisi!', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance.post('/verifikasi-otp', data: {
        'email': _emailController.text.trim(),
        'otp': otp,
      });
      _showSnackbar(res.data['message'] ?? 'OTP Valid!');
      setState(() => _currentStep = 3); // Pindah ke layar Password Baru
    } catch (e) {
      String err = 'Kode OTP salah.';
      if (e is DioException && e.response != null) {
        err = e.response?.data['message'] ?? err;
      }
      _showSnackbar(err, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── 3. API: RESET PASSWORD ──
  Future<void> _resetPassword() async {
    final pw = _newPasswordController.text.trim();
    final confirmPw = _confirmPasswordController.text.trim();

    if (pw.length < 8) {
      _showSnackbar('Password minimal 8 karakter!', isError: true);
      return;
    }
    if (pw != confirmPw) {
      _showSnackbar('Konfirmasi password tidak cocok!', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance.post('/reset-password', data: {
        'email': _emailController.text.trim(),
        'otp': _otpController.text.trim(),
        'password': pw,
        'password_confirmation': confirmPw,
      });
      
      _showSnackbar(res.data['message'] ?? 'Password berhasil diubah!');
      
      // Tunggu sebentar lalu kembali ke layar Login
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context); 

    } catch (e) {
      String err = 'Gagal mereset password.';
      if (e is DioException && e.response != null) {
        err = e.response?.data['message'] ?? err;
      }
      _showSnackbar(err, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.textMain),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.mintContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 24),
              Text(
                _currentStep == 1 ? 'Lupa Kata Sandi?' 
                : _currentStep == 2 ? 'Verifikasi OTP' 
                : 'Buat Sandi Baru',
                style: AppTextStyles.headlineLg.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                _currentStep == 1 ? 'Jangan khawatir! Masukkan email yang terdaftar, kami akan mengirimkan kode OTP untuk mereset sandi Anda.'
                : _currentStep == 2 ? 'Kami telah mengirimkan 6 digit kode OTP ke email ${_emailController.text}. Silakan cek kotak masuk atau folder spam Anda.'
                : 'Buat kata sandi baru yang kuat dan mudah Anda ingat agar akun Anda aman.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 32),

              // ── FORM STEP 1: EMAIL ──
              if (_currentStep == 1) ...[
                AppTextField(
                  label: 'Alamat Email',
                  hintText: 'contoh: nama@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Kirim Kode OTP',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _kirimOtp,
                ),
              ],

              // ── FORM STEP 2: OTP ──
              if (_currentStep == 2) ...[
                AppTextField(
                  label: 'Kode OTP (6 Digit)',
                  hintText: 'Masukkan angka',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.pin_rounded),
                  // maxLength: 6,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Verifikasi Kode',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _verifikasiOtp,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => setState(() => _currentStep = 1),
                    child: Text('Salah ketik email? Kembali', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary)),
                  ),
                ),
              ],

              // ── FORM STEP 3: PASSWORD BARU ──
              if (_currentStep == 3) ...[
                AppTextField(
                  label: 'Kata Sandi Baru',
                  hintText: 'Minimal 8 karakter',
                  controller: _newPasswordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Konfirmasi Kata Sandi',
                  hintText: 'Ulangi sandi baru Anda',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Simpan Kata Sandi',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _resetPassword,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}