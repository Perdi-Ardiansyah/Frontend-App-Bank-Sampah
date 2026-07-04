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
    try {
      final token = await StorageHelper.getToken();

      if (token != null && token.isNotEmpty) {
        final userJson = await StorageHelper.getUserObject();

        if (userJson != null) {
          // Biarkan jalan di latar belakang, abaikan jika gagal jaringan
          ref.read(authProvider.notifier).fetchUserProfile().catchError((_) => false);

          final role = await StorageHelper.getRole();
          
          if (!mounted) return;

          // ⚠️ PERHATIKAN BAGIAN INI: 
          // Pastikan '/admin-main' dan '/nasabah-main' benar-benar 
          // terdaftar persis seperti ini di rute MaterialApp (main.dart) Anda!
          if (role == 'admin' || role == '1') {
            Navigator.pushReplacementNamed(context, '/admin-home');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
          return; // Selesai dan keluar dari fungsi
        }
      } 
      
      // Jika token/userJson kosong, paksa ke login
      if (!mounted) return;
      await StorageHelper.clearAll();
      Navigator.pushReplacementNamed(context, '/login');

    } catch (e) {
      // 👇 INI PENYELAMATNYA 👇
      // Jika terjadi error apa pun (memori rusak, bug, dll),
      // tangkap errornya dan paksa kembali ke halaman login agar tidak stuck!
      print('🚨 ERROR FATAL DI AUTH CHECKER: $e');
      if (!mounted) return;
      await StorageHelper.clearAll();
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