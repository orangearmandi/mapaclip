import 'package:latlong2/latlong.dart';

class MapConstants {


  static const initialPosition = LatLng(4.6097100, -74.0817500);
  static const defaultZoom = 12.0;
  static const minZoom = 10.0;
  static const maxZoom = 20.0;

  static const mapboxUrlTemplate =
      'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}';
  static const userAgentPackageName = 'MAPBOX_ACCESS_TOKEN';
  static const mapboxStyleId = 'mapbox/streets-v12';
  static const mapboxAccessToken =
      "pk.eyJ1IjoiY2VzYXJvcmFuZ2UiLCJhIjoiY2x1OWFxYnluMDgwNDJxcHExbGhuc3p3NSJ9.ABA5K-LZ6VYKQ8Vrin8I8A";


}