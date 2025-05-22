import 'dart:async';
import 'dart:convert';
import 'package:distincia_carros/controller/trip_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong; 
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const String MAPTILER_API_KEY = "IMdKNAWagDsTUpy68b5d"; 
const String OPENROUTESERVICE_API_KEY = "5b3ce3597851110001cf62484b05b43d095541ed9a40e378ca759ad5"; 
class MapRoutePage extends StatefulWidget {
  const MapRoutePage({super.key});

  @override
  State<MapRoutePage> createState() => _MapRoutePageState();
}
class _MapRoutePageState extends State<MapRoutePage> {
  final TripController tripController = Get.find<TripController>();
  final MapController _mapController = MapController();

  List<latlong.LatLng> _currentRoutePoints = [];
  List<Marker> _markers = [];
  latlong.LatLng _initialCenter = latlong.LatLng(1.2136, -77.2793);
  double _initialZoom = 13.0;
  bool _isSettingStartPoint = true;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
  }

  void _initializeMapRelatedData() {
    _prepareInitialMapState();
    _requestLocationPermissionAndMoveCamera();
  }

  void _prepareInitialMapState() {
    List<Marker> initialMarkers = [];
    bool shouldCenterMap = false;

    final latlong.LatLng? startP = tripController.startPoint.value;
    final latlong.LatLng? endP = tripController.endPoint.value;

    if (startP != null) {
      initialMarkers.add(
        Marker(
          width: 80.0, height: 80.0,
          point: startP,
          child: Tooltip(message: "Inicio", child: Icon(Icons.location_pin, color: Colors.green[700], size: 40)),
        ),
      );
      _isSettingStartPoint = false;
      shouldCenterMap = true;
    }
    if (endP != null) {
      initialMarkers.add(
        Marker(
          width: 80.0, height: 80.0,
          point: endP,
          child: Tooltip(message: "Fin", child: Icon(Icons.location_pin, color: Colors.red[700], size: 40)),
        ),
      );
      shouldCenterMap = true;
    }
    
    if (mounted) {
      setState(() {
        _markers = initialMarkers;
      });
    }

    if (startP != null && endP != null) {
      _drawRouteWithORS();
    } else if (shouldCenterMap && initialMarkers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isMapReady && initialMarkers.isNotEmpty && mounted) {
                _mapController.move(initialMarkers.first.point, 14.0);
            }
        });
    }
  }

  Future<void> _requestLocationPermissionAndMoveCamera() async {
    if (!_isMapReady || !mounted) return;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Ubicación Deshabilitada', 'Por favor, activa los servicios de ubicación.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Permiso Denegado', 'No se concedió el permiso de ubicación.', snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Permiso Bloqueado', 'El permiso de ubicación está bloqueado. Habilítalo desde la configuración.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userLocation = latlong.LatLng(position.latitude, position.longitude);
       if (mounted) {
        _mapController.move(userLocation, 14.0);
      }
    } catch (e) {
      print("Error obteniendo ubicación actual: $e");
      Get.snackbar('Error de Ubicación', 'No se pudo obtener tu ubicación actual.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _onMapTap(TapPosition tapPosition, latlong.LatLng latlng) {
    if (!mounted) return;
    setState(() {
      final newPointForMap = latlng;
      List<Marker> updatedMarkers = List.from(_markers);

      if (tripController.startPoint.value == null || _isSettingStartPoint) {
        tripController.startPoint.value = newPointForMap;
        updatedMarkers.removeWhere((m) => (m.child as Tooltip).message == "Inicio");
        updatedMarkers.add(
          Marker(
            width: 80.0, height: 80.0, point: newPointForMap,
            child: Tooltip(message: "Inicio", child: Icon(Icons.location_pin, color: Colors.green[700], size: 40)),
          ),
        );
        _isSettingStartPoint = false;
        _clearRouteAndDistanceUI();
        Get.snackbar("Punto de Inicio", "Marcado. Ahora selecciona el punto final.", duration: Duration(seconds: 2), snackPosition: SnackPosition.TOP);
      } else if (tripController.endPoint.value == null) {
        tripController.endPoint.value = newPointForMap;
        updatedMarkers.removeWhere((m) => (m.child as Tooltip).message == "Fin");
        updatedMarkers.add(
          Marker(
            width: 80.0, height: 80.0, point: newPointForMap,
            child: Tooltip(message: "Fin", child: Icon(Icons.location_pin, color: Colors.red[700], size: 40)),
          ),
        );
        Get.snackbar("Punto Final", "Marcado. Calculando ruta...", duration: Duration(seconds: 2), snackPosition: SnackPosition.TOP);
        _drawRouteWithORS();
      } else {
        Get.snackbar("Ruta Definida", "Ya has marcado inicio y fin. Limpia el mapa para una nueva ruta.", duration: Duration(seconds: 3), snackPosition: SnackPosition.TOP);
      }
      _markers = updatedMarkers;
    });
  }

  Future<void> _drawRouteWithORS() async {
    if (tripController.startPoint.value == null || tripController.endPoint.value == null) {
      return;
    }
    if (OPENROUTESERVICE_API_KEY == "5b3ce3597851110001cf62484b05b43d095541ed9a40e378ca759ad51") {
        Get.snackbar("API Key Faltante", "Añade tu API Key de OpenRouteService.",
        backgroundColor: Colors.red, colorText: Colors.white, duration: Duration(seconds: 5));
        _fallbackToStraightLine(); 
        return;
    }

    String startCoords = "${tripController.startPoint.value!.longitude},${tripController.startPoint.value!.latitude}";
    String endCoords = "${tripController.endPoint.value!.longitude},${tripController.endPoint.value!.latitude}";

    var url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$OPENROUTESERVICE_API_KEY&start=$startCoords&end=$endCoords&geometry_simplify=true&instructions=false');

    try {
      var response = await http.get(url, headers: {'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8'});
      _hideLoadingDialog();

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['features'] == null || (data['features'] as List).isEmpty) {
            Get.snackbar("Error de Ruta ORS", "No se encontraron rutas en la respuesta.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange);
            _fallbackToStraightLine();
            return;
        }
        List<dynamic> coordinates = data['features'][0]['geometry']['coordinates'];
        double distanceMeters = data['features'][0]['properties']['segments'][0]['distance'].toDouble();

        tripController.calculatedDistanceKm.value = distanceMeters / 1000;
        
        List<latlong.LatLng> routePointsForMap = coordinates.map((coord) {
          return latlong.LatLng(coord[1].toDouble(), coord[0].toDouble());
        }).toList();

        tripController.polylinePointsForDB.clear();
        routePointsForMap.forEach((p) => tripController.polylinePointsForDB.add({'lat': p.latitude, 'lng': p.longitude}));

        if (mounted) {
            setState(() {
            _currentRoutePoints = routePointsForMap;
            });
            _centerMapOnCurrentPoints();
        }

      } else {
        print("Error de OpenRouteService (Status ${response.statusCode}): ${response.body}");
        Get.snackbar("Error de Ruta ORS", "No se pudo obtener la ruta (${response.statusCode}). Revisa API Key/cuotas de ORS.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange);
        _fallbackToStraightLine();
      }
    } catch (e) {
      _hideLoadingDialog();
      print("Excepción al llamar a ORS: $e");
      Get.snackbar("Error de Conexión ORS", "No se pudo conectar al servicio de rutas.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
       _fallbackToStraightLine();
    }
  }

  void _fallbackToStraightLine() {
    if (tripController.startPoint.value != null && tripController.endPoint.value != null) {
      final p1 = tripController.startPoint.value!;
      final p2 = tripController.endPoint.value!;
      
      if (mounted) {
          setState(() {
            _currentRoutePoints = [p1, p2];
          });
          tripController.polylinePointsForDB.clear();
          _currentRoutePoints.forEach((p) => tripController.polylinePointsForDB.add({'lat': p.latitude, 'lng': p.longitude}));
          _calculateDistanceBetweenTwoPoints(p1, p2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted && _isMapReady) _centerMapOnCurrentPoints();
          });
      }
    }
  }

  void _calculateDistanceBetweenTwoPoints(latlong.LatLng p1, latlong.LatLng p2) {
     double distance = Geolocator.distanceBetween(
        p1.latitude, p1.longitude,
        p2.latitude, p2.longitude
     );
     tripController.calculatedDistanceKm.value = distance / 1000;
  }

  void _clearRouteAndDistanceUI() {
     if (mounted) {
        setState(() {
            _currentRoutePoints.clear();
        });
     }
     tripController.calculatedDistanceKm.value = 0.0;
     tripController.polylinePointsForDB.clear();
  }

  void _clearMapAndSelection() {
    if (mounted) {
        setState(() {
        _markers.clear();
        _currentRoutePoints.clear();
        tripController.startPoint.value = null;
        tripController.endPoint.value = null;
        tripController.waypoints.clear();
        tripController.calculatedDistanceKm.value = 0.0;
        tripController.polylinePointsForDB.clear();
        _isSettingStartPoint = true;
        });
    }
    Get.snackbar("Mapa Limpio", "Selecciona un nuevo punto de inicio.", snackPosition: SnackPosition.TOP);
  }

  void _centerMapOnCurrentPoints() {
    if (!_isMapReady || !mounted) {
        print("MapController no está listo o widget no montado (en _centerMapOnCurrentPoints).");
        return;
    }

    List<latlong.LatLng> pointsToBound = [];
    if (_markers.isNotEmpty) _markers.forEach((m) => pointsToBound.add(m.point));
    if (_currentRoutePoints.isNotEmpty) {
        pointsToBound.addAll(_currentRoutePoints);
    }
    
    if (pointsToBound.isNotEmpty) {
        var calculatedBounds = LatLngBounds.fromPoints(pointsToBound);
        bool isArea = calculatedBounds.southEast != calculatedBounds.northWest;


        if (isArea || pointsToBound.length > 1) { 
             _mapController.fitCamera(
                CameraFit.bounds(
                    bounds: calculatedBounds, 
                    padding: const EdgeInsets.all(50.0) 
                )
            );
        } else if (pointsToBound.length == 1) { 
            _mapController.move(pointsToBound.first, 15.0); 
        } else {
            print("Bounds no válidos o insuficientes para centrar el mapa. Centrando en _initialCenter.");
            _mapController.move(_initialCenter, _initialZoom);
        }
    } else {
        print("No hay puntos para crear bounds para fitCamera. Centrando en _initialCenter.");
        _mapController.move(_initialCenter, _initialZoom);
    }
  }

  void _showLoadingDialog(String message) {
    if (!(Get.isDialogOpen ?? false)) {
      Get.dialog(
        AlertDialog(
          content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 15), Text(message)]),
        ),
        barrierDismissible: false,
      );
    }
  }

  void _hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Definir Ruta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: "Limpiar Mapa",
            onPressed: _clearMapAndSelection,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              onTap: _onMapTap,
              onMapReady: () {
                if (mounted) {
                    setState(() {
                    _isMapReady = true;
                    });
                    print("flutter_map está listo!");
                    _initializeMapRelatedData();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$MAPTILER_API_KEY",
                userAgentPackageName: 'com.tuempresa.distincia_carros', // Reemplaza
              ),
              // Condicionar la PolylineLayer
              if (_currentRoutePoints.isNotEmpty && _currentRoutePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _currentRoutePoints,
                      strokeWidth: 5.0,
                      color: Colors.deepPurpleAccent,
                    ),
                  ],
                ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: 10, left: 10, right: 10,
            child: Card( 
                 elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distancia:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                    ),
                     Text(
                      '${tripController.calculatedDistanceKm.value.toStringAsFixed(2)} km',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ],
                )),
              ),
            ),
          ),
          Positioned(
            bottom: 100, left: 16, right: 16,
            child: TextButton.icon( 
                style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.95), foregroundColor: Colors.blueGrey[800],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey[350]!))),
                icon: Icon(_isSettingStartPoint && tripController.startPoint.value == null ? Icons.touch_app_outlined : (_isSettingStartPoint ? Icons.gps_fixed : Icons.gps_not_fixed_outlined), size: 20),
                label: Text(
                _isSettingStartPoint
                    ? (tripController.startPoint.value == null ? "Toca el mapa para marcar INICIO" : "Toca el mapa para marcar FIN")
                    : (tripController.endPoint.value == null ? "Toca el mapa para marcar FIN" : "Ruta definida. Puedes guardar."),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              onPressed: () {
                if(tripController.startPoint.value == null) {
                    if (_isMapReady) _requestLocationPermissionAndMoveCamera();
                } else if (_markers.isNotEmpty && _isMapReady) {
                     _centerMapOnCurrentPoints();
                }
              },
            ),
          ),
          Positioned(
            bottom: 20, left: 16, right: 16,
            child: ElevatedButton.icon( 
                icon: const Icon(Icons.save_alt_outlined),
              label: const Text('Confirmar Ruta y Guardar'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                if (tripController.startPoint.value != null &&
                    tripController.endPoint.value != null &&
                    tripController.calculatedDistanceKm.value > 0) {
                  tripController.saveNewTrip();
                } else {
                  Get.snackbar('Ruta Incompleta', 'Define inicio, fin y asegúrate de que la distancia sea calculada.', snackPosition: SnackPosition.BOTTOM);
                }
              },
            ),
          )
        ],
      ),
    );
  }
}