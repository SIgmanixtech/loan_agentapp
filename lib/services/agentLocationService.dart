import 'package:geolocator/geolocator.dart';

import 'apiClient.dart';

class AgentLocationService {
  static Future<void> updateCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are turned off. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please enable it from app settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final response = await ApiClient.put(
      '/api/agent/location',
      authenticated: true,
      body: {'latitude': position.latitude, 'longitude': position.longitude},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to update agent location.');
    }
  }
}
