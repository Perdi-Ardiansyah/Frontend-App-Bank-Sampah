import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Sesuaikan path import di bawah ini dengan struktur folder Anda
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../data/providers/auth_provider.dart';

class AuthCheckerScreen extends ConsumerStatefulWidget {
  const AuthCheckerScreen({super.key});

  @override
  ConsumerState<AuthCheckerScreen> createState() => _AuthCheckerScreenState();
}

class _AuthCheckerScreenState extends ConsumerState<AuthCheckerScreen> {
  @override
  void initState() {
    super.initState();
    // Memastikan frame pertama selesai digambar sebelum memicu fungsi navigasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _periksaSessionLog();
    });
  }

  Future<void> _periksaSessionLog() async {
    // 1. Ambil token dari local storage secure
    final token = await StorageHelper.getToken();

    if (token != null && token.isNotEmpty) {
      try {
        // 2. Tarik data profil user terbaru dari API Laravel
        await ref.read(authProvider.notifier).fetchUserProfile(); 

        // 3. Ambil data user yang sudah di-update di provider
        final user = ref.read(currentUserProvider);

        if (!mounted) return;

        // 4. Arahkan ke halaman utama berdasarkan Role
        // (Pastikan pengecekan role sesuai dengan tipe data di Laravel Anda: int atau String)
        if (user?.role == 'admin' || user?.role == '1' || user?.role == 1) {
          Navigator.pushReplacementNamed(context, '/admin-main');
        } else {
          Navigator.pushReplacementNamed(context, '/nasabah-main');
        }
      } catch (e) {
        // Jika token tidak valid/expired di server, bersihkan storage dan minta login ulang
        print('🚨 Sesi berakhir atau token tidak valid: $e');
        await StorageHelper.clearAll();
        
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // Jika token memang kosong dari awal, langsung arahkan ke halaman login
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }
}