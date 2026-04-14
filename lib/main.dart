import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/firebase_notification_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Init Firebase (BẮT BUỘC)
  await Firebase.initializeApp();

  // 2. Register background handler (BẮT BUỘC)
  FirebaseMessaging.onBackgroundMessage(
    FirebaseNotificationService.firebaseMessagingBackgroundHandler,
  );

  // 3. Init notification service (permission + listener)
  await FirebaseNotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Belucar Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
