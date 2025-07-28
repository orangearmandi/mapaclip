import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:mapaclip/core/constants/map_constants.dart';
import 'package:mapaclip/core/utils/permissions.dart';
import 'package:mapaclip/data/models/weather_model.dart';
import 'package:mapaclip/data/datasources/weather_service.dart';
import 'package:mapaclip/data/datasources/sql_service_weather.dart';
import 'package:mapaclip/data/datasources/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class InteractiveMap extends StatefulWidget {
  const InteractiveMap({super.key});
  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  final SqlService sql = SqlService.instance;
  List<Map<String, dynamic>> locations = [];
  Future<void> _insertLocation(
    double temperatura,
    String ciudad,
    double lat,
    double lng,
    String descripcion,
    String icono,
  ) async {
    await SqlService.instance.insertLocation(
      temperatura: temperatura,
      ciudad: ciudad,
      lat: lat,
      lng: lng,
      descripcion: descripcion,
      fecha: DateTime.now().toIso8601String(),
      icon: icono,
    );
    _loadLocations();
  }

  void _deleteLocation(int id) {
    sql.deleteLocation(id);
    _loadLocations();
  }

  final MapController _mapController = MapController();
  LatLng? _myPosition;
  LatLng? _mapCenter;
  List<Marker> markers = [];
  Timer? _debounce;
  late Future<WeatherResponse> _weatherFuture = Future.error(
    "No se ha cargado",
  );
  DateTime _lastUpdate = DateTime.now().subtract(const Duration(seconds: 1));
  @override
  void initState() {
    super.initState();
    determinePosition();
    _loadUserLocation();
    _loadLocations();
  }

  void _loadUserLocation() async {
    try {
      final userPos = await determinePosition();
      setState(() {
        _myPosition = LatLng(userPos.latitude, userPos.longitude);
      });
      _getCurrentLocation();
    } catch (e) {
      print('⚠️ No se pudo obtener ubicación. Usando posición por defecto.');
      setState(() {
        _myPosition = MapConstants.initialPosition;
      });
      _getCurrentLocation();
    }
  }

  void _getCurrentLocation() {
    if (_myPosition == null) return;
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
                builder:
                    (context) => AlertDialog(
                      backgroundColor: Colors.blue.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      content: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 40.0,
                            ), // espacio para la X
                            child: Row(
                              children: [
                                Image.network(
                                  "https://openweathermap.org/img/wn/${weather.weather.first.icon}@2x.png",
                                  width: 50,
                                  height: 50,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Ciudad: ${weather.name}",
                                        style: _dialogStyle,
                                      ),
                                      Text(
                                        "Descripción: ${weather.weather.first.description}",
                                        style: _dialogStyle,
                                      ),
                                      Text(
                                        "Temperatura: ${(weather.main.temp - 273.15).toStringAsFixed(1)} °C",
                                        style: _dialogStyle,
                                      ),
                                      const SizedBox(height: 10),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          _insertLocation(
                                            weather.main.temp,
                                            weather.name,
                                            center.latitude,
                                            center.longitude,
                                            weather.weather.first.description,
                                            weather.weather.first.icon,
                                          );
                                          Navigator.of(
                                            context,
                                          ).pop(); // Cierra el diálogo al guardar
                                        },
                                        child: const Text(
                                          "GUARDAR",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Botón de cerrar en la esquina superior derecha
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
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

  //carga locaciones
  Future<void> _loadLocations() async {
    final data = sql.getAllLocations();
    setState(() {
      locations = data;
      markers.addAll(
        locations.map((loc) {
          final rawDatex = loc['fecha'];
          final parsedDatex = DateTime.tryParse(rawDatex ?? '');
          final fechaFormateadax =
          parsedDatex != null
              ? DateFormat(
            'dd/MM/yyyy – hh:mm a',
          ).format(parsedDatex)
              : 'Fecha no válida';
          return Marker(
            width: 160,
            height: 160,
            point: LatLng(loc['latitud'], loc['longitud']),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Colors.blue.shade900,
                        title: Row(
                          children: [
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
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
                                    "Ciudad: ${loc['ciudad']}",
                                    style: _dialogStyle,
                                  ),
                                  Text(
                                    "Descripción: ${loc['descripcion']}",
                                    style: _dialogStyle,
                                  ),
                                  Text(
                                    "Lat: ${loc['latitud']}, Lng: ${loc['longitud']}",
                                    style: _dialogStyle,
                                  ),
                                  Text(
                                    "Lat: ${loc['latitud']}, Lng: ${loc['longitud']}",
                                    style: _dialogStyle,
                                  ),
                                  Text(
                                    "Fecha: ${fechaFormateadax}",
                                    style: _dialogStyle,
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
        }),
      );
    });
  }


  //stylos repetidos
  final TextStyle _dialogStyle = const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );
  bool mostrarLista = false;
  @override
  Widget build(BuildContext context) {
    _loadLocations();
    determinePosition();

    final authService = Provider.of<AuthService>(context);
    // Mostrar pantalla de carga mientras se obtiene la ubicación
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
      backgroundColor: Colors.white, // azul pastel
      appBar: AppBar(
        backgroundColor: Colors.lightBlue.shade300, // azul pastel
        elevation: 4.0, // sombra
        title: const Text(
          'Clima',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        shadowColor: Colors.black.withOpacity(0.4), // color de la sombra
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await authService.logoutAction();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "CENTRO DE MAPA: ${_mapCenter?.latitude?.toStringAsFixed(4)}, ${_mapCenter?.longitude?.toStringAsFixed(4)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: _buildMap(MediaQuery.of(context).size),
              ),
            ),
          ),

          // Mostrar lista solo si mostrarLista es true
          if (mostrarLista)
            Expanded(
              flex: 1,
              child:
                  locations.isEmpty
                      ? const Center(
                        child: Text(
                          'No hay ubicaciones registradas.',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : ListView.builder(
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final loc = locations[index];

                          final iconUrl =
                              "https://openweathermap.org/img/wn/${loc['icon']}@2x.png";
                          final temperaturaC = ((loc['temperatura'] - 273.15)
                              .toStringAsFixed(1));

                          final rawDate = loc['fecha'];
                          final parsedDate = DateTime.tryParse(rawDate ?? '');
                          final fechaFormateada =
                              parsedDate != null
                                  ? DateFormat(
                                    'dd/MM/yyyy – hh:mm a',
                                  ).format(parsedDate)
                                  : 'Fecha no válida';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.blue,
                                child: Image.network(
                                  iconUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              title: Text(
                                '${loc['descripcion']} / ${loc['ciudad']} / $temperaturaC°C',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                '📍 ${loc['latitud']}, ${loc['longitud']}\n🕒 $fechaFormateada',
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.gps_fixed,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      final lat = loc['latitud'] as double;
                                      final lng = loc['longitud'] as double;
                                      _mapController.move(
                                        LatLng(lat, lng),
                                        15.0,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            backgroundColor: Colors.white,
            onPressed: () {
              setState(() {
                mostrarLista = !mostrarLista;
              });
            },
            label: Text(
              mostrarLista ? 'Ocultar Lista' : 'Mostrar Lista',
              style: const TextStyle(color: Colors.blue),
            ),
            icon: const Icon(Icons.list, color: Colors.blue),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            backgroundColor: Colors.white,
            onPressed: () {
              _getCurrentLocation();
              _mapController.move(_myPosition!, 15.0);
            },
            label: const Text(
              'Mi ubicación',
              style: TextStyle(color: Colors.blue),
            ),
            icon: const Icon(Icons.my_location, color: Colors.blue),
          ),
        ],
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
          initialCenter: _myPosition!,
          initialZoom: 15,
          minZoom: 10,
          maxZoom: MapConstants.maxZoom,
          onPositionChanged: (position, hasGesture) {
            final newCenter = position.center;
            if (hasGesture && newCenter != null) {
              final moved =
                  _mapCenter == null ||
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
              'id': 'mapbox/navigation-night-v1',
            },
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

}
