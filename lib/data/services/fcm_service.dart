import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/network/api_client.dart'; // Sesuaikan path ini jika perlu

class FcmService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        print('🔔 FCM TOKEN: $token');
        
        // 👇 OTOMATIS KIRIM KE LARAVEL
        await _simpanTokenKeServer(token);
      }
    } catch (e) {
      print('Gagal mengambil token FCM: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Notifikasi masuk (Foreground): ${message.notification?.title}');
    });
  }

  // Fungsi internal untuk menembak API Laravel
  static Future<void> _simpanTokenKeServer(String token) async {
    try {
      await ApiClient.instance.post(
        '/user/simpan-token-fcm',
        data: {'fcm_token': token},
      );
      print('✅ Token FCM berhasil disimpan di server Laravel!');
    } catch (e) {
      // Jika error (misal karena belum login), abaikan saja
      print('⚠️ Token FCM belum dikirim: $e');
    }
  }
}