import 'dart:io';
import 'package:bank_sampah_fiks/core/utils/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Tambahan untuk baca token
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '/../../data/providers/admin_provider.dart';


class AdminLaporanScreen extends ConsumerWidget {
  const AdminLaporanScreen({super.key});

  // Fungsi untuk menampilkan Date Range Picker
  Future<void> _pilihTanggal(BuildContext context, WidgetRef ref, LaporanAdminState state) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: DateTime.parse(state.dari),
        end: DateTime.parse(state.sampai),
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final dariStr = picked.start.toString().split(' ')[0];
      final sampaiStr = picked.end.toString().split(' ')[0];
      ref.read(laporanAdminProvider.notifier).fetch(dari: dariStr, sampai: sampaiStr);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laporanState = ref.watch(laporanAdminProvider);
    final report = laporanState.data;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Laporan Bank Sampah'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range_rounded, color: AppColors.primary),
              tooltip: 'Filter Tanggal',
              onPressed: () => _pilihTanggal(context, ref, laporanState),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.outline,
            labelStyle: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Setoran'),
              Tab(text: 'Tukar Cash'),
              Tab(text: 'Tukar Sembako'),
            ],
          ),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.read(laporanAdminProvider.notifier).fetch(),
          child: laporanState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : report == null
                  ? const Center(child: Text('Gagal memuat atau data kosong.'))
                  : TabBarView(
                      children: [
                        // TAB 1: SETORAN
                        _LaporanTabContent(
                          title: 'Tabel Rekap Setoran',
                          tipeLaporan: 'setoran',
                          dari: laporanState.dari,
                          sampai: laporanState.sampai,
                          columns: const ['Tanggal', 'Nasabah', 'Kategori', 'Massa', 'Poin'],
                          items: report.setoran,
                          rowBuilder: (item) => [
                            DataCell(Text(item['tanggal'] ?? '-')),
                            DataCell(Text(item['nasabah'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(item['kategori'] ?? '-')),
                            DataCell(Text(item['berat'] ?? '-')),
                            DataCell(Text(item['poin'] ?? '-', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        // TAB 2: TUKAR CASH
                        _LaporanTabContent(
                          title: 'Tabel Rekap Pencairan',
                          tipeLaporan: 'cash',
                          dari: laporanState.dari,
                          sampai: laporanState.sampai,
                          columns: const ['Tanggal', 'Nasabah', 'Metode', 'Nominal'],
                          items: report.tukarCash,
                          rowBuilder: (item) => [
                            DataCell(Text(item['tanggal'] ?? '-')),
                            DataCell(Text(item['nasabah'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(item['metode'] ?? '-')),
                            DataCell(Text(item['nominal'] ?? '-', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        // TAB 3: TUKAR SEMBAKO
                        _LaporanTabContent(
                          title: 'Tabel Rekap Sembako',
                          tipeLaporan: 'produk',
                          dari: laporanState.dari,
                          sampai: laporanState.sampai,
                          columns: const ['Tanggal', 'Nasabah', 'Produk', 'Jumlah', 'Poin'],
                          items: report.tukarSembako,
                          rowBuilder: (item) => [
                            DataCell(Text(item['tanggal'] ?? '-')),
                            DataCell(Text(item['nasabah'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(item['produk'] ?? '-')),
                            DataCell(Text(item['jumlah'] ?? '-')),
                            DataCell(Text(item['poin'] ?? '-', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _LaporanTabContent extends StatelessWidget {
  final String title;
  final String tipeLaporan;
  final String dari;
  final String sampai;
  final List<String> columns;
  final List<dynamic> items;
  final List<DataCell> Function(Map<String, dynamic>) rowBuilder;

  const _LaporanTabContent({
    required this.title,
    required this.tipeLaporan,
    required this.dari,
    required this.sampai,
    required this.columns,
    required this.items,
    required this.rowBuilder,
  });

  // ── FUNGSI UNDUH BERKAS LANGSUNG (TANPA BROWSER) ──
  // ── FUNGSI UNDUH BERKAS LANGSUNG (TANPA BROWSER) ──
  Future<void> _unduhBerkas(BuildContext context, String format) async {
    const String baseUrl = 'http://10.0.2.2:8000/api/admin'; 
    final String urlEndpoint = '$baseUrl/laporan/$format?tipe=$tipeLaporan&dari=$dari&sampai=$sampai';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      // 👇 MENGGUNAKAN STORAGE HELPER MILIK ANDA SENDIRI 👇
      final String? token = await StorageHelper.getToken(); 

      if (token == null || token.isEmpty) {
        throw Exception("Token tidak ditemukan. Silakan login ulang.");
      }

      Dio dio = Dio();
      Directory? directory;
      
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final String ekstensi = format == 'excel' ? 'xlsx' : 'pdf';
      final String namaFile = "Laporan_${tipeLaporan}_${DateTime.now().millisecondsSinceEpoch}.$ekstensi";
      final String savePath = "${directory!.path}/$namaFile";

      // Header dengan token yang sudah pasti valid
      await dio.download(
        urlEndpoint, 
        savePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', 
            'Accept': 'application/json',
          },
        ),
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil disimpan di: $savePath'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'Buka',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(savePath),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh laporan: $e'), backgroundColor: AppColors.error),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('Periode: $dari s/d $sampai', style: const TextStyle(fontSize: 11, color: AppColors.outline)),
                ],
              ),
            ),
            Row(
              children: [
                _ExportBtn(
                  icon: Icons.description_rounded,
                  color: Colors.green,
                  tooltip: 'Unduh Excel',
                  onTap: () => _unduhBerkas(context, 'excel'), // 👈 Pemanggilan fungsi sudah diperbaiki
                ),
                const SizedBox(width: 8),
                _ExportBtn(
                  icon: Icons.picture_as_pdf_rounded,
                  color: Colors.red,
                  tooltip: 'Unduh PDF',
                  onTap: () => _unduhBerkas(context, 'pdf'), // 👈 Pemanggilan fungsi sudah diperbaiki
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),

        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: Text('Tidak ada data transaksi untuk periode ini.')),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35)),
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.55, 
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.background),
                    horizontalMargin: 12,
                    columnSpacing: 24,
                    columns: columns
                        .map((colName) => DataColumn(
                              label: Text(
                                colName,
                                style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMain),
                              ),
                            ))
                        .toList(),
                    rows: items.map((itemData) {
                      return DataRow(cells: rowBuilder(itemData as Map<String, dynamic>));
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExportBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ExportBtn({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}