class WeatherResponse {
  final Coord coord;
  final List<Weather> weather;
  final String base;
  final MainData main;
  final int visibility;
  final Wind wind;
  final Clouds clouds;
  final int dt;
  final Sys sys;
  final int timezone;
  final int id;
  final String name;
  final int cod;

  WeatherResponse({
    required this.coord,
    required this.weather,
    required this.base,
    required this.main,
    required this.visibility,
    required this.wind,
    required this.clouds,
    required this.dt,
    required this.sys,
    required this.timezone,
    required this.id,
    required this.name,
    required this.cod,
  });

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    return WeatherResponse(
      coord: Coord.fromJson(json['coord']),
      weather:
          (json['weather'] as List).map((e) => Weather.fromJson(e)).toList(),
      base: json['base'],
      main: MainData.fromJson(json['main']),
      visibility: json['visibility'],
      wind: Wind.fromJson(json['wind']),
      clouds: Clouds.fromJson(json['clouds']),
      dt: json['dt'],
      sys: Sys.fromJson(json['sys']),
      timezone: json['timezone'],
      id: json['id'],
      name: json['name'],
      cod: json['cod'],
    );
  }

  Map<String, dynamic> toJson() => {
    'coord': coord.toJson(),
    'weather': weather.map((e) => e.toJson()).toList(),
    'base': base,
    'main': main.toJson(),
    'visibility': visibility,
    'wind': wind.toJson(),
    'clouds': clouds.toJson(),
    'dt': dt,
    'sys': sys.toJson(),
    'timezone': timezone,
    'id': id,
    'name': name,
    'cod': cod,
  };
}

class Coord {
  final double lon;
  final double lat;

  Coord({required this.lon, required this.lat});

  factory Coord.fromJson(Map<String, dynamic> json) =>
      Coord(lon: json['lon'].toDouble(), lat: json['lat'].toDouble());

  Map<String, dynamic> toJson() => {'lon': lon, 'lat': lat};
}

class Weather {
  final int id;
  final String main;
  final String description;
  final String icon;

  Weather({
    required this.id,
    required this.main,
    required this.description,
    required this.icon,
  });

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
    id: json['id'],
    main: json['main'],
    description: json['description'],
    icon: json['icon'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'main': main,
    'description': description,
    'icon': icon,
  };
}

class MainData {
  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int pressure;
  final int humidity;
  final int seaLevel;
  final int grndLevel;

  MainData({
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.pressure,
    required this.humidity,
    required this.seaLevel,
    required this.grndLevel,
  });

  factory MainData.fromJson(Map<String, dynamic> json) => MainData(
    temp: json['temp'].toDouble(),
    feelsLike: json['feels_like'].toDouble(),
    tempMin: json['temp_min'].toDouble(),
    tempMax: json['temp_max'].toDouble(),
    pressure: json['pressure'],
    humidity: json['humidity'],
    seaLevel: json['sea_level'],
    grndLevel: json['grnd_level'],
  );

  Map<String, dynamic> toJson() => {
    'temp': temp,
    'feels_like': feelsLike,
    'temp_min': tempMin,
    'temp_max': tempMax,
    'pressure': pressure,
    'humidity': humidity,
    'sea_level': seaLevel,
    'grnd_level': grndLevel,
  };
}

class Wind {
  final double speed;
  final int deg;
  final double gust;

  Wind({required this.speed, required this.deg, required this.gust});

  factory Wind.fromJson(Map<String, dynamic> json) => Wind(
    speed: json['speed'].toDouble(),
    deg: json['deg'],
    gust: json['gust'].toDouble(),
  );

  Map<String, dynamic> toJson() => {'speed': speed, 'deg': deg, 'gust': gust};
}

class Clouds {
  final int all;

  Clouds({required this.all});

  factory Clouds.fromJson(Map<String, dynamic> json) =>
      Clouds(all: json['all']);

  Map<String, dynamic> toJson() => {'all': all};
}

class Sys {
  final String country;
  final int sunrise;
  final int sunset;

  Sys({required this.country, required this.sunrise, required this.sunset});

  factory Sys.fromJson(Map<String, dynamic> json) => Sys(
    country: json['country'],
    sunrise: json['sunrise'],
    sunset: json['sunset'],
  );

  Map<String, dynamic> toJson() => {
    'country': country,
    'sunrise': sunrise,
    'sunset': sunset,
  };
}
