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
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10), 
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                height: 80, 
                child: ClipRRect( 
                  borderRadius: BorderRadius.circular(8.0),
                  child: (trip.vehicleImageUrl != null && trip.vehicleImageUrl!.isNotEmpty)
                      ? FadeInImage.assetNetwork( 
                          placeholder: 'assets/images/placeholder_car.png',
                          image: trip.vehicleImageUrl!,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            print("Error cargando vehicleImageUrl: $error");
                            return Image.asset(
                              'assets/images/placeholder_car_error.png', 
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Container( 
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            
                          ),
                          child: Icon(
                            Icons.directions_car_filled_outlined,
                            size: 40,
                            color: Theme.of(context).primaryColor.withOpacity(0.7),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      '${trip.vehicleBrand} ${trip.vehicleModel} (${trip.vehicleYear})',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd MMM, yyyy', 'es_CO').format(trip.createdAt.toLocal()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent[100]),
                  onPressed: onDelete,
                  tooltip: 'Eliminar recorrido',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}