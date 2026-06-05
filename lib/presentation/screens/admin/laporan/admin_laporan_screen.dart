import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '/../../data/providers/admin_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// Sesuaikan jumlah titik-titiknya dengan posisi folder Anda
import '../notifikasi/admin_akun_screen.dart';

class AdminLaporanScreen extends ConsumerStatefulWidget {
  const AdminLaporanScreen({super.key});

  @override
  ConsumerState<AdminLaporanScreen> createState() => _AdminLaporanScreenState();
}

class _AdminLaporanScreenState extends ConsumerState<AdminLaporanScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isDari) async {
    final now = DateTime.now();
    final state = ref.read(laporanAdminProvider);
    final initial = isDari
        ? DateTime.tryParse(state.dari) ?? now
        : DateTime.tryParse(state.sampai) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final formatted =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    ref
        .read(laporanAdminProvider.notifier)
        .fetch(
          dari: isDari ? formatted : null,
          sampai: !isDari ? formatted : null,
        );
  }

  // ─── FUNGSI EXPORT CSV ───────────────────────────────────────────────────────
  Future<void> _exportCSV() async {
    final state = ref.read(
      laporanAdminProvider,
    ); // Pastikan namanya sesuai provider Anda
    if (state.data == null || state.data!.transaksi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
      );
      return;
    }

    List<List<dynamic>> rows = [];
    // 1. Buat Header (Baris Pertama)
    rows.add([
      "Tanggal",
      "ID Transaksi",
      "Nama Nasabah",
      "Kategori",
      "Berat (Kg)",
      "Poin",
    ]);

    // 2. Masukkan Isi Data
    for (var t in state.data!.transaksi) {
      rows.add([
        t['tanggal'],
        t['id'],
        t['nasabah'],
        t['kategori'] ?? '-',
        t['berat_kg'] ?? 0,
        t['poin_didapat'] ?? 0,
      ]);
    }

    // 3. Ubah ke bentuk teks CSV lalu simpan ke memori HP
    String csvData = ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/Laporan_Transaksi.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    // 4. Buka menu Share agar Admin bisa mengirim ke WA atau menyimpannya
    await Share.shareXFiles([
      XFile(path),
    ], text: 'Laporan Transaksi Bank Sampah');
  }

  // ─── FUNGSI EXPORT PDF ───────────────────────────────────────────────────────
  Future<void> _exportPDF() async {
    final state = ref.read(
      laporanAdminProvider,
    ); // Pastikan namanya sesuai provider Anda
    if (state.data == null || state.data!.transaksi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
      );
      return;
    }

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan Transaksi Bank Sampah',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Periode: ${state.dari} s/d ${state.sampai}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              // Membuat Tabel PDF
              pw.TableHelper.fromTextArray(
                headers: [
                  'Tanggal',
                  'ID Transaksi',
                  'Nasabah',
                  'Kategori',
                  'Berat (Kg)',
                  'Poin',
                ],
                data: state.data!.transaksi
                    .map(
                      (t) => [
                        t['tanggal'],
                        t['id'],
                        t['nasabah'],
                        t['kategori'] ?? '-',
                        t['berat_kg']?.toString() ?? '0',
                        t['poin_didapat']?.toString() ?? '0',
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.teal800,
                ), // Warna background header
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
              ),
            ],
          );
        },
      ),
    );

    // Menampilkan layar preview PDF bawaan HP (Bisa di-print atau di-save)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Laporan_${state.dari}_${state.sampai}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(laporanAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textMain),
        title: const Text('Laporan Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(laporanAdminProvider.notifier).fetch(),
          ),
          const CustomNotifBell(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan Transaksi',
              style: AppTextStyles.headlineLg.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kelola, filter, dan unduh data transaksi harian.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Export buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportCSV,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMain,
                      side: BorderSide(
                        color: AppColors.outlineVariant.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportPDF,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Periode Dari',
                    style: AppTextStyles.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DateField(
                    value: state.dari,
                    onTap: () => _pickDate(context, true),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sampai Dengan',
                    style: AppTextStyles.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DateField(
                    value: state.sampai,
                    onTap: () => _pickDate(context, false),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(laporanAdminProvider.notifier).fetch(),
                      icon: const Icon(Icons.filter_list_rounded, size: 16),
                      label: const Text('Terapkan Filter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mintContainer,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            if (state.isLoading)
              ...List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDim,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else if (state.data != null) ...[
              _StatCard(
                label: 'Total Transaksi',
                value: '${state.data!.totalTransaksi}',
                badge: '+12% dari bulan lalu',
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(height: 10),
              _StatCard(
                label: 'Volume Terkumpul',
                value: '${state.data!.volumeKg.toStringAsFixed(0)} kg',
                badge: '+5.2% dari bulan lalu',
                icon: Icons.scale_rounded,
              ),
              const SizedBox(height: 10),
              _StatCard(
                label: 'Nilai Konversi (Poin)',
                value: '${state.data!.nilaiKonversi}',
                badge: 'Stabil bulan ini',
                icon: Icons.account_balance_wallet_rounded,
                badgeColor: AppColors.onSurfaceVariant,
                badgeIcon: null,
              ),
              const SizedBox(height: 20),

              // Tabel
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Text(
                            'Detail Transaksi',
                            style: AppTextStyles.labelMd.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 160,
                            child: TextFormField(
                              controller: _searchController,
                              style: AppTextStyles.bodySm,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Cari ID atau Nasabah...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 14,
                                  color: AppColors.outline,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 36,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.outlineVariant.withOpacity(
                                      0.4,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.outlineVariant.withOpacity(
                                      0.4,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      color: AppColors.background,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Tanggal',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'ID',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Nasabah',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rows
                    ...state.data!.transaksi
                        .where((t) {
                          final q = _searchController.text.toLowerCase();
                          if (q.isEmpty) return true;
                          return (t['id'] as String).toLowerCase().contains(
                                q,
                              ) ||
                              (t['nasabah'] as String).toLowerCase().contains(
                                q,
                              );
                        })
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.outlineVariant.withOpacity(
                                    0.25,
                                  ),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    t['tanggal'] as String,
                                    style: AppTextStyles.bodySm.copyWith(
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    t['id'] as String,
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    t['nasabah'] as String,
                                    style: AppTextStyles.bodySm.copyWith(
                                      height: 1.4,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const _DateField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surfaceWhite,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.outline,
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(
              Icons.edit_calendar_rounded,
              size: 16,
              color: AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final IconData icon;
  final Color? badgeColor;
  final IconData? badgeIcon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.badge,
    required this.icon,
    this.badgeColor,
    this.badgeIcon = Icons.trending_up_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final bc = badgeColor ?? AppColors.success;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.headlineMd.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (badgeIcon != null) ...[
                      Icon(badgeIcon, size: 12, color: bc),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      badge,
                      style: AppTextStyles.bodySm.copyWith(
                        color: bc,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mintContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
        ],
      ),
    );
  }
}
