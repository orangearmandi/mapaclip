import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapaclip/core/constants/map_constants.dart';
import 'package:mapaclip/core/utils/permissions.dart';
import 'package:mapaclip/data/models/weather_model.dart';
import 'package:mapaclip/data/datasources/weather_service.dart';
import 'package:mapaclip/data/datasources/sql_service_weather.dart';
import 'package:mapaclip/data/datasources/auth_service.dart';
import 'package:provider/provider.dart';

class InteractiveMap extends StatefulWidget {
  const InteractiveMap({super.key});

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {

  /////State

  final SqlService sql = SqlService.instance;
  List<Map<String, dynamic>> locations = [];


  void _insertSampleLocation() {
    sql.insertLocation(4.6097, -74.0817, 'Bogotá centro', '🏙️');
    _loadLocations();
  }

  void _updateLocation(int id) {
    sql.updateLocation(id, 4.6, -74.08, 'Actualizado', '🗺️');
    _loadLocations();
  }

  void _deleteLocation(int id) {
    sql.deleteLocation(id);
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final data = sql.getAllLocations();
    setState(() {
      locations = data;
    });
  }

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
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) =>AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                 backgroundColor:   Colors.blue.shade900,

                    title: Row(

                  children: [
                    Image.network(
                      "https://openweathermap.org/img/wn/${weather.weather.first.icon}@2x.png",
                      width: 50,
                      height: 50,
                    ),
                     SizedBox(width: 10),
                     Expanded(
                      child: Column(children: [
                        Text(
                          "Clima: ${weather.name}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Descripcion: ${weather.weather.first.description}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Temperatura: ${(weather.main.temp - 273.15).toStringAsFixed(1)} °C",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 10,height: 10,),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue, // Color de fondo
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {




                            _insertSampleLocation();



                          },
                          child: const Text(
                            "GUARDAR",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],)
                    ),
                  ],
                ))
              );
            },
            child: Image.network(
              "https://openweathermap.org/img/wn/${weather.weather.first.icon}@2x.png",
              width: 50,
              height: 50,
            ),
          ),
        ),
      ];


      _weatherFuture = Future.value(weather);
    });
  }


  @override
  Widget build(BuildContext context) {
    _loadLocations();
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
    } final  authService = Provider.of<AuthService>(context);

    return Scaffold(


      appBar: AppBar(
        title: const Text('Clima'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await authService.logoutAction();
              // Opcional: Puedes mostrar un mensaje
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sesión cerrada')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Text(
            "Centro del mapa: ${_mapCenter?.latitude?.toStringAsFixed(4)}, ${_mapCenter?.longitude?.toStringAsFixed(4)}",
          ),
          Expanded( child: _buildMap(MediaQuery.of(context).size),),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final loc = locations[index];
                return Card(
                  child: ListTile(
                    leading: Text(loc['icon'] ?? '📍', style: const TextStyle(fontSize: 24)),
                    title: Text('${loc['descripcion']}'),
                    subtitle: Text('Lat: ${loc['latitud']}, Lng: ${loc['longitud']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _updateLocation(loc['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteLocation(loc['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
              'accessToken': MapConstants.mapboxAccessToken!,
              'id': 'mapbox/dark-v9',
            },
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }



}



