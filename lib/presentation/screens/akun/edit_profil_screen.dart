import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class EditProfilScreen extends ConsumerStatefulWidget {
  const EditProfilScreen({super.key});

  @override
  ConsumerState<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends ConsumerState<EditProfilScreen> {
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi field form secara otomatis dengan data user saat ini
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _namaCtrl.text = user.namaLengkap;
      _emailCtrl.text = user.email;
      _noHpCtrl.text = user.noHp ?? ''; //
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _noHpCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_namaCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _noHpCtrl.text.isEmpty) {
      _showSnackbar('Semua field wajib diisi.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final ok = await ref.read(authProvider.notifier).updateProfilTeks(
          namaLengkap: _namaCtrl.text,
          email: _emailCtrl.text,
          noHp: _noHpCtrl.text,
        );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (ok) {
      // 👇 PANGGIL FUNGSI REFRESH KITA DI SINI
      ref.read(authProvider.notifier).updateLocalUser(
        namaLengkap: _namaCtrl.text,
        email: _emailCtrl.text,
        noHp: _noHpCtrl.text,
      );

      _showSnackbar('Profil Anda berhasil diperbarui!');
      Navigator.pop(context); // Kembali ke halaman Akun, dan BOOM! Data langsung berubah
    } else {
      _showSnackbar('Gagal memperbarui profil. Periksa data kembali.', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textMain),
        title: const Text('Edit Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Pribadi',
              style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Pastikan email dan nomor HP Anda tetap aktif untuk menerima pemberitahuan.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 24),
            
            AppTextField(
              label: 'Nama Lengkap',
              hintText: 'Masukkan nama lengkap Anda',
              controller: _namaCtrl,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Alamat Email',
              hintText: 'contoh@email.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Nomor HP',
              hintText: 'Contoh: 08123456789',
              controller: _noHpCtrl,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            
            AppButton(
              label: 'Simpan Perubahan',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}