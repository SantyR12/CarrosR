import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/data/repositories/auth_repository.dart';
import 'package:distincia_carros/presentation/pages/home_page.dart';
import 'package:distincia_carros/presentation/pages/login_page.dart';
import 'package:distincia_carros/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:distincia_carros/core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtén la instancia de Account desde AppConfig
  final account = AppConfig.account;

  // Crea la instancia de AuthRepository PASANDO la instancia de Account DE FORMA POSICIONAL
  final authRepository = AuthRepository(account);

  Get.put(AuthController(authRepository)); // Inicializa el AuthController

  final authController = Get.find<AuthController>();
  final isLoggedIn = await authController.checkAuth();

  runApp(
    GetMaterialApp(
      title: 'Fitness App',
      initialRoute: isLoggedIn ? '/home' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(
          name: '/home',
          page: () => HomePage(),
        ), // Asegúrate de tener esta ruta
      ],
    ),
  );
}