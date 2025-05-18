// lib/controller/profile_controller.dart
import 'dart:io';
import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/data/models/user_profile_model.dart';
import 'package:distincia_carros/data/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final ProfileRepository _profileRepository = ProfileRepository();
  // AuthController se obtendrá con Get.find() cuando se necesite,
  // para evitar dependencia circular directa en la inicialización.

  Rx<UserProfile?> userProfile = Rx<UserProfile?>(null);
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  final ImagePicker _picker = ImagePicker();
  Rx<File?> pickedImageFile = Rx<File?>(null); // Para la previsualización de la imagen

  @override
  void onInit() {
    super.onInit();
    // Escuchar cambios en el usuario autenticado para cargar/limpiar el perfil
    ever(Get.find<AuthController>().appwriteUser, (ModelsUser) { // ModelsUser es Models.User?
      if (ModelsUser != null) {
        fetchUserProfile();
      } else {
        userProfile.value = null;
        pickedImageFile.value = null;
      }
    });
    // Carga inicial si el usuario ya está logueado al iniciar el controller
    if (Get.find<AuthController>().appwriteUser.value != null) {
        fetchUserProfile();
    }
  }

  Future<void> fetchUserProfile() async {
    final authController = Get.find<AuthController>();
    final userId = authController.appwriteUser.value?.$id;

    if (userId == null) {
      errorMessage.value = "Usuario no autenticado. No se puede cargar el perfil.";
      userProfile.value = null; // Asegurar que el perfil se limpie
      print(errorMessage.value);
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      userProfile.value = await _profileRepository.getUserProfile(userId);
      if (userProfile.value == null) {
        print("No se encontró perfil para el usuario: $userId. Se podría crear uno nuevo.");
        // Considera si quieres crear un perfil automáticamente aquí
        // o manejarlo desde la UI (ej. un botón "Crear mi perfil").
        // Por ahora, solo se loguea. La creación se maneja tras el registro.
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      print("Error en fetchUserProfile: $e");
      Get.snackbar("Error de Perfil", "No se pudo cargar el perfil: ${errorMessage.value}",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createInitialProfile(String name, String email) async {
    final authController = Get.find<AuthController>();
    final userId = authController.appwriteUser.value?.$id;
    if (userId == null) {
      errorMessage.value = "No se puede crear perfil: Usuario no autenticado.";
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      // Verificar si ya existe un perfil para evitar duplicados
      UserProfile? existingProfile = await _profileRepository.getUserProfile(userId);
      if (existingProfile != null) {
        userProfile.value = existingProfile;
        print("Perfil ya existe para $userId. Cargado en lugar de crear.");
        return;
      }

      UserProfile newProfile = UserProfile(
        id: '', // Appwrite lo generará, ProfileRepository espera un ID para update, no para create
        userId: userId,
        name: name,
        email: email,
        // phone, profileImageUrl, profileImageFileId son opcionales y se pueden añadir después
      );
      userProfile.value = await _profileRepository.createUserProfile(newProfile);
      Get.snackbar('Perfil Creado', 'Tu perfil básico ha sido configurado.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      errorMessage.value = "Error creando perfil inicial: ${e.toString().replaceFirst('Exception: ', '')}";
      print(errorMessage.value);
      Get.snackbar("Error de Perfil", errorMessage.value,
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserProfileData({
    required String name,
    String? phone,
    // La imagen (File) se toma de pickedImageFile.value
  }) async {
    if (userProfile.value == null) {
      errorMessage.value = "No hay perfil para actualizar.";
      Get.snackbar("Error", errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      UserProfile profileToUpdate = UserProfile(
        id: userProfile.value!.id, // ID del documento existente
        userId: userProfile.value!.userId,
        name: name,
        email: userProfile.value!.email, // Email no se actualiza desde aquí
        phone: phone,
        // Mantener la URL/FileId actual si no se elige una nueva imagen
        profileImageUrl: userProfile.value!.profileImageUrl,
        profileImageFileId: userProfile.value!.profileImageFileId,
      );

      // El ProfileRepository.updateUserProfile se encargará de subir `pickedImageFile.value` si existe
      userProfile.value = await _profileRepository.updateUserProfile(profileToUpdate, newImageFile: pickedImageFile.value);
      
      pickedImageFile.value = null; // Limpiar la imagen previsualizada después de guardar
      Get.snackbar('Éxito', 'Perfil actualizado correctamente.', snackPosition: SnackPosition.BOTTOM);
      fetchUserProfile(); // Recargar para asegurar consistencia, aunque updateUserProfile ya devuelve el actualizado.
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('Error', 'No se pudo actualizar el perfil: ${errorMessage.value}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Comprimir un poco la imagen
        maxWidth: 800,    // Reducir dimensiones si es muy grande
      );
      if (image != null) {
        pickedImageFile.value = File(image.path);
        // No se sube aquí, solo se previsualiza. La subida ocurre al guardar el perfil.
      }
    } catch (e) {
      errorMessage.value = "Error seleccionando imagen: $e";
      Get.snackbar('Error de Imagen', 'No se pudo seleccionar la imagen.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}