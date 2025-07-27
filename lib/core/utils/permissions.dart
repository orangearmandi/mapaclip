import 'package:geolocator/geolocator.dart';


Future<Position> determinePosition() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();


    if (permission == LocationPermission.denied) {
      throw Exception('Permiso de ubicación denegado');
    }
  }

  return await Geolocator.getCurrentPosition();
}
