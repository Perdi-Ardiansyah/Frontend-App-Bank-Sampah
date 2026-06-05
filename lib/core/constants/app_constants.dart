class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String pendingVerification = '/pending-verification';
  static const String sessionExpired = '/session-expired';
  static const String home = '/home';
  static const String riwayat = '/riwayat';
  static const String tukar = '/tukar';
  static const String akun = '/akun';
  static const String katalog = '/katalog';
}

class AppStrings {
  AppStrings._();

  static const String appName = 'Bank Sampah';
  static const String tagline = 'Masuk ke akun Anda untuk mulai mengelola\ntabungan sampah hari ini.';

  // Auth
  static const String login = 'Masuk';
  static const String register = 'Daftar';
  static const String username = 'Nama Pengguna atau Email';
  static const String password = 'Kata Sandi';
  static const String rememberMe = 'Ingat saya';
  static const String forgotPassword = 'Lupa sandi?';
  static const String noAccount = 'Belum punya akun?';
  static const String registerNow = 'Daftar Sekarang';
  static const String hasAccount = 'Sudah memiliki akun?';
  static const String loginHere = 'Masuk di sini';

  // Nav
  static const String beranda = 'Beranda';
  static const String riwayat = 'Riwayat';
  static const String tukar = 'Tukar';
  static const String setor = 'Setor';
  static const String akun = 'Akun';

  // Home
  static const String totalPoin = 'TOTAL POIN';
  static const String setaraRp = 'Setara dengan Rp';
  static const String katalogHarga = 'Katalog Harga';
  static const String lihatDaftarHarga = 'Lihat daftar harga sampah';
  static const String tukarPoin = 'Tukar Poin';
  static const String klaimHadiahmu = 'Klaim hadiahmu';
  static const String transaksiTerakhir = 'Transaksi Terakhir';
  static const String lihatSemua = 'Lihat Semua';
}