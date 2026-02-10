import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Supported languages for voice input
enum VoiceLanguage {
  english('en_US', 'English'),
  german('de_DE', 'German'),
  polish('pl_PL', 'Polish'),
  romanian('ro_RO', 'Romanian'),
  spanish('es_ES', 'Spanish'),
  french('fr_FR', 'French'),
  italian('it_IT', 'Italian'),
  dutch('nl_NL', 'Dutch'),
  portuguese('pt_PT', 'Portuguese'),
  czech('cs_CZ', 'Czech'),
  hungarian('hu_HU', 'Hungarian'),
  bulgarian('bg_BG', 'Bulgarian'),
  turkish('tr_TR', 'Turkish'),
  lithuanian('lt_LT', 'Lithuanian');

  final String localeId;
  final String displayName;
  const VoiceLanguage(this.localeId, this.displayName);
}

/// Voice input service for hands-free hazard reporting
class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentText = '';
  VoiceLanguage _currentLanguage = VoiceLanguage.english;
  List<LocaleName> _availableLocales = [];

  // Callbacks
  void Function(String text, bool isFinal)? onTextReceived;
  void Function(SpeechRecognitionError error)? onError;
  void Function(String status)? onStatusChanged;

  /// Check if voice input is available
  bool get isAvailable => _isInitialized;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get current transcribed text
  String get currentText => _currentText;

  /// Get current language
  VoiceLanguage get currentLanguage => _currentLanguage;

  /// Get available locales on this device
  List<LocaleName> get availableLocales => _availableLocales;

  /// Initialize the speech recognition engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: kDebugMode,
      );

      if (_isInitialized) {
        _availableLocales = await _speech.locales();
        debugPrint('Voice input initialized with ${_availableLocales.length} locales');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize voice input: $e');
      return false;
    }
  }

  /// Set the language for voice recognition
  void setLanguage(VoiceLanguage language) {
    _currentLanguage = language;
  }

  /// Start listening for voice input
  Future<void> startListening({
    VoiceLanguage? language,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        onError?.call(SpeechRecognitionError('Speech recognition not available', false));
        return;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    _currentText = '';
    _isListening = true;

    final targetLanguage = language ?? _currentLanguage;

    await _speech.listen(
      onResult: _handleResult,
      localeId: targetLanguage.localeId,
      listenFor: listenFor ?? const Duration(seconds: 30),
      pauseFor: pauseFor ?? const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.confirmation,
    );
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
  }

  /// Cancel listening without processing
  Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
    _currentText = '';
  }

  /// Handle speech recognition results
  void _handleResult(SpeechRecognitionResult result) {
    _currentText = result.recognizedWords;
    onTextReceived?.call(_currentText, result.finalResult);

    if (result.finalResult) {
      _isListening = false;
    }
  }

  /// Handle status changes
  void _handleStatus(String status) {
    debugPrint('Speech status: $status');
    onStatusChanged?.call(status);

    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  /// Handle errors
  void _handleError(SpeechRecognitionError error) {
    debugPrint('Speech error: ${error.errorMsg}');
    _isListening = false;
    onError?.call(error);
  }

  /// Parse hazard type from voice input
  String? parseHazardType(String text) {
    final lowerText = text.toLowerCase();

    // Police detection
    if (lowerText.contains('police') ||
        lowerText.contains('cop') ||
        lowerText.contains('polizei') ||
        lowerText.contains('policja')) {
      return 'police';
    }

    // Camera/speed camera
    if (lowerText.contains('camera') ||
        lowerText.contains('speed camera') ||
        lowerText.contains('blitzer') ||
        lowerText.contains('radar')) {
      return 'camera';
    }

    // Accident
    if (lowerText.contains('accident') ||
        lowerText.contains('crash') ||
        lowerText.contains('collision') ||
        lowerText.contains('unfall')) {
      return 'accident';
    }

    // Road works
    if (lowerText.contains('road work') ||
        lowerText.contains('construction') ||
        lowerText.contains('baustelle') ||
        lowerText.contains('roadwork')) {
      return 'road_works';
    }

    // Road closure
    if (lowerText.contains('closed') ||
        lowerText.contains('closure') ||
        lowerText.contains('blocked') ||
        lowerText.contains('gesperrt')) {
      return 'road_closure';
    }

    // Weather
    if (lowerText.contains('weather') ||
        lowerText.contains('rain') ||
        lowerText.contains('snow') ||
        lowerText.contains('ice') ||
        lowerText.contains('fog')) {
      return 'weather';
    }

    // Border delay
    if (lowerText.contains('border') ||
        lowerText.contains('customs') ||
        lowerText.contains('grenze') ||
        lowerText.contains('queue')) {
      return 'border_delay';
    }

    // General hazard
    if (lowerText.contains('hazard') ||
        lowerText.contains('danger') ||
        lowerText.contains('warning') ||
        lowerText.contains('object')) {
      return 'road_hazard';
    }

    return null;
  }

  /// Parse severity from voice input
  String parseSeverity(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('critical') ||
        lowerText.contains('emergency') ||
        lowerText.contains('serious') ||
        lowerText.contains('major')) {
      return 'critical';
    }

    if (lowerText.contains('high') ||
        lowerText.contains('dangerous') ||
        lowerText.contains('severe')) {
      return 'high';
    }

    if (lowerText.contains('low') ||
        lowerText.contains('minor') ||
        lowerText.contains('small')) {
      return 'low';
    }

    return 'medium';
  }

  /// Dispose resources
  void dispose() {
    _speech.stop();
    _speech.cancel();
  }
}
