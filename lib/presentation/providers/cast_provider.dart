import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/spell_executor.dart';
import '../../core/services/iap_service.dart';
import '../../domain/models/spell.dart';
import '../../domain/services/haptic_service.dart';

enum CastState { idle, listening, casting, success, fizzled }

/// Provider managing the cast screen: listening state and last result.
class CastProvider extends ChangeNotifier {
  CastState _state = CastState.idle;
  String? _lastHeardPhrase;
  String? _feedbackMessage;
  Spell? _lastMatchedSpell;

  CastState get state => _state;
  String? get lastHeardPhrase => _lastHeardPhrase;
  String? get feedbackMessage => _feedbackMessage;
  Spell? get lastMatchedSpell => _lastMatchedSpell;

  bool get isListening => _state == CastState.listening;

  Future<void> toggleListening() async {
    if (_state == CastState.listening) {
      await SpeechService.instance.stopListening();
      _state = CastState.idle;
      notifyListeners();
    } else {
      _clearFeedback();
      await SpeechService.instance.startListening(
        onResult: _handleResult,
        onListeningStarted: () {
          _state = CastState.listening;
          notifyListeners();
        },
        onListeningStopped: () {
          if (_state == CastState.listening) {
            _state = CastState.idle;
            notifyListeners();
          }
        },
      );
    }
  }

  Future<void> _handleResult(String phrase) async {
    _lastHeardPhrase = phrase;
    _state = CastState.casting;
    notifyListeners();

    // Fuzzy match: check exact, then first-word match
    Spell? spell = await DatabaseHelper.instance.findByTrigger(phrase);
    spell ??= await _fuzzyMatch(phrase);

    if (spell == null) {
      _state = CastState.fizzled;
      _feedbackMessage = 'Spell not found: "$phrase"';
      await HapticService.instance.spellFizzled();
      notifyListeners();
      _scheduleClear();
      return;
    }

    // Premium gate
    if (spell.isPremiumRequired && !IAPService.instance.isPremium) {
      _state = CastState.fizzled;
      _feedbackMessage = 'Premium spell locked — upgrade to cast.';
      await HapticService.instance.spellFizzled();
      notifyListeners();
      _scheduleClear();
      return;
    }

    // Execute
    final success = await SpellExecutor.instance.execute(spell);

    if (success) {
      _lastMatchedSpell = spell;
      _state = CastState.success;
      _feedbackMessage = '${spell.name} cast!';
      await HapticService.instance.castSuccess();
    } else {
      _state = CastState.fizzled;
      _feedbackMessage = 'Spell fizzled — ${spell.name} failed.';
      await HapticService.instance.spellFizzled();
    }

    notifyListeners();
    _scheduleClear();
  }

  Future<Spell?> _fuzzyMatch(String phrase) async {
    // Try matching just the first word of the phrase
    final firstWord = phrase.split(' ').first.toLowerCase().trim();
    if (firstWord != phrase.toLowerCase().trim()) {
      return DatabaseHelper.instance.findByTrigger(firstWord);
    }
    return null;
  }

  void _scheduleClear() {
    Future.delayed(const Duration(seconds: 4), () {
      _clearFeedback();
      notifyListeners();
    });
  }

  void _clearFeedback() {
    _feedbackMessage = null;
    _lastHeardPhrase = null;
    _lastMatchedSpell = null;
    if (_state != CastState.listening) {
      _state = CastState.idle;
    }
  }
}
