import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '/../../data/providers/admin_provider.dart';
import '../laporan/admin_laporan_screen.dart';
import '../verifikasi/admin_verifikasi_screen.dart';
import '../pencairan/admin_pencairan_screen.dart';
import '../kategori/admin_kategori_screen.dart';
import '../produk/admin_produk_screen.dart';
// Sesuaikan jumlah titik-titiknya dengan posisi folder Anda
import '../notifikasi/admin_akun_screen.dart';

class AdminBerandaScreen extends ConsumerWidget {
  final void Function(int)? onNavigate;
  const AdminBerandaScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardAdminProvider);

    print('==== CEK DATA DARI SERVER ====');
    print('Grafik: ${state.data?.grafikMingguan}');
    print('==============================');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Bank Sampah'),
        actions: const [
          CustomNotifBell(),
          SizedBox(width: 8), // Sedikit jarak
        ],
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'A',
                style: AppTextStyles.bodySm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(dashboardAdminProvider.notifier).fetch(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Selamat Datang,\nSuper Admin',
                        style: AppTextStyles.headlineXl.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Berikut adalah ringkasan aktivitas bank sampah hari ini.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Menu Grid
                      Text(
                        'MENU MANAJEMEN',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.95,
                        children: [
                          _MenuTile(
                            icon: Icons.wallet_rounded,
                            label: 'Harga\nSampah',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminKategoriScreen(),
                              ),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.how_to_reg_rounded,
                            label: 'Verifikasi',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminVerifikasiScreen(),
                              ),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.task_alt_rounded,
                            label: 'Approval',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminPencairanScreen(),
                              ),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.bar_chart_rounded,
                            label: 'Laporan',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminLaporanScreen(),
                              ),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.manage_history_rounded,
                            label: 'Log Aktivitas',
                            onTap: () => onNavigate?.call(1),
                          ),
                          _MenuTile(
                            icon: Icons.inventory_2_rounded,
                            label: 'Produk',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminProdukScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // 👇 GRAFIK DIPASANG DI SINI (PASTI MUNCUL) 👇
                      // 👇 GRAFIK DIPASANG DI SINI 👇
                      // 👇 GRAFIK DIPASANG DI SINI 👇
                      _WeeklyStatChart(
                        nasabahAktif:
                            state.data?.totalNasabah.toString() ?? '0',

                        // Ubah ini agar mengambil data TRANSAKSI yang sebenarnya
                        transaksiHariIni:
                            state.data?.setoranHariIniTransaksi.toString() ??
                            '0',

                        // Ubah ini agar mengambil data KG yang sebenarnya
                        setoranHariIni:
                            state.data?.setoranHariIniKg.toString() ?? '0',

                        grafikMingguan: state.data?.grafikMingguan,
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'RINGKASAN KESELURUHAN',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (state.isLoading)
                        ...List.generate(
                          4,
                          (_) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              height: 88,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDim,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        )
                      else if (state.data != null) ...[
                        _StatCard(
                          icon: Icons.group_rounded,
                          iconBg: AppColors.primary,
                          label: 'Total Nasabah',
                          value: state.data!.totalNasabahFormatted,
                          badge: '+${state.data!.nasabahHariIni} hari ini',
                          badgeColor: AppColors.success,
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          icon: Icons.star_rounded,
                          iconBg: AppColors.warning,
                          label: 'Total Poin Beredar',
                          value: state.data!.totalPoinBeredarFormatted,
                          badge:
                              'Senilai ~Rp ${(state.data!.totalPoinBeredar / 1000).toStringAsFixed(0)}rb',
                          badgeColor: AppColors.onSurfaceVariant,
                          badgeIcon: null,
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          icon: Icons.recycling_rounded,
                          iconBg: AppColors.secondary,
                          label: 'Total Sampah Terkumpul',
                          value: state.data!.totalSampahKgFormatted,
                          badge: 'Hari ini: ${state.data!.setoranHariIniKg} kg',
                          badgeColor: AppColors.success,
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          icon: Icons.pending_actions_rounded,
                          iconBg: AppColors.error,
                          label: 'Menunggu Verifikasi',
                          value: '${state.data!.menungguVerifikasi}',
                          badge: 'Segera proses',
                          badgeColor: AppColors.error,
                        ),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String value;
  final String badge;
  final Color badgeColor;
  final IconData? badgeIcon;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
    this.badgeIcon = Icons.trending_up_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineLg.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (badgeIcon != null) ...[
                Icon(badgeIcon, size: 14, color: badgeColor),
                const SizedBox(width: 4),
              ],
              Text(
                badge,
                style: AppTextStyles.bodySm.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyStatChart extends StatelessWidget {
  final String nasabahAktif;
  final String transaksiHariIni;
  final String setoranHariIni;
  final List<dynamic>? grafikMingguan; // 👈 Wajib ada penangkap ini

  const _WeeklyStatChart({
    Key? key,
    required this.nasabahAktif,
    required this.transaksiHariIni,
    required this.setoranHariIni,
    this.grafikMingguan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ALAT SADAP UI (Cek log terminal setelah di-refresh)
    print('💡 [UI] Data masuk ke grafik: $grafikMingguan');

    // 1. Tangkap data dari server, jadikan array kosong jika null
    final List<dynamic> rawData = grafikMingguan ?? [];

    // 2. Mesin konversi baja ringan (Aman dari tipe data aneh)
    List<Map<String, dynamic>> chartData = [];

    if (rawData.isNotEmpty) {
      chartData = rawData.map((item) {
        // Ekstrak dengan sangat hati-hati
        double beratAngka = 0.0;
        if (item['berat'] != null) {
          beratAngka = double.tryParse(item['berat'].toString()) ?? 0.0;
        }

        return {'day': item['day']?.toString() ?? '-', 'berat': beratAngka};
      }).toList();
    } else {
      // Jika kosong, tampilkan 0
      chartData = [
        {'day': 'Sen', 'berat': 0.0},
        {'day': 'Sel', 'berat': 0.0},
        {'day': 'Rab', 'berat': 0.0},
        {'day': 'Kam', 'berat': 0.0},
        {'day': 'Jum', 'berat': 0.0},
        {'day': 'Sab', 'berat': 0.0},
        {'day': 'Min', 'berat': 0.0},
      ];
    }

    // 3. Cari Nilai Tertinggi untuk proporsi tinggi batang
    double maxBerat = 0.1;
    for (var item in chartData) {
      double berat = item['berat'] as double;
      if (berat > maxBerat) {
        maxBerat = berat;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistik Aktivitas',
                style: AppTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '7 Hari Terakhir',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Stats
          Row(
            children: [
              _buildMiniStat('Nasabah', nasabahAktif, 'Aktif'),
              Container(
                width: 1,
                height: 30,
                color: AppColors.outlineVariant.withOpacity(0.5),
              ),
              _buildMiniStat('Transaksi', transaksiHariIni, 'Selesai'),
              Container(
                width: 1,
                height: 30,
                color: AppColors.outlineVariant.withOpacity(0.5),
              ),
              _buildMiniStat('Volume', setoranHariIni, 'Kg'),
            ],
          ),

          const SizedBox(height: 28),

          // Susunan Grafik Batang Dinamis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.map((data) {
              double nilaiBerat = data['berat'] as double;
              double persentaseTinggi = (nilaiBerat / maxBerat).clamp(0.0, 1.0);

              if (nilaiBerat == 0) persentaseTinggi = 0.02;

              return Column(
                children: [
                  if (nilaiBerat > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        nilaiBerat >= 10
                            ? nilaiBerat.toStringAsFixed(0)
                            : nilaiBerat.toStringAsFixed(1),
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 9,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                  Container(
                    width: 14,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDim,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: persentaseTinggi,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['day'].toString(),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, String unit) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: 22,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
