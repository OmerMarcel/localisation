import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'directions_service.dart';

class VoiceGuidanceService extends ChangeNotifier {
  static final VoiceGuidanceService _instance = VoiceGuidanceService._internal();
  factory VoiceGuidanceService() => _instance;
  VoiceGuidanceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  // État de navigation
  bool _isNavigating = false;
  bool _isMuted = false;
  DirectionsResult? _activeRoute;
  int _currentStepIndex = 0;
  String _currentInstruction = '';
  double _distanceToNextStepMeters = 0.0;
  String _remainingDistance = '';
  String _remainingDuration = '';
  Position? _lastPosition;
  String? _lastSpokenPhrase;
  DateTime? _lastSpokenTime;
  DateTime? _lastPeriodicAnnouncementTime;

  StreamSubscription<Position>? _positionSubscription;

  // Getters
  bool get isNavigating => _isNavigating;
  bool get isMuted => _isMuted;
  DirectionsResult? get activeRoute => _activeRoute;
  int get currentStepIndex => _currentStepIndex;
  String get currentInstruction => _currentInstruction;
  double get distanceToNextStepMeters => _distanceToNextStepMeters;
  String get remainingDistance => _remainingDistance;
  String get remainingDuration => _remainingDuration;
  Position? get lastPosition => _lastPosition;

  /// Initialisation du moteur vocal TTS en Français
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage("fr-FR");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5); // Cadence naturelle et compréhensible
      await _tts.setVolume(1.0);

      // Gestion des plateformes iOS / Android
      await _tts.awaitSpeakCompletion(true);

      _isInitialized = true;
      debugPrint('🎙️ VoiceGuidanceService initialisé avec succès');
    } catch (e) {
      debugPrint('⚠️ Erreur initialisation TTS: $e');
    }
  }

  /// Énoncer un texte à voix haute
  Future<void> speak(String text, {bool force = false}) async {
    if (_isMuted) return;
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    // Éviter de répéter exactement la même phrase dans un intervalle de 8 secondes
    if (!force &&
        _lastSpokenPhrase == text &&
        _lastSpokenTime != null &&
        now.difference(_lastSpokenTime!).inSeconds < 8) {
      return;
    }

    try {
      _lastSpokenPhrase = text;
      _lastSpokenTime = now;
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('⚠️ Erreur speak TTS: $e');
    }
  }

  /// Activer / Couper le son de la voix
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _tts.stop();
    } else {
      speak("Guidage vocal réactivé", force: true);
    }
    notifyListeners();
  }

  /// Démarrer le guidage vocal le long de l'itinéraire
  Future<void> startNavigation(DirectionsResult route, Position initialPosition) async {
    await initialize();

    _activeRoute = route;
    _isNavigating = true;
    _currentStepIndex = 0;
    _remainingDistance = route.distance;
    _remainingDuration = route.duration;
    _lastPosition = initialPosition;
    _lastPeriodicAnnouncementTime = DateTime.now();

    if (route.steps.isNotEmpty) {
      _currentInstruction = route.steps[0].instruction;
    } else {
      _currentInstruction = 'Suivre l\'itinéraire tracé';
    }

    notifyListeners();

    // Annonce vocale initiale de démarrage
    final startMessage =
        "Itinéraire démarré. $_remainingDistance, environ $_remainingDuration. $_currentInstruction.";
    await speak(startMessage, force: true);

    // Écoute du flux GPS en continu
    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Actualisation tous les 3 mètres
      ),
    ).listen(
      _onPositionUpdate,
      onError: (err) {
        debugPrint('⚠️ Erreur GPS pendant la navigation: $err');
      },
    );
  }

  /// Arrêter la navigation vocale
  Future<void> stopNavigation() async {
    _isNavigating = false;
    _activeRoute = null;
    _currentStepIndex = 0;
    _currentInstruction = '';
    _distanceToNextStepMeters = 0.0;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _tts.stop();
    notifyListeners();
  }

  /// Traitement de chaque pas / mise à jour de position
  void _onPositionUpdate(Position position) {
    if (!_isNavigating || _activeRoute == null) return;

    _lastPosition = position;
    final steps = _activeRoute!.steps;

    if (steps.isEmpty) {
      notifyListeners();
      return;
    }

    // 1. Calculer la distance vers la destination finale
    final lastStep = steps.last;
    final distanceToDestination = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lastStep.endLocation.latitude,
      lastStep.endLocation.longitude,
    );

    // Si on est à moins de 15 mètres de l'arrivée
    if (distanceToDestination < 15) {
      speak("Vous êtes arrivé à votre destination.", force: true);
      _currentInstruction = "Vous êtes arrivé à destination";
      _remainingDistance = "0 m";
      _remainingDuration = "0 min";
      notifyListeners();
      return;
    }

    // 2. Gestion de l'étape courante
    if (_currentStepIndex < steps.length) {
      final currentStep = steps[_currentStepIndex];
      final targetLoc = currentStep.startLocation.latitude != 0
          ? currentStep.startLocation
          : currentStep.endLocation;

      final distToStep = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLoc.latitude,
        targetLoc.longitude,
      );

      _distanceToNextStepMeters = distToStep;
      _currentInstruction = currentStep.instruction;

      // Calculer la distance restante totale approximative
      _recalculateRemaining(distanceToDestination);

      // Déclencheur vocal :
      // A. Si virage dans moins de 40 mètres
      if (distToStep <= 40 && distToStep > 12) {
        speak("Dans ${distToStep.round()} mètres, ${currentStep.instruction}");
      }
      // B. Si on atteint la manœuvre (< 12 mètres)
      else if (distToStep <= 12) {
        speak(currentStep.instruction);
        // Passer à l'étape suivante
        if (_currentStepIndex < steps.length - 1) {
          _currentStepIndex++;
        }
      }
      // C. Rappel périodique de distance (toutes les 2 minutes de marche)
      else {
        final now = DateTime.now();
        if (_lastPeriodicAnnouncementTime == null ||
            now.difference(_lastPeriodicAnnouncementTime!).inMinutes >= 2) {
          _lastPeriodicAnnouncementTime = now;
          speak("Continuez tout droit. Il reste $_remainingDistance et environ $_remainingDuration.");
        }
      }
    }

    notifyListeners();
  }

  void _recalculateRemaining(double distanceMeters) {
    if (distanceMeters < 1000) {
      _remainingDistance = "${distanceMeters.round()} m";
    } else {
      _remainingDistance = "${(distanceMeters / 1000).toStringAsFixed(1)} km";
    }

    // Estimation vitesse marche : ~4.5 km/h -> ~75 mètres/minute
    final minutes = (distanceMeters / 75).ceil();
    if (minutes < 60) {
      _remainingDuration = "$minutes min";
    } else {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      _remainingDuration = "${hours}h ${remainingMins}min";
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _tts.stop();
    super.dispose();
  }
}
