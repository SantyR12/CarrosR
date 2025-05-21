import 'dart:io';
import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/data/models/user_profile_model.dart';
import 'package:distincia_carros/data/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
class ProfileController extends GetxController {
  final ProfileRepository _profileRepository = ProfileRepository();

  Rx<UserProfile?> userProfile = Rx<UserProfile?>(null);
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  final ImagePicker _picker = ImagePicker();
  Rx<File?> pickedImageFile = Rx<File?>(null); 

  @override
  void onInit() {
    super.onInit();
    ever(Get.find<AuthController>().appwriteUser, (ModelsUser) { 
      if (ModelsUser != null) {
        fetchUserProfile();
      } else {
        userProfile.value = null;
        pickedImageFile.value = null;
      }
    });
    if (Get.find<AuthController>().appwriteUser.value != null) {
        fetchUserProfile();
    }
  }

  Future<void> fetchUserProfile() async {
    final authController = Get.find<AuthController>();
    final userId = authController.appwriteUser.value?.$id;

    if (userId == null) {
      errorMessage.value = "Usuario no autenticado. No se puede cargar el perfil.";
      userProfile.value = null; 
      print(errorMessage.value);
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      userProfile.value = await _profileRepository.getUserProfile(userId);
      if (userProfile.value == null) {
        print("No se encontró perfil para el usuario: $userId. Se podría crear uno nuevo.");
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
      UserProfile? existingProfile = await _profileRepository.getUserProfile(userId);
      if (existingProfile != null) {
        userProfile.value = existingProfile;
        print("Perfil ya existe para $userId. Cargado en lugar de crear.");
        return;
      }

      UserProfile newProfile = UserProfile(
        id: '', 
        userId: userId,
        name: name,
        email: email,
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
        id: userProfile.value!.id,
        userId: userProfile.value!.userId,
        name: name,
        email: userProfile.value!.email, 
        phone: phone,
        profileImageUrl: userProfile.value!.profileImageUrl,
        profileImageFileId: userProfile.value!.profileImageFileId,
      );

      userProfile.value = await _profileRepository.updateUserProfile(profileToUpdate, newImageFile: pickedImageFile.value);
      
      pickedImageFile.value = null; 
      Get.snackbar('Éxito', 'Perfil actualizado correctamente.', snackPosition: SnackPosition.BOTTOM);
      fetchUserProfile(); 
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
        imageQuality: 70, 
        maxWidth: 800,   
      );
      if (image != null) {
        pickedImageFile.value = File(image.path);
      }
    } catch (e) {
      errorMessage.value = "Error seleccionando imagen: $e";
      Get.snackbar('Error de Imagen', 'No se pudo seleccionar la imagen.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}