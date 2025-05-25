
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
        scaffoldBackgroundColor: Colors.grey[100], 
        fontFamily: 'Nunito', 

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
          elevation: 4, 
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600, 
            letterSpacing: 0.5,
             color: Colors.white 
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 3,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, 
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey[350]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.teal[700]!, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.w500),
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIconColor: Colors.teal[700]?.withOpacity(0.8),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        ),
        cardTheme: CardThemeData(
          elevation: 2, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6)
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white, 
          selectedItemColor: Colors.teal[700],
          unselectedItemColor: Colors.grey[500], 
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11.5),
          showSelectedLabels: true, 
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 10.0, 
          selectedIconTheme: IconThemeData(size: 26, color: Colors.teal[700]), 
          unselectedIconTheme: IconThemeData(size: 22, color: Colors.grey[500]),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.orange[600], 
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        textTheme: TextTheme(
            headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.teal[900]),
            titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.black87),
            titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.black54),
            bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
            bodyMedium: TextStyle(fontSize: 14.0, color: Colors.grey[800]),
            labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white) 
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('en', 'US'),
        Locale('es', ''),
      ],
      locale: const Locale('es', 'CO'),
    ),
  );
}