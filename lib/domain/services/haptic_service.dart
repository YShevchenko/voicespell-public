import 'package:flutter/services.dart';

/// Haptic feedback service for spell casting events.
class HapticService {
  static final HapticService instance = HapticService._();
  HapticService._();

  /// Heavy impact — used when a spell is successfully cast.
  Future<void> castSuccess() async {
    await HapticFeedback.heavyImpact();
  }

  /// Light impact — used when a spell fizzles (no match or error).
  Future<void> spellFizzled() async {
    await HapticFeedback.lightImpact();
  }
}
