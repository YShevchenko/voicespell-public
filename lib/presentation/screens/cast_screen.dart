import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cast_provider.dart';
import 'spellbook_screen.dart';
import 'settings_screen.dart';

class CastScreen extends StatefulWidget {
  const CastScreen({super.key});

  @override
  State<CastScreen> createState() => _CastScreenState();
}

class _CastScreenState extends State<CastScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onListeningStateChanged(bool isListening) {
    if (isListening) {
      _rippleController.repeat();
    } else {
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  Color _stateColor(BuildContext context, CastState state) {
    switch (state) {
      case CastState.success:
        return Colors.greenAccent;
      case CastState.fizzled:
        return Colors.redAccent;
      case CastState.listening:
      case CastState.casting:
        return Theme.of(context).colorScheme.primary;
      case CastState.idle:
        return Theme.of(context).colorScheme.primary.withValues(alpha: 0.8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CastProvider>(
      builder: (context, castProvider, _) {
        final isListening = castProvider.isListening;

        // Sync ripple animation with listening state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onListeningStateChanged(isListening);
        });

        final stateColor = _stateColor(context, castProvider.state);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'VoiceSpell',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_stories, color: Colors.white70),
                tooltip: 'Spellbook',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SpellbookScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            alignment: Alignment.center,
            children: [
              // Starfield background
              const _StarfieldBackground(),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animated cast orb
                  GestureDetector(
                    onTap: () => context.read<CastProvider>().toggleListening(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple rings (only when listening)
                        if (isListening)
                          AnimatedBuilder(
                            animation: _rippleController,
                            builder: (context, _) {
                              return _RippleRings(
                                progress: _rippleController.value,
                                color: stateColor,
                              );
                            },
                          ),

                        // Main orb
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (context, child) {
                            final scale =
                                isListening ? _pulseAnim.value : 1.0;
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  stateColor,
                                  stateColor.withValues(alpha: 0.4),
                                ],
                                stops: const [0.35, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: stateColor.withValues(alpha: 0.5),
                                  blurRadius: isListening ? 40 : 20,
                                  spreadRadius: isListening ? 10 : 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              isListening ? Icons.mic : Icons.mic_none,
                              size: 72,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Status text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusText(castProvider.state),
                      key: ValueKey(castProvider.state),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Heard phrase
                  if (castProvider.lastHeardPhrase != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '"${castProvider.lastHeardPhrase}"',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Feedback message
                  if (castProvider.feedbackMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          castProvider.feedbackMessage!,
                          key: ValueKey(castProvider.feedbackMessage),
                          style: TextStyle(
                            color: castProvider.state == CastState.success
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const Spacer(flex: 2),

                  // Spell hints
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      children: [
                        Text(
                          'Try saying:',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: const [
                            _SpellChip('Illumina'),
                            _SpellChip('Obscura'),
                            _SpellChip('Tempus'),
                            _SpellChip('Silencio'),
                            _SpellChip('Revelio'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusText(CastState state) {
    switch (state) {
      case CastState.idle:
        return 'Tap to Cast';
      case CastState.listening:
        return 'Listening...';
      case CastState.casting:
        return 'Casting...';
      case CastState.success:
        return 'Spell Cast!';
      case CastState.fizzled:
        return 'Spell Fizzled';
    }
  }
}

class _SpellChip extends StatelessWidget {
  final String label;
  const _SpellChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _RippleRings extends StatelessWidget {
  final double progress;
  final Color color;
  const _RippleRings({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(300, 300),
      painter: _RipplePainter(progress: progress, color: color),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const maxRadius = 150.0;
    const minRadius = 90.0;

    for (int i = 0; i < 3; i++) {
      final offset = i / 3.0;
      final t = ((progress + offset) % 1.0);
      final radius = minRadius + (maxRadius - minRadius) * t;
      final opacity = (1.0 - t) * 0.4;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.color != color;
}

class _StarfieldBackground extends StatelessWidget {
  const _StarfieldBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarPainter(),
      size: Size.infinite,
    );
  }
}

class _StarPainter extends CustomPainter {
  static final List<_StarData> _stars = _generateStars();

  static List<_StarData> _generateStars() {
    final rng = math.Random(42);
    return List.generate(80, (_) {
      return _StarData(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 2 + 0.5,
        opacity: rng.nextDouble() * 0.5 + 0.1,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in _stars) {
      paint.color = Colors.white.withValues(alpha: star.opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

class _StarData {
  final double x, y, size, opacity;
  const _StarData(
      {required this.x,
      required this.y,
      required this.size,
      required this.opacity});
}
