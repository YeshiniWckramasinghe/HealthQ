import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'common Screens/onboarding_screen.dart';
import 'theme/app_colors.dart';
import 'services/booking_service.dart';

// Global future so screens requiring Firebase can ensure it is ready
Future<FirebaseApp>? _firebaseInitFuture;

Future<FirebaseApp> ensureFirebaseInitialized() {
  _firebaseInitFuture ??= Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  return _firebaseInitFuture!;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Start Firebase in background without blocking the first frame,
  // then seed booking data once Firebase is ready
  ensureFirebaseInitialized().then((app) async {
    debugPrint('Firebase connected: ${app.name}');
    await BookingService().seedIfEmpty();
  }).catchError((e) {
    debugPrint('Firebase init error: $e');
  });

  // Launch UI immediately on frame 1
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary300),
        scaffoldBackgroundColor: AppColors.white,
        useMaterial3: true,
        // Snappy, smooth 60fps page transitions without lag
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}