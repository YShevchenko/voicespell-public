import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/spell_executor.dart';
import '../../../../core/services/iap_service.dart';
import '../../../../core/database/database_helper.dart';
import '../../../spellbook/presentation/screens/spellbook_screen.dart';

/// Main casting screen with speech recognition
class CastScreen extends ConsumerStatefulWidget {
  const CastScreen({super.key});

  @override
  ConsumerState<CastScreen> createState() => _CastScreenState();
}

class _CastScreenState extends ConsumerState<CastScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isListening = false;
  String? _lastRecognizedText;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await IAPService.instance.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    SpeechService.instance.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await SpeechService.instance.stopListening();
      setState(() {
        _isListening = false;
        _controller.stop();
        _controller.reset();
      });
    } else {
      await SpeechService.instance.startListening(
        onResult: _handleSpeechResult,
        onListeningStarted: () {
          setState(() {
            _isListening = true;
            _lastRecognizedText = null;
            _feedbackMessage = null;
            _controller.repeat();
          });
        },
        onListeningStopped: () {
          setState(() {
            _isListening = false;
            _controller.stop();
            _controller.reset();
          });
        },
      );
    }
  }

  Future<void> _handleSpeechResult(String recognizedText) async {
    setState(() {
      _lastRecognizedText = recognizedText;
    });

    // Find matching spell
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'spells',
      where: 'LOWER(incantation) = ? AND is_active = 1',
      whereArgs: [recognizedText.toLowerCase()],
    );

    if (results.isEmpty) {
      setState(() {
        _feedbackMessage = 'Spell not found: "$recognizedText"';
      });
      Vibration.vibrate(duration: 200);
      return;
    }

    final spell = results.first;
    final isPremium = spell['is_premium'] == 1;

    // Check premium access
    if (isPremium && !IAPService.instance.isPremium) {
      setState(() {
        _feedbackMessage = 'Premium spell locked! Upgrade to cast.';
      });
      Vibration.vibrate(duration: 200);
      _showPremiumDialog();
      return;
    }

    // Execute spell
    final success = await SpellExecutor.instance.executeSpell(
      spell['action_type'] as String,
      spell['action_params'] as String?,
    );

    if (success) {
      setState(() {
        _feedbackMessage = 'Cast: ${spell['name']}';
      });
      Vibration.vibrate(duration: 100);

      // Log successful cast
      await db.insert('cast_history', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'spell_id': spell['id'],
        'success': 1,
      });
    } else {
      setState(() {
        _feedbackMessage = 'Failed to cast: ${spell['name']}';
      });
      Vibration.vibrate(duration: 200);
    }

    // Clear feedback after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _feedbackMessage = null;
          _lastRecognizedText = null;
        });
      }
    });
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Required'),
        content: const Text(
          'Upgrade to Premium for \$3.99 to unlock all 20+ spells and create custom spells!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await IAPService.instance.purchase();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium unlocked!')),
                );
              }
            },
            child: const Text('UPGRADE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Spell'),
        actions: [
          IconButton(
            icon: const Icon(Icons.book),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SpellbookScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Cast button
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        ],
                        stops: [0.3 + (_controller.value * 0.3), 1.0],
                      ),
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5 * (1 - _controller.value)),
                                blurRadius: 30 * (1 + _controller.value),
                                spreadRadius: 10 * _controller.value,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 80,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _isListening ? 'Listening...' : 'Tap to Cast',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (_lastRecognizedText != null)
              Text(
                'Heard: "$_lastRecognizedText"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            if (_feedbackMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _feedbackMessage!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            const Spacer(),
            // Quick spell examples
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Try saying:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: const [
                      Chip(label: Text('"Illumina"')),
                      Chip(label: Text('"Obscura"')),
                      Chip(label: Text('"Tempus"')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
