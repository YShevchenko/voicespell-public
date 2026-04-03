import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/iap_service.dart';
import 'presentation/providers/cast_provider.dart';
import 'presentation/providers/spell_provider.dart';
import 'presentation/screens/cast_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IAPService.instance),
        ChangeNotifierProvider(create: (_) => SpellProvider()),
        ChangeNotifierProvider(create: (_) => CastProvider()),
      ],
      child: const VoiceSpellApp(),
    ),
  );
}

class VoiceSpellApp extends StatelessWidget {
  const VoiceSpellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceSpell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CastScreen(),
    );
  }
}
