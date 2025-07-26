import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapaclip/core/constants/map_constants.dart';

class InteractiveMap extends StatefulWidget {
  const InteractiveMap({super.key});

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  final MapController _mapController = MapController();
  LatLng? _myPosition;
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<Position> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _determinePosition();
      setState(() {
        _myPosition = LatLng(position.latitude, position.longitude);
        markers = [
          Marker(
            point: _myPosition!,
            width: 40,
            height: 40,
            child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
          ),
        ];
      });

      _mapController.move(_myPosition!, MapConstants.defaultZoom);
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(body: _buildMap(size));
  }

  Widget _buildMap(Size size) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _myPosition ?? MapConstants.initialPosition,
          initialZoom: MapConstants.defaultZoom,
          minZoom: MapConstants.minZoom,
          maxZoom: MapConstants.maxZoom,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
            additionalOptions: {
              'accessToken': MapConstants.mapboxAccessToken,
              'id': 'mapbox/streets-v12',
            },
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
