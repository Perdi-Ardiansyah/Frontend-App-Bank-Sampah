import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/api_client.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/status_screens.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/katalog/katalog_screen.dart';
import 'presentation/screens/admin/admin_main_screen.dart';
import 'presentation/screens/admin/laporan/admin_laporan_screen.dart';
import 'presentation/screens/admin/verifikasi/admin_verifikasi_screen.dart';
import 'presentation/screens/admin/pencairan/admin_pencairan_screen.dart';
import 'presentation/screens/admin/kategori/admin_kategori_screen.dart';
import 'presentation/screens/admin/produk/admin_produk_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ✅ Init Firebase — wajib sebelum runApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Jalankan app DULU, FCM init belakangan (non-blocking)
  runApp(
    const ProviderScope(
      child: BankSampahApp(),
    ),
  );

  // ✅ Init FCM setelah runApp — tidak memblokir tampilan
  // Dibungkus try-catch agar tidak crash jika ada masalah FCM
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('FCM init error (non-fatal): $e');
  }
}

class BankSampahApp extends StatelessWidget {
  const BankSampahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank Sampah',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/login',
      routes: {
        '/login':            (_) => const LoginScreen(),
        '/register':         (_) => const RegisterScreen(),
        '/pending':          (_) => const PendingVerificationScreen(),
        '/session-expired':  (_) => const SessionExpiredScreen(),
        '/home':             (_) => const MainScreen(),
        '/katalog':          (_) => const KatalogScreen(),
        '/admin-home':       (_) => const AdminMainScreen(),
        '/admin-laporan':    (_) => const AdminLaporanScreen(),
        '/admin-verifikasi': (_) => const AdminVerifikasiScreen(),
        '/admin-pencairan':  (_) => const AdminPencairanScreen(),
        '/admin-kategori':   (_) => const AdminKategoriScreen(),
        '/admin-produk':     (_) => const AdminProdukScreen(),
      },
    );
  }
}