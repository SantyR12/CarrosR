import 'dart:io';
import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/controller/home_page_controller.dart';
import 'package:distincia_carros/data/models/trip_model.dart';
import 'package:distincia_carros/data/repositories/trip_repository.dart';
import 'package:distincia_carros/core/config/app_config.dart';
import 'package:distincia_carros/core/constants/appwrite_constants.dart'; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as latlong2; 
import 'package:image_picker/image_picker.dart'; 
import 'package:appwrite/appwrite.dart' as AppwriteSDK; 

class CarOption {
  final String displayName;
  final String assetPath;
  
  CarOption({required this.displayName, required this.assetPath});
}

class TripController extends GetxController {
  final TripRepository _tripRepository = TripRepository();
  final AuthController _authController = Get.find<AuthController>();
  final AppwriteSDK.Storage _storage = AppwriteSDK.Storage(AppConfig.client); 

  RxList<Trip> userTrips = <Trip>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  Rx<File?> pickedVehicleImageFile = Rx<File?>(null);
  RxString selectedDefaultCarAssetPath = ''.obs;

  final List<CarOption> carOptions = <CarOption>[
    CarOption(displayName: 'Chevrolet', assetPath: 'assets/images/chevrolet_sonic.png'),
    CarOption(displayName: 'Chevrolet', assetPath: 'assets/images/chevrolet_spark.png'),
    CarOption(displayName: 'Toyota', assetPath: 'assets/images/toyota_corolla.png'),
    CarOption(displayName: 'Toyota', assetPath: 'assets/images/toyota_corolla_cross.png'),
    CarOption(displayName: 'Mazda', assetPath: 'assets/images/mazda_3.png'),
    CarOption(displayName: 'Renault', assetPath: 'assets/images/renault_sandero.png'),
    CarOption(displayName: 'Hyundai', assetPath: 'assets/images/hyundai_tucson.png'),
    CarOption(displayName: 'Hyundai', assetPath: 'assets/images/hyundai_i25.png'),
    CarOption(displayName: 'Kia', assetPath: 'assets/images/kia_rio.png'),
    CarOption(displayName: 'Kia', assetPath: 'assets/images/kia_picanto.png'),
  ];


  final formKeyCreateTrip = GlobalKey<FormState>();
  TextEditingController vehicleBrandController = TextEditingController();
  TextEditingController vehicleModelController = TextEditingController();
  TextEditingController vehicleYearController = TextEditingController();
  TextEditingController tripDescriptionController = TextEditingController();
  TextEditingController tripTitleController = TextEditingController();
  

  Rx<latlong2.LatLng?> startPoint = Rx<latlong2.LatLng?>(null);
  Rx<latlong2.LatLng?> endPoint = Rx<latlong2.LatLng?>(null);
  RxList<latlong2.LatLng> waypoints = <latlong2.LatLng>[].obs;
  RxDouble calculatedDistanceKm = 0.0.obs;
  RxList<Map<String, double>> polylinePointsForDB = <Map<String, double>>[].obs;

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
        imageQuality: 70,
        maxWidth: 1024,   
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
        bucketId: AppwriteConstants.profileImagesBucketId,
        fileId: AppwriteSDK.ID.unique(),
        file: AppwriteSDK.InputFile.fromPath(
          path: imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        permissions: [
          AppwriteSDK.Permission.read(AppwriteSDK.Role.any()), 
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
    isLoading.value = true;
    errorMessage.value = '';

    String? vehicleImgUrl;
    String? vehicleImgFileId;

    if (pickedVehicleImageFile.value != null) {
      final uploadResult = await _uploadVehicleImage(userId, pickedVehicleImageFile.value!);
      if (uploadResult != null) {
        vehicleImgUrl = uploadResult['url'];
        vehicleImgFileId = uploadResult['fileId'];
      } else {
        isLoading.value = false;
        Get.snackbar('Error', 'Falló la subida de la imagen del vehículo. Intenta de nuevo.');
        return; 
      }
    }

    try {
      Trip newTrip = Trip(
        id: '',
        userId: userId,
        vehicleBrand: vehicleBrandController.text.trim(),
        vehicleModel: vehicleModelController.text.trim(),
        vehicleYear: int.parse(vehicleYearController.text.trim()),
        tripDescription: tripDescriptionController.text.trim(),
        tripTitle: tripTitleController.text.trim().isNotEmpty 
            ? tripTitleController.text.trim() 
            : "Recorrido - ${DateTime.now().day}/${DateTime.now().month}",
        vehicleImageUrl: vehicleImgUrl,         
        vehicleImageFileId: vehicleImgFileId,  
        startLatitude: startPoint.value!.latitude,
        startLongitude: startPoint.value!.longitude,
        endLatitude: endPoint.value!.latitude,
        endLongitude: endPoint.value!.longitude,
        waypoints: waypoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        polylinePointsForDB: polylinePointsForDB.toList(),
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
    pickedVehicleImageFile.value = null;
    startPoint.value = null;
    endPoint.value = null;
    waypoints.clear();
    polylinePointsForDB.clear();
    calculatedDistanceKm.value = 0.0;
  }

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