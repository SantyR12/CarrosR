import 'package:distincia_carros/data/repositories/auth_repository.dart';
import 'package:distincia_carros/presentation/pages/home_page.dart'; 
import 'package:distincia_carros/presentation/pages/login_page.dart';  
import 'package:flutter/material.dart'; 
import 'package:get/get.dart';
import 'package:appwrite/models.dart' as Models; 
import 'package:distincia_carros/core/config/app_config.dart'; 
import 'package:distincia_carros/controller/profile_controller.dart';
import 'package:distincia_carros/controller/trip_controller.dart';
class AuthController extends GetxController {
  final AuthRepository _authRepository;

  RxBool isLoading = false.obs;
  RxString error = ''.obs;
  Rx<Models.User?> appwriteUser = Rx<Models.User?>(null);

  AuthController(this._authRepository) {
     _initialize();
  }

  Future<void> _initialize() async {
    await checkAuth();
  }


  Future<bool> checkAuth() async {
    isLoading.value = true;
    error.value = '';
    try {
      final currentUser = await AppConfig.account.get();
      appwriteUser.value = currentUser;
      if (currentUser.$id.isNotEmpty) { 
        return true;
      }
      return false;
    } catch (e) {
      appwriteUser.value = null;
      print("CheckAuth: No hay sesión activa o error: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String email, String password, String name) async {
    isLoading.value = true;
    error.value = '';
    try {
      await _authRepository.createAccount(email: email, password: password, name: name);
      await login(email, password, isAfterRegistration: true, registrationName: name);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        "Error de Registro",
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password, {bool isAfterRegistration = false, String? registrationName}) async {
    isLoading.value = true;
    error.value = '';
    try {
      await _authRepository.login(email: email, password: password);
      await checkAuth();

      if (appwriteUser.value != null) {
        final profileController = Get.find<ProfileController>();
        Get.find<TripController>(); 

        if (isAfterRegistration && registrationName != null) {
          await profileController.createInitialProfile(registrationName, email);
        } else {
          await profileController.fetchUserProfile();
        }
        
        Get.offAll(() => HomePage());
      } else {
        error.value = "No se pudo obtener la información del usuario tras el login.";
        Get.snackbar(
          "Error de Login",
          error.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        "Error de Login",
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    error.value = '';
    try {
      await _authRepository.logout();
      appwriteUser.value = null; 
      if (Get.isRegistered<TripController>()) {
        Get.find<TripController>().userTrips.clear();
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().userProfile.value = null;
        Get.find<ProfileController>().pickedImageFile.value = null;
      }
      
      Get.offAll(() => LoginPage()); 
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        "Error al Cerrar Sesión",
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}