import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapaclip/data/models/weather_model.dart'; // Asegúrate de importar el modelo que generaste

class WeatherService {
  final String apiKey =
      'ae36192518ad3b93b218a1cc6a22a5f0'; // <-- Sustituye por tu API Key real
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherResponse> fetchWeatherByCity(String cityName) async {
    final url = Uri.parse('$baseUrl?q=$cityName&appid=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return WeatherResponse.fromJson(jsonData);
    } else {
      throw Exception('Error al obtener el clima: ${response.statusCode}');
    }
  }

  Future<WeatherResponse> fetchWeatherByCoords(double lat, double lon) async {



    final url = Uri.parse('$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&lang=sp');


    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return WeatherResponse.fromJson(jsonData);
    } else {
      throw Exception(
        'Error al obtener el clima por coordenadas: ${response.statusCode}',
      );
    }
  }
}
