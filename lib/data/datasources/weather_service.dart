import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapaclip/data/models/weather_model.dart'; // Asegúrate de importar el modelo que generaste
import 'package:flutter_dotenv/flutter_dotenv.dart';
class WeatherService {
  final String apiKey = dotenv.env['SECRETCLIENTW']!;

  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';


  Future<WeatherResponse> fetchWeatherByCoords(double lat, double lon) async {

    final url = Uri.parse('$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&lang=sp');


    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      print("object$jsonData");
      return WeatherResponse.fromJson(jsonData);
    } else {
      throw Exception(
        'Error al obtener el clima por coordenadas: ${response.statusCode}',
      );
    }
  }
}
