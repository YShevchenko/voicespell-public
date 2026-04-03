import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/database/database_helper.dart';
import '../../domain/models/spell.dart';

/// ChangeNotifier providing CRUD for spells + export/import/reset.
class SpellProvider extends ChangeNotifier {
  List<Spell> _spells = [];
  bool _isLoading = false;

  List<Spell> get spells => List.unmodifiable(_spells);
  bool get isLoading => _isLoading;

  List<Spell> get freeSpells =>
      _spells.where((s) => !s.isPremiumRequired).toList();
  List<Spell> get premiumSpells =>
      _spells.where((s) => s.isPremiumRequired).toList();
  List<Spell> get customSpells =>
      _spells.where((s) => !s.isDefault).toList();

  int get totalSpellCount => _spells.length;

  Future<void> loadSpells() async {
    _isLoading = true;
    notifyListeners();
    _spells = await DatabaseHelper.instance.getAllSpells();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleEnabled(Spell spell) async {
    await DatabaseHelper.instance
        .toggleSpellEnabled(spell.id, !spell.isEnabled);
    await loadSpells();
  }

  Future<void> updateSpellName(Spell spell, String newName) async {
    final updated = spell.copyWith(name: newName);
    await DatabaseHelper.instance.updateSpell(updated);
    await loadSpells();
  }

  Future<void> updateSpellTrigger(Spell spell, String newTrigger) async {
    final updated = spell.copyWith(triggerPhrase: newTrigger.toLowerCase().trim());
    await DatabaseHelper.instance.updateSpell(updated);
    await loadSpells();
  }

  Future<String> addCustomSpell(Spell spell) async {
    final id = await DatabaseHelper.instance.insertSpell(spell);
    await loadSpells();
    return id;
  }

  Future<void> deleteSpell(Spell spell) async {
    if (spell.isDefault) return; // Default spells cannot be deleted
    await DatabaseHelper.instance.deleteSpell(spell.id);
    await loadSpells();
  }

  Future<void> resetToStarterSpellbook() async {
    await DatabaseHelper.instance.resetToStarterSpellbook();
    await loadSpells();
  }

  /// Export all custom spells as JSON via share sheet.
  Future<void> exportCustomSpells() async {
    final customs = customSpells;
    if (customs.isEmpty) return;
    final json = jsonEncode(Spell.listToJson(customs));
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/voicespell_export.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'VoiceSpell Custom Spells',
      text: 'My VoiceSpell custom spell export',
    );
  }

  /// Import custom spells from a JSON file.
  /// Returns the number of spells imported, or -1 on error.
  Future<int> importSpells() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return 0;

      final path = result.files.first.path;
      if (path == null) return -1;

      final content = await File(path).readAsString();
      final spells = Spell.listFromJson(content);

      int count = 0;
      for (final spell in spells) {
        // Import as custom spell (overwrite is_default)
        final importedSpell = spell.copyWith(isDefault: false);
        await DatabaseHelper.instance.insertSpell(importedSpell);
        count++;
      }
      await loadSpells();
      return count;
    } catch (_) {
      return -1;
    }
  }
}
