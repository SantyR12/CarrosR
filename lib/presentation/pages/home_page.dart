// lib/presentation/pages/home_page.dart
// lib/presentation/pages/home_page.dart
import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/controller/home_page_controller.dart'; // Importar
import 'package:distincia_carros/controller/trip_controller.dart';
import 'package:distincia_carros/presentation/pages/create_trip_form_page.dart';
import 'package:distincia_carros/presentation/pages/profile_page.dart';
import 'package:distincia_carros/presentation/pages/trip_details_page.dart';
// Importa tu pantalla de lista de recorridos (TripsListScreen)
import 'package:distincia_carros/presentation/widgets/trip_list_item.dart'; // O donde esté TripsListScreen
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget { // Puede seguir siendo StatelessWidget
  final AuthController authController = Get.find<AuthController>();
  final HomePageController homePageCtrl = Get.find<HomePageController>(); // Encontrar el controlador inyectado

  HomePage({super.key});

  // Definir las páginas/widgets para cada pestaña
  final List<Widget> _widgetOptions = <Widget>[
    TripsListScreen(),       // Pestaña 0: Lista de recorridos
    CreateTripFormPage(),  // Pestaña 1: Formulario para crear recorrido
    ProfilePage(),         // Pestaña 2: Perfil de usuario
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() { // Título reactivo basado en la pestaña
          int currentIndex = homePageCtrl.tabIndex.value;
          if (currentIndex == 0) return const Text('Mis Recorridos');
          if (currentIndex == 1) return const Text('Crear Nuevo Recorrido');
          if (currentIndex == 2) return const Text('Mi Perfil');
          return const Text('App Recorridos');
        }),
        actions: [
          Obx(() => homePageCtrl.tabIndex.value == 2
              ? IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar Sesión',
                  onPressed: () {
                    authController.logout();
                  },
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() => _widgetOptions.elementAt(homePageCtrl.tabIndex.value)), // Cuerpo reactivo
      bottomNavigationBar: Obx( // BottomNavigationBar reactiva
        () => BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Recorridos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_location_alt_outlined),
              activeIcon: Icon(Icons.add_location_alt),
              label: 'Crear',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
          currentIndex: homePageCtrl.tabIndex.value, // Índice reactivo
          selectedItemColor: Theme.of(context).primaryColorDark,
          unselectedItemColor: Colors.grey[600],
          onTap: homePageCtrl.changeTabIndex, // Método del controlador para cambiar pestaña
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

// Widget interno o en un archivo separado para la lista de recorridos
class TripsListScreen extends StatelessWidget {
  final TripController tripController = Get.find<TripController>();

  TripsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (tripController.isLoading.value && tripController.userTrips.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (tripController.errorMessage.value.isNotEmpty && tripController.userTrips.isEmpty) {
        return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 60),
                  SizedBox(height:10),
                  Text("Error", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height:5),
                  Text(tripController.errorMessage.value, textAlign: TextAlign.center),
                  SizedBox(height:20),
                  ElevatedButton(onPressed: ()=> tripController.fetchUserTrips(), child: Text("Reintentar"))
                ],
              ),
            ));
      }
      if (tripController.userTrips.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No has creado ningún recorrido aún.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Presiona la pestaña "+" para registrar tu primer recorrido.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => tripController.fetchUserTrips(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), // Padding inferior para no tapar con BottomNav
          itemCount: tripController.userTrips.length,
          itemBuilder: (context, index) {
            final trip = tripController.userTrips[index];
            return TripListItem(
              trip: trip,
              onTap: () {
                Get.to(() => TripDetailsPage(trip: trip));
              },
              onDelete: () { // La confirmación ya está en el controlador
                tripController.deleteTrip(trip.id);
              },
            );
          },
        ),
      );
    });
  }
}