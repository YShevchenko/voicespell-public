import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/casting/presentation/screens/cast_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: VoiceSpellApp(),
    ),
  );
}

class VoiceSpellApp extends StatelessWidget {
  const VoiceSpellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Spell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CastScreen(),
    );
  }
}
