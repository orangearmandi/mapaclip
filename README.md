# 🌦️ mapaclip

**Climap** es una app móvil construida con Flutter que muestra información climática en un mapa interactivo. Los usuarios pueden consultar el clima actual en su ubicación y guardar datos meteorológicos en una base de datos local.

## 🚀 Características

- Mapa interactivo con marcadores del clima.
- Consulta del clima actual usando OpenWeatherMap.
- Almacenamiento de datos local con SQLite.
- Autenticación con Auth0.
- Diseño responsive y amigable.

## 🛠️ Tecnologías

- Flutter + Riverpod + Provider
- `flutter_map` + `latlong2`
- SQLite3 con `sqlite3_flutter_libs`
- Auth0 (`auth0_flutter`)
- `flutter_dotenv` para manejo de variables de entorno

## ✅ Requisitos

- Flutter 3.7.2 o superior
- Clave API de [OpenWeatherMap](https://openweathermap.org/api)
- Archivo `.env` con tu configuración (clientId, domain, apiKey, etc)

## 📦 Instalación

1. Clona el repositorio:
   ```bash
   git clone https://github.com/orangearmandi/mapaclip.git
   cd mapaclip
