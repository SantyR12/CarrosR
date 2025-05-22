// lib/presentation/widgets/trip_list_item.dart
import 'package:distincia_carros/data/models/trip_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

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
      clipBehavior: Clip.antiAlias, // Para que la imagen respete los bordes redondeados
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10), // Debe coincidir con el Card
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Para alinear mejor si el texto es multilínea
            children: [
              // Izquierda: Imagen del Vehículo o Placeholder
              SizedBox(
                width: 80, // Ancho de la imagen/placeholder
                height: 80, // Alto de la imagen/placeholder
                child: ClipRRect( // Para redondear la imagen misma
                  borderRadius: BorderRadius.circular(8.0),
                  child: (trip.vehicleImageUrl != null && trip.vehicleImageUrl!.isNotEmpty)
                      ? FadeInImage.assetNetwork( // Efecto de carga suave
                          placeholder: 'assets/images/placeholder_car.png', // <--- NECESITAS UNA IMAGEN PLACEHOLDER EN TUS ASSETS
                          image: trip.vehicleImageUrl!,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            // Placeholder si hay error cargando la imagen de red
                            print("Error cargando vehicleImageUrl: $error");
                            return Image.asset(
                              'assets/images/placeholder_car_error.png', // <--- OTRA IMAGEN PLACEHOLDER PARA ERRORES
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Container( // Placeholder si no hay imagen del vehículo
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            // borderRadius: BorderRadius.circular(8.0), // Ya está en ClipRRect
                          ),
                          child: Icon(
                            Icons.directions_car_filled_outlined, // Icono de carro
                            size: 40,
                            color: Theme.of(context).primaryColor.withOpacity(0.7),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16), // Espacio entre imagen y texto
              // Centro: Información del recorrido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // Para centrar verticalmente si el alto es fijo
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
              // Derecha: Botón de eliminar
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