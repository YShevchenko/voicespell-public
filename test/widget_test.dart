import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_spell/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const VoiceSpellApp());
    expect(find.text('Voice Spell'), findsOneWidget);
  });
}
