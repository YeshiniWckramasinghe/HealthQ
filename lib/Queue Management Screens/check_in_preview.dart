import 'package:flutter/material.dart';

import 'check_in_screen.dart';

void main() {
  runApp(const CheckInPreviewApp());
}

class CheckInPreviewApp extends StatelessWidget {
  const CheckInPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthQ Check In Preview',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007471),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F7F6),
      ),
      home: const CheckInScreen(),
    );
  }
}
