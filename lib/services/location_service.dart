import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
}

class LocationService {
  Future<LatLng> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException('Konum servisi kapalı. Lütfen açın.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationException('Konum izni verilmedi.');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LatLng(pos.latitude, pos.longitude);
  }
}
