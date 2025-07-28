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


  Future<void> _insertLocation(     String ciudad,
       double lat,
       double lng,
       String descripcion,
       String icon,) async {
    await SqlService.instance.insertLocation(
      ciudad: ciudad,
      lat: lat,
      lng: lng,
      descripcion: descripcion,
      icon: icon,
    );
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

  /*
  * Future<void> _loadLocations() async {
  final data = sql.getAllLocations();
  setState(() {
    locations = data;

    markers = locations.map((loc) {
      return Marker(
        width: 160,
        height: 160,
        point: LatLng(loc['latitud'], loc['longitud']),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.blue.shade900,
                title: Row(
                  children: [
                    Image.network(
                      "https://openweathermap.org/img/wn/${loc['icon']}@2x.png",
                      width: 50,
                      height: 50,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ciudad: ${loc['ciudad'] ?? 'Desconocida'}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "Descripción: ${loc['descripcion']}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "Lat: ${loc['latitud']}, Lng: ${loc['longitud']}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Image.network(
            "https://openweathermap.org/img/wn/${loc['icon']}@2x.png",
            width: 50,
            height: 50,
          ),
        ),
      );
    }).toList();
  });
}

  * */

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
                          "Ciudad: ${weather.name}",
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
                            _insertLocation(weather.name,center.latitude,center.longitude,weather.weather.first.description,weather.weather.first.icon);
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
            child: locations.isEmpty
                ? const Center(child: Text('No hay ubicaciones registradas.'))
                : ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final loc = locations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade100,
                      child:
                      Image.network(
                        "https://openweathermap.org/img/wn/${loc['icon']}@2x.png",
                        width: 50,
                        height: 50,
                      ),
                    ),
                    title: Text(
                      '${loc['descripcion']} - ${loc['ciudad']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Lat: ${loc['latitud']}, Lng: ${loc['longitud']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.gps_fixed, color: Colors.blue),
                          onPressed: () {
                            final lat = loc['latitud'] as double;
                            final lng = loc['longitud'] as double;
                            _mapController.move(LatLng(lat, lng), 15.0);
                            // Aquí puedes abrir un modal para editar la ubicación si deseas
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteLocation(loc['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )

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



