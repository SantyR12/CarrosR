import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/controller/home_page_controller.dart';
import 'package:distincia_carros/data/repositories/auth_repository.dart';
import 'package:distincia_carros/presentation/pages/home_page.dart';
import 'package:distincia_carros/presentation/pages/login_page.dart';
import 'package:distincia_carros/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:distincia_carros/core/config/app_config.dart';
import 'package:distincia_carros/controller/profile_controller.dart';
import 'package:distincia_carros/controller/trip_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try{
    await dotenv.load(fileName: ".env");
    print(".env file loaded successfully");
  } catch (e) {
    print("Error loading .env file: $e");
  }

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal.shade800, 
          brightness: Brightness.light, 
          primary: Colors.teal.shade800,
          secondary: Colors.amber.shade700, 
          surface: Colors.grey[100],      
          background: Colors.blueGrey[50], 
          error: Colors.red.shade700,      
          onPrimary: Colors.white,         
          onSecondary: Colors.black,     
          onSurface: Colors.black87,      
          onBackground: Colors.black87,    
          onError: Colors.white,          
        ),
        scaffoldBackgroundColor: Colors.blueGrey[50], 
        fontFamily: 'Nunito',

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal[900], 
          foregroundColor: Colors.white,    
          elevation: 1, 
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontFamily: 'Nunito', 
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[700], 
            foregroundColor: Colors.white,   
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Nunito', letterSpacing: 0.5), // Texto un poco más bold
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.9), 
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0), 
            borderSide: BorderSide.none, 
          ),
          enabledBorder: OutlineInputBorder( 
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.w500, fontFamily: 'Nunito'),
          hintStyle: TextStyle(color: Colors.grey[500], fontFamily: 'Nunito'),
          prefixIconColor: Colors.teal[700]?.withOpacity(0.7),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          floatingLabelBehavior: FloatingLabelBehavior.auto, 
        ),
        cardTheme: CardThemeData(
          elevation: 3, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          clipBehavior: Clip.antiAlias, 
          color: Colors.white, 
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[850], 
          selectedItemColor: Colors.teal[300],   
          unselectedItemColor: Colors.grey[500], 
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Nunito'),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontFamily: 'Nunito'),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0, 
          selectedIconTheme: IconThemeData(size: 26, color: Colors.teal[300]),
          unselectedIconTheme: IconThemeData(size: 22, color: Colors.grey[500]),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber[700], 
          foregroundColor: Colors.black, 
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontFamily: 'Nunito', fontSize: 26.0, fontWeight: FontWeight.bold, color: Colors.teal[900]),
          titleLarge: TextStyle(fontFamily: 'Nunito', fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.85)),
          titleMedium: TextStyle(fontFamily: 'Nunito', fontSize: 17.0, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.75)),
          bodyLarge: TextStyle(fontFamily: 'Nunito', fontSize: 16.0, color: Colors.black.withOpacity(0.8)),
          bodyMedium: TextStyle(fontFamily: 'Nunito', fontSize: 14.0, color: Colors.grey[800]),
          labelLarge: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white) 
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