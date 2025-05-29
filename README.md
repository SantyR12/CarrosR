# Recorridos App: Gestión Inteligente de Trayectos Vehiculares 🚗💨

Una aplicación móvil desarrollada en Flutter para registrar, visualizar y gestionar tus recorridos vehiculares de forma eficiente.

## 📝 Descripción General

Recorridos App permite a los usuarios llevar un control preciso de los trayectos realizados con sus vehículos. Facilita la documentación de detalles clave de cada viaje, el trazado de rutas en un mapa interactivo con cálculo automático de distancia, y el mantenimiento de un historial organizado.

## ✨ Funcionalidades Principales

* **Autenticación de Usuarios:** Registro e inicio de sesión seguros.
* **Gestión de Perfil:** Visualización y edición de la información del usuario, incluyendo foto de perfil.
* **Registro de Recorridos:**
    * Ingreso de detalles del vehículo (marca, modelo, año).
    * Opción para seleccionar una imagen predeterminada del vehículo o subir una foto personalizada.
    * Descripción del título y motivo del recorrido.
* **Definición de Ruta en Mapa Interactivo:**
    * Selección de puntos de inicio y fin en el mapa.
    * Cálculo automático de la ruta por carretera y la distancia (usando OpenRouteService).
    * Visualización de la polilínea de la ruta.
* **Historial de Recorridos:**
    * Listado de todos los recorridos guardados por el usuario.
    * Visualización de la imagen del vehículo, título, detalles y distancia.
    * Opción para ver los detalles completos de un recorrido.
    * Eliminación de recorridos.
* **Detalles del Recorrido:**
    * Visualización completa de la información del recorrido, incluyendo el mapa de la ruta trazada.
      
## 🧱 Arquitectura de Widgets

### Widget Personalizado Reutilizable

* **TripListItem** : Un widget basado en tarjeta que muestra información de viaje individual, incluyendo imagen del vehículo, título del viaje, detalles del vehículo (marca/modelo/año), distancia y fecha de creación. Maneja la carga de imágenes con retrocesos y proporciona funcionalidad eliminación o delete.

---
### Widgets de Nivel de Página

* **Página de Inicio** : El widget contenedor principal con navegación inferior que cambia entre tres pestañas: lista de viajes, creación de viajes y perfil.
* **TripsListScreen** : Muestra la colección de viajes del usuario con estados de carga, manejo de errores, estados vacíos y funcionalidad "pull-to-refresh". Utiliza widgets `TripListItem` en una lista desplazable.
* **CrearTripFormPage** : Un widget de formulario para recopilar información sobre viajes y vehículos, incluida la selección de imágenes, el título del viaje, la marca/modelo/año del vehículo y la descripción antes de proceder a la definición de la ruta.
* **TripDetallesPágina** : Muestra detalles completos del viaje con un mapa interactivo que muestra polilíneas de ruta, marcadores de inicio/fin, puntos de referencia, información del vehículo y metadatos de viaje.
* **MapRoutePágina** : Un widget de mapa interactivo para definir rutas de viaje estableciendo puntos de inicio/finalización, calculando distancias usando la API OpenRouteService y visualizando la ruta antes de guardarla.
* **IniciarSesiónPágina** : Widget de formulario de autenticación con validación de correo electrónico/contraseña y gestión de estado reactiva para el inicio de sesión del usuario.
* **RegistrarsePágina** : Widget de formulario de registro de usuario que recopila nombre, correo electrónico y contraseña con validación antes de la creación de la cuenta.
* **EditarProfilePage** : Widget de formulario de edición de perfiles que permite a los usuarios actualizar su nombre, correo electrónico e información telefónica.
* **PerfilPage**: Un widget para mostrar información de perfil de usuario .

## 🛠️ Tecnologías Utilizadas

* **Flutter (SDK v3.29.3):** Framework principal para el desarrollo de la UI y la lógica de la aplicación.
* **Dart (SDK v3.7.2):** Lenguaje de programación.
* **Appwrite (BaaS - v16.0.0 SDK):**
    * **Autenticación:** Para el manejo de usuarios.
    * **Base de Datos:** Para almacenar perfiles y datos de recorridos.
    * **Almacenamiento:** Para imágenes de perfil y vehículos.
* **GetX (v4.7.2):** Para gestión de estado, inyección de dependencias y navegación.
* **Mapas y Geolocalización:**
    * **`flutter_map` (v8.1.1):** Para mostrar mapas interactivos.
    * **MapTiler:** Proveedor de teselas de mapa (map tiles).
    * **OpenRouteService (ORS):** API para cálculo de rutas y obtención de polilíneas.
    * **`geolocator` (v14.0.0):** Para obtener la ubicación actual del dispositivo y calcular distancias.
    * **`latlong2` (v0.9.1):** Para manejo de coordenadas geográficas con `flutter_map`.
* **Otras Dependencias Clave:**
    * **`http` (v1.4.0):** Para realizar llamadas a la API de ORS.
    * **`image_picker` (v1.1.0):** Para seleccionar imágenes de la galería o cámara.
    * **`intl` (v0.19.0):** Para formateo de fechas.
    * **`flutter_dotenv` (v5.1.0):** Para gestionar variables de entorno y credenciales.

## 🚀 Configuración y Ejecución del Proyecto

Sigue estos pasos para configurar y ejecutar la aplicación en tu entorno local.

### Prerrequisitos

* Flutter SDK (versión 3.29.3 o compatible).
* Un editor de código (VS Code o Android Studio).
* Para Android: Android Studio con un AVD configurado o un dispositivo físico con depuración USB habilitada.
* Git.

### Pasos de Instalación

1.  **Clona el repositorio:**
    ```bash
    git clone [https://github.com/SantyR12/CarrosR.git](https://github.com/SantyR12/CarrosR.git)
    cd CarrosR
    ```



2.  **Obtén las Dependencias de Flutter:**
     * Pide actualizar la dependencia de intl en la terminal dependiento de tu sdk en mi caso pedia la ^0.19.0
    ```bash
    flutter pub add intl:^0.19.0
    ```
    ```bash
    flutter pub get
    ```

3.  **Ejecuta la Aplicación:**
    * Asegúrate de tener un emulador en ejecución o un dispositivo conectado.
    * Puedes verificar los dispositivos disponibles con: `flutter devices`
    * Ejecuta la aplicación:
        ```bash
        flutter run
        ```

### Configuración del Backend (Appwrite)

Esta aplicación requiere una instancia de Appwrite configurada con lo siguiente:

* **Autenticación:** Habilitada.
* **Base de Datos (con el ID especificado en `.env`):**
    * **Colección de Perfiles** (ID en `.env`):
        * `userId` (String, Requerido, Indexado)
        * `name` (String, Requerido)
        * `email` (String, Requerido)
        * `phone` (String, Opcional)
        * `profileImageUrl` (String, Opcional)
        * `profileImageFileId` (String, Opcional)
        * *Permisos de Documento:* `Role.user(userId)` para leer, actualizar y eliminar.
    * **Colección de Recorridos** (ID en `.env`):
        * `userId` (String, Requerido, Indexado)
        * `vehicleBrand` (String, Requerido)
        * `vehicleModel` (String, Requerido)
        * `vehicleYear` (Integer, Requerido)
        * `tripTitle` (String, Requerido)
        * `tripDescription` (String, Requerido)
        * `vehicleImageUrl` (String, Opcional) - Puede ser una URL de Appwrite Storage o una ruta de asset local.
        * `vehicleImageFileId` (String, Opcional) - Solo para imágenes subidas a Appwrite.
        * `startLatitude` (Double, Requerido)
        * `startLongitude` (Double, Requerido)
        * `endLatitude` (Double, Requerido)
        * `endLongitude` (Double, Requerido)
        * `waypoints` (String, Opcional) - Almacenado como JSON String.
        * `polylinePointsForDB` (String, Opcional, Tamaño Grande) - Almacenado como JSON String para la ruta detallada.
        * `distanceKm` (Double, Requerido)
        * *Permisos de Documento:* `Role.user(userId)` para leer, actualizar y eliminar.
* **Almacenamiento (Storage):**
    * **Bucket de Imágenes** (ID en `.env`, ej. `profile_images_bucket`):
        * Usado para imágenes de perfil y vehículos.
        * *Permisos de Archivo:* `Permission.read(Role.any())` para permitir visualización pública, `Permission.create/update/delete(Role.user(USER_ID))` para el propietario.


## 🤓 Autor

* **Santiago [Tu Apellido]**
    * [Tu Perfil de GitHub (Opcional)](https://github.com/SantyR12)

