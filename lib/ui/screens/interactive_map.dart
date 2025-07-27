import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapaclip/core/constants/map_constants.dart';
import 'package:mapaclip/core/utils/permissions.dart';
import 'package:mapaclip/data/models/weather_model.dart';
import 'package:mapaclip/data/datasources/weather_service.dart';

class InteractiveMap extends StatefulWidget {
  const InteractiveMap({super.key});

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  final MapController _mapController = MapController();
  LatLng? _myPosition;
  LatLng? _mapCenter;
  List<Marker> markers = [];
  Timer? _debounce; // 👈 para detectar "cuando se deja de mover"
  late Future<WeatherResponse> _weatherFuture = Future.error("no se ha cargado");
  DateTime _lastUpdate = DateTime.now().subtract(const Duration  (seconds: 1));
  @override
  void initState() {
    super.initState();
    determinePosition();
    _getCurrentLocation();
    _loadUserLocation();
  }

  void _loadUserLocation() async {
    try {
      final userPos = await determinePosition();
      setState(() {
        _myPosition = LatLng(userPos.latitude, userPos.longitude);
      });
    } catch (e) {
      print('⚠️ No se pudo obtener ubicación. Usando posición por defecto.');
      setState(() {
        _myPosition = MapConstants.initialPosition;
      });
    }
  }


  void _getCurrentLocation() async {
    setState(() {

      markers.add(
        Marker(
          child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
          point: _myPosition!,
        ),
      );
      _mapCenter = _myPosition; // Opcional: lo usas como centro del mapa

      // Solo cuando tengas la posición, llama a la API del clima
      _weatherFuture = WeatherService().fetchWeatherByCoords(
        _myPosition!.latitude,
        _myPosition!.longitude,
      );
    });

    final latLng = LatLng(_myPosition!.latitude, _myPosition!.longitude);

    _updateCenterAndWeather(latLng);

  }




  void _updateCenterAndWeather(LatLng center) async {
    setState(() {
      _mapCenter = center;
      _myPosition = center;
    });

    final weather = await WeatherService().fetchWeatherByCoords(
      center.latitude,
      center.longitude,
    );

    setState(() {
      markers = [
        Marker(
          width: 160,
          height: 160,
          point: center,
          child: Image.network(
            "https://openweathermap.org/img/wn/${weather.weather.first.icon}@2x.png",
            width: 50,
            height: 50,
          ),
        ),
      ];

      _weatherFuture = Future.value(weather);
    });
  }

  @override
  Widget build(BuildContext context) {

    // ✅ Mostrar pantalla de carga si no se ha obtenido la ubicación
    if (_myPosition == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Cargando...")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Buscando ubicación actual...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Clima')),
      body: Column(
        children: [
          Text(
            "Centro del mapa: ${_mapCenter?.latitude?.toStringAsFixed(4)}, ${_mapCenter?.longitude?.toStringAsFixed(4)}",
          ),
          _buildMap(MediaQuery.of(context).size),
          Expanded(child: _buildWeatherInfo()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _getCurrentLocation();
          _mapController.move(_myPosition!, 15.0);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildMap(Size size) {
    return SizedBox(
      width: size.width - 10,
      height: size.height / 2,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _myPosition! ,
          initialZoom: 15,
          minZoom: 10,
          maxZoom: MapConstants.maxZoom,
            onPositionChanged: (position, hasGesture) {
              final newCenter = position.center;
              if (hasGesture && newCenter != null) {
                final moved = _mapCenter == null ||
                    _mapCenter!.latitude != newCenter.latitude ||
                    _mapCenter!.longitude != newCenter.longitude;
                if (moved) {
                  _mapCenter = newCenter;
                  // 👇 Cancela el intento anterior
                  _debounce?.cancel();
                  // 👇 Reprograma para 500ms después de terminar el gesto
                  _debounce = Timer(const Duration(milliseconds: 600), () {
                    _updateCenterAndWeather(newCenter);
                  });
                }
              }
            },

        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
            additionalOptions: {
              'accessToken': MapConstants.mapboxAccessToken,
              'id': 'mapbox/dark-v11',
            },
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    return FutureBuilder<WeatherResponse>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final weather = snapshot.data!;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weather.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(weather.main.temp - 273.15).toStringAsFixed(1)} °C',
                style: const TextStyle(fontSize: 20),
              ),
              Text(weather.weather.first.description),
              Image.network(
                "https://openweathermap.org/img/wn/${weather.weather.first.icon}@2x.png",
                width: 130,
                height: 130,
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}
