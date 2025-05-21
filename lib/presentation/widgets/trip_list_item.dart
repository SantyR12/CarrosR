import 'package:distincia_carros/data/models/trip_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class TripListItem extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TripListItem({
    super.key,
    required this.trip,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: trip.mapThumbnailUrl == null || trip.mapThumbnailUrl!.isEmpty
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: trip.mapThumbnailUrl == null || trip.mapThumbnailUrl!.isEmpty
                    ? Icon(Icons.route_outlined, size: 35, color: Theme.of(context).primaryColor)
                    : null, 
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      trip.tripTitle.isNotEmpty ? trip.tripTitle : "Recorrido",
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${trip.vehicleBrand} ${trip.vehicleModel} (${trip.vehicleYear})',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${trip.distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('dd MMM, yyyy').format(trip.createdAt.toLocal()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40, 
                child: IconButton(
                  icon: Icon(Icons.delete_sweep_outlined, color: Colors.redAccent[200]),
                  onPressed: onDelete,
                  tooltip: 'Eliminar recorrido',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(), 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}