import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '/../../data/providers/nasabah_provider.dart';
import '/../../data/models/produk_model.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/lonceng_notifikasi.dart';
import '../../../../core/network/api_client.dart'; // Sesuaikan path jika perlu


class TukarScreen extends ConsumerStatefulWidget {
  const TukarScreen({super.key});

  @override
  ConsumerState<TukarScreen> createState() => _TukarScreenState();
}

class _TukarScreenState extends ConsumerState<TukarScreen> {
  final _nominalController = TextEditingController();
  final _noRekController = TextEditingController(); // 👈 Tambahkan ini

  // State untuk melacak pilihan metode pencairan
  String _selectedMetode = 'Cash'; // 'Cash' atau 'Transfer'
  String _selectedTipeTransfer = 'Bank'; // 'Bank' atau 'e-Wallet'
  String? _selectedNamaBankEwallet;

  // Daftar opsi Bank dan e-Wallet
  final List<String> _listBank = ['BCA', 'Mandiri', 'BNI', 'BRI', 'BSI'];
  final List<String> _listEwallet = ['Dana', 'Gopay', 'OVO', 'LinkAja', 'ShopeePay'];

  @override
  void dispose() {
    _nominalController.dispose();
    _noRekController.dispose(); // 👈 Tambahkan ini
    super.dispose();
  }

  Future<void> _handleTukarCash() async {
    final nominal = int.tryParse(_nominalController.text.replaceAll('.', '').trim());
    if (nominal == null || nominal <= 0) {
      _showSnackbar('Masukkan nominal yang valid.', isError: true);
      return;
    }
    if (nominal < 10000) {
      _showSnackbar('Minimum pencairan Rp 10.000.', isError: true);
      return;
    }

    // Validasi tambahan untuk metode Transfer
    if (_selectedMetode == 'Transfer') {
      if (_selectedNamaBankEwallet == null) {
        _showSnackbar('Silakan pilih Bank atau e-Wallet tujuan.', isError: true);
        return;
      }
      if (_noRekController.text.trim().isEmpty) {
        _showSnackbar('Nomor rekening atau nomor HP wajib diisi.', isError: true);
        return;
      }
    }

    final ok = await ref.read(tukarProvider.notifier).tukarCash(
          nominal: nominal,
          metode: _selectedMetode,
          tipeTransfer: _selectedMetode == 'Transfer' ? _selectedTipeTransfer : null,
          namaBankEwallet: _selectedMetode == 'Transfer' ? _selectedNamaBankEwallet : null,
          nomorRekening: _selectedMetode == 'Transfer' ? _noRekController.text.trim() : null,
        );

    if (!mounted) return;
    if (ok) {
      _nominalController.clear();
      _noRekController.clear();
      setState(() {
        _selectedNamaBankEwallet = null;
        _selectedMetode = 'Cash';
      });
      _showSnackbar('Permintaan pencairan berhasil dikirim!');
    } else {
      final err = ref.read(tukarProvider).error;
      _showSnackbar(err ?? 'Gagal melakukan pencairan.', isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tukarProvider);
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Bank Sampah',
          style: AppTextStyles.headlineMd.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          const LoncengNotifikasi(), 
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(tukarProvider.notifier).fetchProduk(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saldo Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF004D35), Color(0xFF006948)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Poin Anda',
                      style: AppTextStyles.bodySm.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dashboard.totalPoinFormatted,
                          style: AppTextStyles.dataDisplay.copyWith(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Pts',
                            style: AppTextStyles.bodyLg.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tarik Tunai
              Text(
                'Tarik Tunai',
                style: AppTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pencairan Dana', style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Tukar poin Anda menjadi uang tunai langsung atau transfer digital. Minimum penukaran 10.000 Pts (Rp 10.000).',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                    ),
                    const SizedBox(height: 16),

                    // ── PILIHAN METODE (CASH / TRANSFER) ──
                    Text('Metode Pencairan', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Cash', 'Transfer'].map((m) {
                        final isSelected = _selectedMetode == m;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(m),
                            selected: isSelected,
                            onSelected: (_) => setState(() {
                              _selectedMetode = m;
                              _selectedNamaBankEwallet = null; // Reset sub-pilihan
                            }),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textMain,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // ── FORM KONDISIONAL JIKA TRANSFER DIPILIH ──
                    if (_selectedMetode == 'Transfer') ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text('Tipe Transfer', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Bank', 'e-Wallet'].map((t) {
                          final isSelected = _selectedTipeTransfer == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(t),
                              selected: isSelected,
                              onSelected: (_) => setState(() {
                                _selectedTipeTransfer = t;
                                _selectedNamaBankEwallet = null; // Reset nama bank
                              }),
                              selectedColor: AppColors.secondary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textMain,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      
                      // Dropdown Pilih Bank atau e-Wallet
                      DropdownButtonFormField<String>(
                        value: _selectedNamaBankEwallet,
                        hint: Text(_selectedTipeTransfer == 'Bank' ? 'Pilih Bank Tujuan' : 'Pilih e-Wallet Tujuan'),
                        style: AppTextStyles.bodyMd,
                        items: (_selectedTipeTransfer == 'Bank' ? _listBank : _listEwallet)
                            .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedNamaBankEwallet = val),
                      ),
                      const SizedBox(height: 14),
                      
                      // Input Nomor Rekening / Nomor HP
                      TextFormField(
                        controller: _noRekController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyMd,
                        decoration: InputDecoration(
                          hintText: _selectedTipeTransfer == 'Bank' ? 'Masukkan nomor rekening' : 'Masukkan nomor HP e-Wallet (contoh: 0812...)',
                          prefixIcon: const Icon(Icons.pin_rounded, size: 20),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nominalController,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Nominal pencairan',
                        prefixText: 'Rp  ',
                        prefixStyle: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Tarik Dana',
                      isLoading: state.isSubmitting,
                      prefixIcon: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
                      onPressed: state.isSubmitting ? null : _handleTukarCash,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tukar Sembako
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tukar Sembako',
                    style: AppTextStyles.headlineMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Tersedia',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.successText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Produk list
              if (state.isLoading)
                ...List.generate(
                  2,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
              else if (state.produk.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  alignment: Alignment.center,
                  child: Text(
                    'Belum ada produk tersedia.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...state.produk.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProdukCard(
                      produk: p,
                      isSubmitting: state.isSubmitting,
                      totalPoin: dashboard.totalPoin,
                      onTukar: (qty) async {
                        final ok = await ref
                            .read(tukarProvider.notifier)
                            .tukarProduk(produkId: p.id, jumlah: qty);
                        if (!mounted) return;
                        if (ok) {
                          _showSnackbar('Penukaran berhasil!');
                        } else {
                          final err = ref.read(tukarProvider).error;
                          // Saldo tidak cukup → tampilkan dialog
                          if (err != null &&
                              err.toLowerCase().contains('cukup')) {
                            _showInsufficientDialog();
                          } else {
                            _showSnackbar(
                              err ?? 'Gagal menukar.',
                              isError: true,
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showInsufficientDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Saldo Poin Tidak Cukup',
                style: AppTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Maaf, transaksi gagal karena saldo poin Anda tidak mencukupi. Silakan kumpulkan lebih banyak poin.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Kembali ke Beranda',
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Tutup',
                variant: ButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Produk Card ───────────────────────────────────────────────────────────────

class _ProdukCard extends StatefulWidget {
  final ProdukModel produk;
  final bool isSubmitting;
  final int totalPoin;
  final Future<void> Function(int qty) onTukar;

  const _ProdukCard({
    required this.produk,
    required this.isSubmitting,
    required this.totalPoin,
    required this.onTukar,
  });

  @override
  State<_ProdukCard> createState() => _ProdukCardState();
}

class _ProdukCardState extends State<_ProdukCard> {
  int _qty = 1;

  bool get _canAfford => widget.totalPoin >= widget.produk.biayaPoin * _qty;

  // 👇 1. FUNGSI DIALOG KONFIRMASI DITAMBAHKAN DI SINI 👇
  Future<void> _konfirmasiTukar() async {
    final p = widget.produk;
    final totalHargaPoin = p.biayaPoin * _qty;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Konfirmasi',
                style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
              children: [
                const TextSpan(text: 'Anda yakin ingin melakukan penukaran pada produk '),
                TextSpan(
                  text: p.nama,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                if (_qty > 1) ...[
                  const TextSpan(text: ' sebanyak '),
                  TextSpan(
                    text: '$_qty pcs',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
                const TextSpan(text: ' seharga '),
                TextSpan(
                  // Menampilkan total poin sesuai dengan jumlah barang (qty)
                  text: '${totalHargaPoin.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')} Poin',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Batal',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Ya, Tukar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    // Jika pengguna menekan "Ya, Tukar", lanjutkan ke proses backend
    if (confirm == true) {
      widget.onTukar(_qty);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final p = widget.produk;
    final isHabis = p.isHabis;

    // ─── PERBAIKAN LOGIKA GAMBAR DI SINI ───
    final finalImageUrl = ApiClient.getImageUrl(p.fotoUrl);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: finalImageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          finalImageUrl, // 👈 Memanggil URL yang sudah dibersihkan
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.outline,
                            size: 40,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag_outlined,
                        size: 48,
                        color: AppColors.outline,
                      ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isHabis
                        ? AppColors.errorContainer
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    isHabis ? 'Stok Habis' : 'Stok: ${p.stok}',
                    style: AppTextStyles.labelSm.copyWith(
                      color: isHabis ? AppColors.errorText : AppColors.textMain,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nama,
                  style: AppTextStyles.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.deskripsi,
                  style: AppTextStyles.bodySm.copyWith(height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${p.biayaPoinFormatted} Pts',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!isHabis) ...[
                  Row(
                    children: [
                      // Qty control
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.outlineVariant.withOpacity(0.4),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _QtyBtn(
                              icon: Icons.remove,
                              onTap: _qty > 1
                                  ? () => setState(() => _qty--)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                '$_qty',
                                style: AppTextStyles.labelMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _QtyBtn(
                              icon: Icons.add,
                              onTap: _qty < p.stok
                                  ? () => setState(() => _qty++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Tukar',
                          height: 42,
                          isLoading: widget.isSubmitting,
                          // 👇 PANGGIL FUNGSI KONFIRMASI DI SINI 👇
                          onPressed: widget.isSubmitting || !_canAfford
                              ? null
                              : _konfirmasiTukar,
                        ),
                      ),
                    ],
                  ),
                  if (!_canAfford)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Poin tidak cukup untuk jumlah ini.',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.outlineVariant.withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        'Kosong',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.primary : AppColors.outline,
        ),
      ),
    );
  }
}
