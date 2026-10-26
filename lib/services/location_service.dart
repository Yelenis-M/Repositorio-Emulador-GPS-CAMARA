import 'package:geolocator/geolocator.dart';
class LocationService {
  // Obtiene las coordenadas actuales del dispositivo
  Future<Position> getCurrentLocation() async {
    // 1. ¿El GPS está encendido en el teléfono?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El GPS está desactivado en el dispositivo.');
    }
    // 2. ¿Qué estado tiene el permiso de ubicación?
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Solicitamos el permiso en tiempo de ejecución
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado por el usuario.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permiso denegado permanentemente. '
        'Habilítalo en los ajustes del sistema.',
      );
    }
    // 3. Obtenemos la posición con alta precisión
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15), // Evita esperar indefinidamente
      ),
    );
  }
  // RETO 5: Stream para seguir la ubicación en vivo al caminar
  Future<Stream<Position>> getPositionStream() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El GPS está desactivado en el dispositivo.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado por el usuario.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permiso denegado permanentemente. Habilítalo en los ajustes del sistema.',
      );
    }

    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Se actualiza cada vez que el usuario se mueva 5 metros
      ),
    );
  }
}