// lib/main.dart
import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/controller/home_page_controller.dart';
import 'package:distincia_carros/data/repositories/auth_repository.dart';
import 'package:distincia_carros/presentation/pages/home_page.dart';
import 'package:distincia_carros/presentation/pages/login_page.dart';
import 'package:distincia_carros/presentation/pages/register_page.dart';
import 'package:flutter/material.dart'; 
import 'package:get/get.dart';
import 'package:distincia_carros/core/config/app_config.dart';
import 'package:distincia_carros/controller/profile_controller.dart';
import 'package:distincia_carros/controller/trip_controller.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final account = AppConfig.account;
  final authRepository = AuthRepository(account);

  Get.put(AuthController(authRepository));
  Get.put(ProfileController());   
  Get.put(TripController());     
  Get.put(HomePageController());  

  final authController = Get.find<AuthController>();
  await authController.checkAuth(); 

  bool isLoggedIn = authController.appwriteUser.value != null;

  runApp(
    GetMaterialApp(
      title: 'Mis Recorridos App',
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(name: '/home', page: () => HomePage()),
        ],
      theme: ThemeData(
        primarySwatch: Colors.teal, 
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white, 
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
      ),
    supportedLocales: const [
        Locale('es', 'CO'), 
        Locale('en', 'US'), 
      ],
      locale: const Locale('es', 'CO'), 
    ),
  );
}