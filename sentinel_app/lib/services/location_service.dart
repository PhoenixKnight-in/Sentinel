import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

/// Initialises the background location service.
/// Call once at app startup (inside main() after Firebase.initializeApp).
Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    // ── Android ────────────────────────────────────────────────────
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      isForegroundMode: true,              // Required for location in BG
      autoStart: false,                    // Only start when user enables it
      notificationChannelId: 'safeher_location',
      initialNotificationTitle: 'SafeHer Active',
      initialNotificationContent: 'Your location is being monitored.',
      foregroundServiceNotificationId: 1001,
    ),
    // ── iOS ────────────────────────────────────────────────────────
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _onStart,
      onBackground: _onIosBackground,
    ),
  );
}

/// iOS background handler — must be a top-level function.
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// The service entry point — runs in a separate Isolate on Android.
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Respond to stop commands from the UI isolate
  service.on('stop').listen((_) => service.stopSelf());

  // Stream location every 30 seconds
  final locationStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,               // metres — avoid spamming
    ),
  );

  locationStream.listen((Position position) {
    // Broadcast back to UI isolate for display / SQLite queueing
    service.invoke('location_update', {
      'lat': position.latitude,
      'lng': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
    });
  });
}

/// Public helpers ──────────────────────────────────────────────────

Future<void> startLocationTracking() async {
  final hasPermission = await _ensurePermissions();
  if (!hasPermission) return;
  FlutterBackgroundService().startService();
}

Future<void> stopLocationTracking() async {
  FlutterBackgroundService().invoke('stop');
}

Stream<Map<String, dynamic>?> get locationUpdateStream =>
    FlutterBackgroundService().on('location_update');

Future<bool> _ensurePermissions() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}