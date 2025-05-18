// lib/data/models/trip_model.dart
import 'dart:convert';
// Quita la importación de flutter_map si no la usas directamente aquí.
// import 'package:flutter_map/flutter_map.dart'; // Si almacenas LatLng directamente

class Trip {
  final String id;
  final String userId;
  String vehicleBrand;
  String vehicleModel;
  int vehicleYear;
  String tripDescription;
  String tripTitle;

  // Campos para la imagen del vehículo
  String? vehicleImageUrl;
  String? vehicleImageFileId;

  String? mapThumbnailUrl; // Para miniatura del mapa (opcional)
  String? mapImageFileId;  // Para imagen estática del mapa (opcional)

  double startLatitude;
  double startLongitude;
  double endLatitude;
  double endLongitude;
  List<Map<String, double>> waypoints;
  List<Map<String, double>>? polylinePointsForDB;
  double distanceKm;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.userId,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.tripDescription,
    required this.tripTitle,
    this.vehicleImageUrl,     // Añadir al constructor
    this.vehicleImageFileId,  // Añadir al constructor
    this.mapThumbnailUrl,
    this.mapImageFileId,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    this.waypoints = const [],
    this.polylinePointsForDB,
    required this.distanceKm,
    required this.createdAt,
  });

  factory Trip.fromMap(Map<String, dynamic> map) {
    // ... (lógica existente de parsedWaypoints y parsedPolylinePoints)
    List<Map<String, double>> parsedWaypoints = [];
    if (map['waypoints'] != null) {
        if (map['waypoints'] is String && (map['waypoints'] as String).isNotEmpty) {
            try {
            List<dynamic> decodedJson = jsonDecode(map['waypoints']);
            parsedWaypoints = decodedJson
                .map((wp) => Map<String, double>.from(wp as Map))
                .toList();
            } catch (e) {
            print('Error decodificando waypoints (String JSON): $e');
            }
        } else if (map['waypoints'] is List) {
            try {
                parsedWaypoints = (map['waypoints'] as List)
                .map((wp) => Map<String, double>.from(wp as Map))
                .toList();
            } catch (e) {
                print('Error decodificando waypoints (List<dynamic>): $e');
            }
        }
    }

    List<Map<String, double>>? parsedPolylinePoints;
    if (map['polylinePointsForDB'] != null) {
      if (map['polylinePointsForDB'] is String && (map['polylinePointsForDB'] as String).isNotEmpty) {
        try {
          List<dynamic> decodedJson = jsonDecode(map['polylinePointsForDB']);
          parsedPolylinePoints = decodedJson
              .map((p) => Map<String, double>.from(p as Map))
              .toList();
        } catch (e) {
          print('Error decodificando polylinePointsForDB (String JSON): $e');
        }
      } else if (map['polylinePointsForDB'] is List) {
         try {
            parsedPolylinePoints = (map['polylinePointsForDB'] as List)
              .map((p) => Map<String, double>.from(p as Map))
              .toList();
        } catch (e) {
            print('Error decodificando polylinePointsForDB (List<dynamic>): $e');
        }
      }
    }

    return Trip(
      id: map['\$id'] ?? '',
      userId: map['userId'] ?? '',
      vehicleBrand: map['vehicleBrand'] ?? 'N/A',
      vehicleModel: map['vehicleModel'] ?? 'N/A',
      vehicleYear: map['vehicleYear'] is String
          ? (int.tryParse(map['vehicleYear']) ?? DateTime.now().year)
          : (map['vehicleYear'] ?? DateTime.now().year),
      tripDescription: map['tripDescription'] ?? '',
      tripTitle: map['tripTitle'] ?? 'Recorrido sin título',
      vehicleImageUrl: map['vehicleImageUrl'],         // Cargar
      vehicleImageFileId: map['vehicleImageFileId'],   // Cargar
      mapThumbnailUrl: map['mapThumbnailUrl'],
      mapImageFileId: map['mapImageFileId'],
      startLatitude: (map['startLatitude'] as num? ?? 0.0).toDouble(),
      startLongitude: (map['startLongitude'] as num? ?? 0.0).toDouble(),
      endLatitude: (map['endLatitude'] as num? ?? 0.0).toDouble(),
      endLongitude: (map['endLongitude'] as num? ?? 0.0).toDouble(),
      waypoints: parsedWaypoints,
      polylinePointsForDB: parsedPolylinePoints,
      distanceKm: (map['distanceKm'] as num? ?? 0.0).toDouble(),
      createdAt: map['\$createdAt'] != null
          ? DateTime.parse(map['\$createdAt'])
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'tripDescription': tripDescription,
      'tripTitle': tripTitle,
      if (vehicleImageUrl != null) 'vehicleImageUrl': vehicleImageUrl,         // Guardar
      if (vehicleImageFileId != null) 'vehicleImageFileId': vehicleImageFileId, // Guardar
      if (mapThumbnailUrl != null) 'mapThumbnailUrl': mapThumbnailUrl,
      if (mapImageFileId != null) 'mapImageFileId': mapImageFileId,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'waypoints': jsonEncode(waypoints),
      if (polylinePointsForDB != null) 'polylinePointsForDB': jsonEncode(polylinePointsForDB),
      'distanceKm': distanceKm,
      // Appwrite maneja $createdAt y $updatedAt automáticamente
    };
  }
}