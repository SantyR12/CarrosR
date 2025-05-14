import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController authController = Get.find();
  int _selectedIndex = 0; // Para manejar la selección de la BottomNavigationBar

  // Lista de widgets para la BottomNavigationBar (puedes expandir esto)
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Index 0: Home', // Placeholder para la vista de Home
    ),
    Text(
      'Index 1: Add', // Placeholder para la vista de "Add"
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Aquí puedes añadir lógica para navegar a diferentes secciones o cambiar el contenido
      // basado en el ítem seleccionado. Por ahora, solo actualiza el índice.
    });
  }

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo para el GridView. Reemplaza esto con tus datos reales.
    final List<Widget> gridItems = [
      // Primer elemento: Imagen del carro
      Card(
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network( // Puedes cambiar esto por Image.asset si la tienes localmente
            'https://www.manualdecodificacion.cl/wp-content/uploads/2021/05/renault-sandero-ii-2012-2017-hatchback-5-puertas-2.jpg', // URL de ejemplo
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(child: Icon(Icons.car_repair, size: 50, color: Colors.grey)); // Placeholder en caso de error
            },
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      ),
      // Elementos placeholder grises
      _buildPlaceholderCard(),
      _buildPlaceholderCard(),
      _buildPlaceholderCard(),
      _buildPlaceholderCard(),
      _buildPlaceholderCard(),
      _buildPlaceholderCard(),
      _buildPlaceholderCard(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'), // Título como en la imagen
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authController.logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0), // Espaciado alrededor del GridView
        child: GridView.count(
          crossAxisCount: 2, // Dos columnas como en la imagen
          crossAxisSpacing: 8.0, // Espacio horizontal entre tarjetas
          mainAxisSpacing: 8.0,  // Espacio vertical entre tarjetas
          children: gridItems,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, // Color del ítem seleccionado
        unselectedItemColor: Colors.grey, // Color de los ítems no seleccionados
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Para que se vean todas las etiquetas
      ),
    );
  }

  // Widget auxiliar para crear las tarjetas placeholder
  Widget _buildPlaceholderCard() {
    return Card(
      elevation: 2.0,
      color: Colors.grey[300], // Color gris para el placeholder
      child: Center(
        child: Icon(
          Icons.image, // Icono de imagen como placeholder
          color: Colors.grey[600],
          size: 40.0,
        ),
      ),
    );
  }
}