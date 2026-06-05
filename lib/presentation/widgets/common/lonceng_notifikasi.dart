import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/nasabah_provider.dart';
// Sesuaikan import ini ke lokasi file NotifikasiScreen Anda yang baru
import '../../screens/notifikasi/notifikasi_screen.dart'; 

class LoncengNotifikasi extends ConsumerWidget {
  const LoncengNotifikasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotifCountProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textMain, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotifikasiScreen()),
            );
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 12, top: 12,
            child: Container(
              width: 9, height: 9,
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}