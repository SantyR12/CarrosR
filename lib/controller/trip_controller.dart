// lib/controller/trip_controller.dart
import 'dart:io'; // Para File
import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/controller/home_page_controller.dart';
import 'package:distincia_carros/data/models/trip_model.dart';
import 'package:distincia_carros/data/repositories/trip_repository.dart';
import 'package:distincia_carros/core/config/app_config.dart'; // Para Storage y AppwriteConstants
import 'package:distincia_carros/core/constants/appwrite_constants.dart'; // Para AppwriteConstants
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Asegúrate que LatLng sea el de latlong2 si es lo que usa flutter_map
import 'package:latlong2/latlong.dart' as latlong2; // O el tipo que estés usando consistentemente
import 'package:image_picker/image_picker.dart'; // Para image_picker
import 'package:appwrite/appwrite.dart' as AppwriteSDK; // Para ID y InputFile


class TripController extends GetxController {
  final TripRepository _tripRepository = TripRepository();
  final AuthController _authController = Get.find<AuthController>();
  final AppwriteSDK.Storage _storage = AppwriteSDK.Storage(AppConfig.client); // Instancia de Storage

  RxList<Trip> userTrips = <Trip>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  // --- Para el formulario de creación de Recorrido ---
  final formKeyCreateTrip = GlobalKey<FormState>();
  TextEditingController vehicleBrandController = TextEditingController();
  TextEditingController vehicleModelController = TextEditingController();
  TextEditingController vehicleYearController = TextEditingController();
  TextEditingController tripDescriptionController = TextEditingController();
  TextEditingController tripTitleController = TextEditingController();
  Rx<File?> pickedVehicleImageFile = Rx<File?>(null); // Para la imagen del vehículo seleccionada

  // --- Para la página del mapa ---
  // Asegúrate que el tipo de LatLng sea consistente con flutter_map (latlong2.LatLng)
  Rx<latlong2.LatLng?> startPoint = Rx<latlong2.LatLng?>(null);
  Rx<latlong2.LatLng?> endPoint = Rx<latlong2.LatLng?>(null);
  RxList<latlong2.LatLng> waypoints = <latlong2.LatLng>[].obs;
  RxDouble calculatedDistanceKm = 0.0.obs;
  RxList<Map<String, double>> polylinePointsForDB = <Map<String, double>>[].obs;

  // ... (métodos onInit y fetchUserTrips sin cambios)
    @override
  void onInit() {
    super.onInit();
    ever(Get.find<AuthController>().appwriteUser, (appwriteUserModel) {
      if (appwriteUserModel != null) {
        fetchUserTrips();
      } else {
        userTrips.clear();
        clearTripCreationData(); 
      }
    });
    if (Get.find<AuthController>().appwriteUser.value != null) {
        fetchUserTrips();
    }
  }

  Future<void> fetchUserTrips() async {
    final userId = _authController.appwriteUser.value?.$id;
    if (userId == null) {
      errorMessage.value = "Usuario no autenticado.";
      userTrips.clear();
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      userTrips.value = await _tripRepository.getUserTrips(userId);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar("Error", "No se pudieron cargar tus recorridos: ${errorMessage.value}");
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> pickVehicleImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, // Comprimir un poco
        maxWidth: 1024,   // Reducir dimensiones si es muy grande
      );
      if (image != null) {
        pickedVehicleImageFile.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Error de Imagen', 'No se pudo seleccionar la imagen: $e');
    }
  }

  Future<Map<String, String>?> _uploadVehicleImage(String userId, File imageFile) async {
    if (userId.isEmpty) return null;
    try {
      final uploadedFile = await _storage.createFile(
        bucketId: AppwriteConstants.profileImagesBucketId, // Usando el mismo bucket
        fileId: AppwriteSDK.ID.unique(),
        file: AppwriteSDK.InputFile.fromPath(
          path: imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        permissions: [
          AppwriteSDK.Permission.read(AppwriteSDK.Role.any()), // Para URL pública
          AppwriteSDK.Permission.update(AppwriteSDK.Role.user(userId)),
          AppwriteSDK.Permission.delete(AppwriteSDK.Role.user(userId)),
        ],
      );

      final String imageUrl =
          "${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.profileImagesBucketId}/files/${uploadedFile.$id}/view?project=${AppwriteConstants.projectId}";
      
      return {'url': imageUrl, 'fileId': uploadedFile.$id};
    } catch (e) {
      print('Error subiendo imagen del vehículo: $e');
      Get.snackbar('Error de Subida', 'No se pudo subir la imagen del vehículo.');
      return null;
    }
  }

  Future<void> saveNewTrip() async {
    final userId = _authController.appwriteUser.value?.$id;
    if (userId == null) {
      Get.snackbar('Error', 'No estás autenticado.');
      return;
    }
    if (!formKeyCreateTrip.currentState!.validate()) {
      Get.snackbar('Atención', 'Completa todos los campos requeridos.');
      return;
    }
    if (startPoint.value == null || endPoint.value == null) {
      Get.snackbar('Error de Mapa', 'Define inicio y fin en el mapa.');
      return;
    }
    // No es estrictamente necesario que la distancia sea > 0 si el usuario puede querer registrar un punto.
    // if (calculatedDistanceKm.value <= 0) {
    //   Get.snackbar('Error de Mapa', 'La distancia debe ser mayor a cero.');
    //   return;
    // }

    isLoading.value = true;
    errorMessage.value = '';

    String? vehicleImgUrl;
    String? vehicleImgFileId;

    // Subir imagen del vehículo si se seleccionó una
    if (pickedVehicleImageFile.value != null) {
      final uploadResult = await _uploadVehicleImage(userId, pickedVehicleImageFile.value!);
      if (uploadResult != null) {
        vehicleImgUrl = uploadResult['url'];
        vehicleImgFileId = uploadResult['fileId'];
      } else {
        // Falló la subida de imagen, ¿continuar sin imagen o detener?
        isLoading.value = false;
        Get.snackbar('Error', 'Falló la subida de la imagen del vehículo. Intenta de nuevo.');
        return; // Detener si la imagen es crucial o si hubo un error de subida
      }
    }

    try {
      Trip newTrip = Trip(
        id: '', // Appwrite lo generará
        userId: userId,
        vehicleBrand: vehicleBrandController.text.trim(),
        vehicleModel: vehicleModelController.text.trim(),
        vehicleYear: int.parse(vehicleYearController.text.trim()),
        tripDescription: tripDescriptionController.text.trim(),
        tripTitle: tripTitleController.text.trim().isNotEmpty 
            ? tripTitleController.text.trim() 
            : "Recorrido - ${DateTime.now().day}/${DateTime.now().month}",
        vehicleImageUrl: vehicleImgUrl,         // Pasar URL de imagen
        vehicleImageFileId: vehicleImgFileId,   // Pasar File ID de imagen
        startLatitude: startPoint.value!.latitude,
        startLongitude: startPoint.value!.longitude,
        endLatitude: endPoint.value!.latitude,
        endLongitude: endPoint.value!.longitude,
        waypoints: waypoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        polylinePointsForDB: polylinePointsForDB.toList(), // Asegúrate que esto se llene en MapRoutePage
        distanceKm: calculatedDistanceKm.value,
        createdAt: DateTime.now(),
      );

      await _tripRepository.createTrip(newTrip);
      fetchUserTrips();
      
      Get.snackbar('Éxito', 'Recorrido guardado correctamente.', snackPosition: SnackPosition.BOTTOM);
      
      if(Get.isRegistered<HomePageController>()){
        Get.find<HomePageController>().changeTabIndex(0);
      }
      Get.until((route) => Get.currentRoute == '/home' || Get.currentRoute == '/');
      clearTripCreationData();

    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('Error', 'No se pudo guardar el recorrido: ${errorMessage.value}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void clearTripCreationData() {
    vehicleBrandController.clear();
    vehicleModelController.clear();
    vehicleYearController.clear();
    tripDescriptionController.clear();
    tripTitleController.clear();
    pickedVehicleImageFile.value = null; // Limpiar imagen seleccionada
    startPoint.value = null;
    endPoint.value = null;
    waypoints.clear();
    polylinePointsForDB.clear();
    calculatedDistanceKm.value = 0.0;
  }

  // ... (método deleteTrip sin cambios)
  Future<void> deleteTrip(String tripId) async {
    bool confirmDelete = await Get.dialog(
      AlertDialog(
        title: const Text("Confirmar Eliminación"),
        content: const Text("¿Estás seguro de que quieres eliminar este recorrido? Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: false,
    ) ?? false;

    if (!confirmDelete) return;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _tripRepository.deleteTrip(tripId);
      userTrips.removeWhere((trip) => trip.id == tripId);
      Get.snackbar('Éxito', 'Recorrido eliminado.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('Error', 'No se pudo eliminar el recorrido: ${errorMessage.value}');
    } finally {
      isLoading.value = false;
    }
  }
}

// HomePageController ya está definido en su propio bloque o archivo.
// Si no, descomenta y ajusta:
// class HomePageController extends GetxController {
//   var tabIndex = 0.obs;
//   void changeTabIndex(int index) {
//     tabIndex.value = index;
//   }
// }