import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/controller/home_page_controller.dart';
import 'package:distincia_carros/presentation/pages/create_trip_form_page.dart';
import 'package:distincia_carros/presentation/pages/profile_page.dart';
import 'package:distincia_carros/presentation/widgets/trip_list_item.dart'; 
import 'package:distincia_carros/controller/trip_controller.dart'; 
import 'package:distincia_carros/presentation/pages/trip_details_page.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final HomePageController homePageCtrl = Get.find<HomePageController>();

  HomePage({super.key});
  final List<Widget> _widgetOptions = <Widget>[
    TripsListScreen(key: const ValueKey('trips_screen')),
    CreateTripFormPage(key: const ValueKey('create_trip_screen')),
    ProfilePage(key: const ValueKey('profile_screen')),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
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
                  onPressed: (){
                    Get.dialog(
                      AlertDialog(
                        title: const Text('Confirmar Cierre de Sesión'),
                        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              authController.logout();
                              Get.offAllNamed('/login');
                            },
                            child: const Text('Cerrar Sesión'),
                          ),
                        ],
                    )
                    );
                  },
                )
              : const SizedBox.shrink()),
        ],
      ),
      body:
            Obx(() => AnimatedSwitcher( 
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _widgetOptions.elementAt(homePageCtrl.tabIndex.value),
          )),
      bottomNavigationBar: Obx(
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
          currentIndex: homePageCtrl.tabIndex.value,

          onTap: homePageCtrl.changeTabIndex,

        ),
      ),
    );
  }
}

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
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                  SizedBox(height:16),
                  Text("Error al Cargar", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.redAccent)),
                  SizedBox(height:8),
                  Text(tripController.errorMessage.value, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height:24),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    onPressed: ()=> tripController.fetchUserTrips(), 
                    label: Text("Reintentar")
                  )
                ],
              ),
            )
        );
      }
      if (tripController.userTrips.isEmpty) {
        return Center( 
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_off_outlined, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'Aún no tienes recorridos guardados.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Usa la pestaña (+) para añadir tu primer recorrido.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => tripController.fetchUserTrips(),
        color: Theme.of(context).primaryColor,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), 
          itemCount: tripController.userTrips.length,
          itemBuilder: (context, index) {
            final trip = tripController.userTrips[index];
            return TripListItem( 
              trip: trip,
              onTap: () {
                Get.to(() => TripDetailsPage(trip: trip));
              },
              onDelete: () {
                tripController.deleteTrip(trip.id);
              },
            );
          },
        ),
      );
    });
  }
}