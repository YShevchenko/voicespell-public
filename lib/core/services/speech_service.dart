import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// On-device speech-to-text service (offline capable via device STT engine).
class SpeechService {
  static final SpeechService instance = SpeechService._();
  SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    _isInitialized = await _speech.initialize(
      onError: (error) {
        // ignore diagnostic noise
      },
      onStatus: (status) {
        // ignore diagnostic noise
      },
    );

    return _isInitialized;
  }

  Future<void> startListening({
    required void Function(String) onResult,
    required void Function() onListeningStarted,
    required void Function() onListeningStopped,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        onListeningStopped();
        return;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    _isListening = true;
    onListeningStarted();

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          final words = result.recognizedWords.trim();
          onResult(words);
          _isListening = false;
          onListeningStopped();
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: false,
        cancelOnError: true,
        // SpeechListenMode.dictation uses on-device model — offline capable.
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  void dispose() {
    _speech.stop();
    _speech.cancel();
    _isListening = false;
  }
}
