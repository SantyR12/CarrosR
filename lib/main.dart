// lib/main.dart
import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/controller/home_page_controller.dart';
import 'package:distincia_carros/data/repositories/auth_repository.dart';
import 'package:distincia_carros/presentation/pages/home_page.dart';
import 'package:distincia_carros/presentation/pages/login_page.dart';
import 'package:distincia_carros/presentation/pages/register_page.dart';
import 'package:flutter/material.dart'; // Para localización de fechas
import 'package:get/get.dart';
import 'package:distincia_carros/core/config/app_config.dart';
import 'package:distincia_carros/controller/profile_controller.dart';
import 'package:distincia_carros/controller/trip_controller.dart'; // Asegúrate que este también se importa
import 'package:flutter_localizations/flutter_localizations.dart';
// Importar HomePageController
import 'package:distincia_carros/controller/trip_controller.dart'; // Ya está, pero si lo moviste a otro archivo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de Appwrite (ya la tienes)
  final account = AppConfig.account;
  final authRepository = AuthRepository(account);

  // Inyectar controladores principales con GetX
  // Es importante el orden si uno depende de otro en su `onInit`
  Get.put(AuthController(authRepository));
  Get.put(ProfileController());   // ProfileController ahora depende de AuthController vía Get.find()
  Get.put(TripController());      // TripController también depende de AuthController vía Get.find()
  Get.put(HomePageController());  // Inyectar el controlador para el BottomNavBar de HomePage

  final authController = Get.find<AuthController>();
  // `checkAuth` ahora se llama en el constructor de AuthController o en un _initialize
  // y actualiza `appwriteUser`. Esperamos a que termine la inicialización.
  await authController.checkAuth(); // Si tienes un Future en AuthController para esto

  bool isLoggedIn = authController.appwriteUser.value != null;

  // Si está logueado, los controladores de Profile y Trip ya tienen lógica en su `onInit`
  // (o a través de `ever` en AuthController) para cargar datos.

  runApp(
    GetMaterialApp(
      title: 'Mis Recorridos App',
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(name: '/home', page: () => HomePage()),
        // No necesitas definir rutas para las páginas internas si navegas
        // con Get.to(() => NombrePagina()), lo cual es más simple para este caso.
      ],
      // Configuración de Tema (Ejemplo)
      theme: ThemeData(
        primarySwatch: Colors.teal, // Color principal
        // primaryColor: Colors.teal[600], // Un tono específico
        scaffoldBackgroundColor: Colors.grey[50], // Fondo general
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white, // Color del texto y los iconos en AppBar
          elevation: 2,
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.teal[700]!, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIconColor: Colors.grey[600],
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4)
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.teal[700],
          unselectedItemColor: Colors.grey[500],
          backgroundColor: Colors.white,
          elevation: 8,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
        ),
        // ... más personalizaciones de tema
      ),
      // Para la localización de fechas (ej. DateFormat en TripDetailsPage)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'), // Español de Colombia
        Locale('en', 'US'), // Inglés como fallback o alternativa
        // ... otros locales que soportes
      ],
      locale: const Locale('es', 'CO'), // Establecer el locale por defecto
    ),
  );
}