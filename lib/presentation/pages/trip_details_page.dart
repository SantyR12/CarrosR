
import 'dart:async';
import 'package:distincia_carros/data/models/trip_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

const String MAPTILER_API_KEY_DETAILS = "IMdKNAWagDsTUpy68b5d";

class TripDetailsPage extends StatefulWidget {
  final Trip trip;
  const TripDetailsPage({super.key, required this.trip});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  List<latlong.LatLng> _routePointsForMapVisual = [];
  bool _isMapDetailsReady = false;

  @override
  void initState() {
    super.initState();
  }

  void _initializeDetailsMapData() {
    _buildMapElements();
  }

  void _buildMapElements() {
    List<Marker> localMarkers = [];
    List<latlong.LatLng> mainTripPoints = [];

    final startPoint = latlong.LatLng(widget.trip.startLatitude, widget.trip.startLongitude);
    localMarkers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: startPoint,
        child: Tooltip(message: "Inicio", child: Icon(Icons.location_on, color: Colors.green[700], size: 40)),
      ),
    );
    mainTripPoints.add(startPoint);

    widget.trip.waypoints.forEach((wp) {
      if (wp['lat'] != null && wp['lng'] != null) {
        final waypoint = latlong.LatLng(wp['lat']!, wp['lng']!);
        localMarkers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: waypoint,
            child: Tooltip(message: "Parada", child: Icon(Icons.flag_circle_outlined, color: Colors.blue[600], size: 35)),
          ),
        );
        mainTripPoints.add(waypoint);
      }
    });

    final endPoint = latlong.LatLng(widget.trip.endLatitude, widget.trip.endLongitude);
    localMarkers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: endPoint,
        child: Tooltip(message: "Fin", child: Icon(Icons.location_on, color: Colors.red[700], size: 40)),
      ),
    );
    mainTripPoints.add(endPoint);

    List<Polyline> localPolylines = [];

    if (widget.trip.polylinePointsForDB != null && widget.trip.polylinePointsForDB!.isNotEmpty) {
      _routePointsForMapVisual = widget.trip.polylinePointsForDB!
          .map((p) => latlong.LatLng(p['lat']!, p['lng']!))
          .toList();
    } else {
      _routePointsForMapVisual = mainTripPoints;
    }

    if (_routePointsForMapVisual.length >= 2) {
      localPolylines.add(Polyline(
        points: _routePointsForMapVisual,
        strokeWidth: 5.0,
        color: Colors.teal[600]!, 
      ));
    }

    if (mounted) {
      setState(() {
        _markers = localMarkers;
        _polylines = localPolylines;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isMapDetailsReady) _centerMapOnRoute();
      });
    }
  }

  void _centerMapOnRoute() {
    if (!_isMapDetailsReady || !mounted) return;

    List<latlong.LatLng> pointsToBound = [];
    if (_routePointsForMapVisual.isNotEmpty) {
      pointsToBound.addAll(_routePointsForMapVisual);
    } else if (_markers.isNotEmpty) {
      _markers.forEach((m) => pointsToBound.add(m.point));
    }

    if (pointsToBound.isNotEmpty) {
      var calculatedBounds = LatLngBounds.fromPoints(pointsToBound); 

      bool canFitBounds = pointsToBound.length > 1 &&
                          calculatedBounds.southWest != null &&
                          calculatedBounds.northEast != null &&
                          (calculatedBounds.southWest!.latitude != calculatedBounds.northEast!.latitude ||
                           calculatedBounds.southWest!.longitude != calculatedBounds.northEast!.longitude);

      if (canFitBounds) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: calculatedBounds,
            padding: const EdgeInsets.all(50.0),
          ),
        );
      } else if (pointsToBound.length == 1) {
        _mapController.move(pointsToBound.first, 15.0);
      } else {
        print("Bounds no válidos en detalles o solo un punto. Centrando en el punto de inicio del viaje.");
        _mapController.move(latlong.LatLng(widget.trip.startLatitude, widget.trip.startLongitude), 12.0);
      }
    } else {
      print("No hay puntos para crear bounds en detalles. Centrando en el punto de inicio del viaje.");
      _mapController.move(latlong.LatLng(widget.trip.startLatitude, widget.trip.startLongitude), 12.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    latlong.LatLng initialMapCenter = latlong.LatLng(widget.trip.startLatitude, widget.trip.startLongitude);
    if (_markers.isNotEmpty && _routePointsForMapVisual.isEmpty) {
      double avgLat = _markers.map((m) => m.point.latitude).reduce((a, b) => a + b) / _markers.length;
      double avgLng = _markers.map((m) => m.point.longitude).reduce((a, b) => a + b) / _markers.length;
      initialMapCenter = latlong.LatLng(avgLat, avgLng);
    } else if (_routePointsForMapVisual.isNotEmpty) {
      double avgLat = _routePointsForMapVisual.map((p) => p.latitude).reduce((a,b) => a+b) / _routePointsForMapVisual.length;
      double avgLng = _routePointsForMapVisual.map((p) => p.longitude).reduce((a,b) => a+b) / _routePointsForMapVisual.length;
      initialMapCenter = latlong.LatLng(avgLat, avgLng);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.tripTitle.isNotEmpty ? widget.trip.tripTitle : 'Detalles del Recorrido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: <Widget>[
          if (widget.trip.vehicleImageUrl != null && widget.trip.vehicleImageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/images/placeholder_car.png',
                  image: widget.trip.vehicleImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300], 
                      child: Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey[600])),
                    );
                  },
                ),
              ),
            ),
          Container(
            height: 280,
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialMapCenter,
                  initialZoom: 12,
                  onMapReady: () {
                    if (mounted) {
                      setState(() {
                        _isMapDetailsReady = true;
                      });
                      _initializeDetailsMapData();
                    }
                  }
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$MAPTILER_API_KEY_DETAILS",
                    userAgentPackageName: 'com.example.distincia_carros',
                  ),
                  if (_polylines.isNotEmpty && _polylines.first.points.isNotEmpty && _polylines.first.points.length >=2)
                    PolylineLayer(polylines: _polylines),
                  MarkerLayer(markers: _markers),
                ],
              ),
            ),
          ),
          _buildDetailSection(
            context,
            title: "Vehículo Utilizado",
            icon: Icons.directions_car_filled_outlined,
            details: [
              _buildDetailItem("Marca:", widget.trip.vehicleBrand),
              _buildDetailItem("Modelo:", widget.trip.vehicleModel),
              _buildDetailItem("Año:", widget.trip.vehicleYear.toString()),
            ],
          ),
          _buildDetailSection(
            context,
            title: "Información del Recorrido",
            icon: Icons.article_outlined,
            details: [
              _buildDetailItem("Título:", widget.trip.tripTitle),
              _buildDetailItem("Descripción:", widget.trip.tripDescription, isMultiline: true),
              _buildDetailItem("Distancia:", "${widget.trip.distanceKm.toStringAsFixed(1)} km"),
              _buildDetailItem("Fecha:", DateFormat('EEEE, dd MMMM, hh:mm a', 'es_CO').format(widget.trip.createdAt.toLocal())),
            ],
          ),
          const SizedBox(height: 20), 
        ],
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, {required String title, required IconData icon, required List<Widget> details}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 26, color: Theme.of(context).primaryColorDark),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: Theme.of(context).primaryColorDark
                      ),
                ),
              ],
            ),
            Divider(height: 20, thickness: 0.8, color: Colors.grey[200]),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isMultiline = false}) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110, 
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "No especificado",
              style: TextStyle(fontSize: 15, color: Colors.black.withOpacity(0.75)),
              softWrap: isMultiline,
              textAlign: isMultiline ? TextAlign.justify : TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}