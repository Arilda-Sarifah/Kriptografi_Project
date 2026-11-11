import 'package:flutter/material.dart';

import 'features/auth/auth_gate_screen.dart';

class EduSafeApp extends StatelessWidget {
  const EduSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF176B87);

    return MaterialApp(
      title: 'EduSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthGateScreen(),
    );
  }
}
