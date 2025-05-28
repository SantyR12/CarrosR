import 'package:distincia_carros/controller/trip_controller.dart';
import 'package:distincia_carros/presentation/pages/map_route_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; 
class CreateTripFormPage extends StatelessWidget {
  final TripController tripController = Get.find<TripController>();

  CreateTripFormPage({super.key});

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Seleccionar de la Galería'),
                onTap: () {
                  tripController.pickVehicleImage(ImageSource.gallery);
                  Get.back();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una Foto'),
                onTap: () {
                  tripController.pickVehicleImage(ImageSource.camera);
                  Get.back();
                },
              ),
              if (tripController.pickedVehicleImageFile.value != null)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                  title: Text('Eliminar Imagen Seleccionada', style: TextStyle(color: Colors.red[700])),
                  onTap: () {
                    tripController.pickedVehicleImageFile.value = null;
                    Get.back();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });


    return Scaffold(
      body:Stack(
        children: [
          // FONDO DE IMAGEN
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/fondohomee.jpg"), // ASEGÚRATE QUE ESTE ASSET EXISTA
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6), // Oscurecer un poco más el fondo
                  BlendMode.darken,
                ),
              ),
            ),
          ),
            SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: tripController.formKeyCreateTrip,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Imagen del Vehículo (Opcional)",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showImagePickerOptions(context),
                child: Obx(() {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[400]!, width: 1.5),
                      image: tripController.pickedVehicleImageFile.value != null
                          ? DecorationImage(
                              image: FileImage(tripController.pickedVehicleImageFile.value!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: tripController.pickedVehicleImageFile.value == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text("Toca para añadir imagen", style: TextStyle(color: Colors.grey[700])),
                            ],
                          )
                        : Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red.withOpacity(0.8)),
                              onPressed: () {
                                tripController.pickedVehicleImageFile.value = null;
                              },
                            ),
                          ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Text(
                "Información del Recorrido",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: tripController.tripTitleController,
                decoration: InputDecoration(
                  labelText: 'Título del Recorrido',
                  hintText: 'Ej: Viaje a la Playa, Visita Cliente X',
                  prefixIcon: Icon(Icons.title_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'El título es requerido';
                  if (value.trim().length < 3) return 'Título muy corto';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tripController.vehicleBrandController,
                decoration: InputDecoration(
                  labelText: 'Marca del Vehículo',
                  prefixIcon: Icon(Icons.directions_car_filled_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'La marca es requerida' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tripController.vehicleModelController,
                decoration: InputDecoration(
                  labelText: 'Modelo del Vehículo',
                  prefixIcon: Icon(Icons.rv_hookup_outlined), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'El modelo es requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tripController.vehicleYearController,
                decoration: InputDecoration(
                  labelText: 'Año del Vehículo',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'El año es requerido';
                  if (value.length != 4) return 'Año inválido (ej: 2023)';
                  final year = int.tryParse(value);
                  if (year == null || year < 1900 || year > DateTime.now().year + 2) { 
                    return 'Año fuera de rango';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tripController.tripDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción del Recorrido',
                  hintText: 'Ej: Desde mi casa hasta la oficina...',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3, minLines: 1,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'La descripción es requerida' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text('Siguiente: Definir Ruta en Mapa'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () {
                  if (tripController.formKeyCreateTrip.currentState!.validate()) {
                    Get.to(() => MapRoutePage(), transition: Transition.cupertino); 
                  } else {
                    Get.snackbar(
                      "Campos Incompletos",
                      "Revisa y completa los campos marcados.",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.orange[800],
                      colorText: Colors.white,
                    );
                  }
                },
              ),
              const SizedBox(height: 20), 
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}