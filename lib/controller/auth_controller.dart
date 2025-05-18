// lib/controller/auth_controller.dart
import 'package:distincia_carros/data/repositories/auth_repository.dart';
import 'package:distincia_carros/presentation/pages/home_page.dart'; // Asegúrate que esta ruta sea correcta
import 'package:distincia_carros/presentation/pages/login_page.dart';  // Asegúrate que esta ruta sea correcta
import 'package:flutter/material.dart'; // Para Get.snackbar y otros
import 'package:get/get.dart';
import 'package:appwrite/models.dart' as Models; // Para el tipo Models.User
import 'package:distincia_carros/core/config/app_config.dart'; // Para AppConfig.account
import 'package:distincia_carros/controller/profile_controller.dart';
import 'package:distincia_carros/controller/trip_controller.dart';


class AuthController extends GetxController {
  final AuthRepository _authRepository;

  RxBool isLoading = false.obs;
  RxString error = ''.obs;
  Rx<Models.User?> appwriteUser = Rx<Models.User?>(null);

  AuthController(this._authRepository) {
    // Llama a checkAuth al inicializar para restaurar el estado si ya está logueado.
     _initialize();
  }

  Future<void> _initialize() async {
    await checkAuth();
  }


  Future<bool> checkAuth() async {
    isLoading.value = true;
    error.value = '';
    try {
      // Usamos la instancia de Account directamente desde AppConfig
      final currentUser = await AppConfig.account.get();
      appwriteUser.value = currentUser;
      if (currentUser.$id.isNotEmpty) { // Chequeo más robusto
        // Si está autenticado, intenta cargar su perfil
        // Asegúrate que ProfileController esté disponible vía Get.find()
        // y que maneje el caso donde el perfil aún no existe.
        // Esto se puede hacer en el onInit de ProfileController también.
        // Get.find<ProfileController>().fetchUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      appwriteUser.value = null;
      // No mostramos error aquí, es normal si no hay sesión
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
      // Después de registrar, iniciar sesión para obtener el User object
      // y luego crear el perfil inicial.
      await login(email, password, isAfterRegistration: true, registrationName: name);
      // La navegación y creación de perfil se manejan dentro de login ahora
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
      // Actualizar el usuario de Appwrite en el controlador
      await checkAuth();

      if (appwriteUser.value != null) {
        // Inyectar y/o encontrar ProfileController y TripController
        // Asegúrate de que ya estén en Get o inyéctalos si es la primera vez.
        // Por lo general, se inyectan en main.dart con Get.put()
        final profileController = Get.find<ProfileController>();
        Get.find<TripController>(); // Para inicializarlo si no lo está

        if (isAfterRegistration && registrationName != null) {
          // Crear perfil inicial después del registro
          await profileController.createInitialProfile(registrationName, email);
        } else {
          // Cargar perfil existente
          await profileController.fetchUserProfile();
        }
        
        Get.offAll(() => HomePage()); // Usar Get.offAll para limpiar stack de login/registro
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
      appwriteUser.value = null; // Limpiar usuario actual

      // Limpiar datos de los otros controladores
      if (Get.isRegistered<TripController>()) {
        Get.find<TripController>().userTrips.clear();
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().userProfile.value = null;
        Get.find<ProfileController>().pickedImageFile.value = null;
      }
      
      Get.offAll(() => LoginPage()); // Navegar a Login y limpiar stack
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