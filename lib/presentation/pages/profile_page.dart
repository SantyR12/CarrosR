// lib/presentation/pages/profile_page.dart
import 'package:distincia_carros/controller/auth_controller.dart'; // Necesario para logout
import 'package:distincia_carros/controller/profile_controller.dart';
import 'package:distincia_carros/presentation/pages/edit_profil_page.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // Para ImageSource

class ProfilePage extends StatelessWidget {
  // AuthController se usa para el logout, que ahora está en el AppBar de HomePage
  // final AuthController authController = Get.find<AuthController>();
  final ProfileController profileController = Get.find<ProfileController>();

  ProfilePage({super.key});

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Seleccionar de la Galería'),
                onTap: () {
                  profileController.pickImage(ImageSource.gallery);
                  Get.back(); // Cerrar el bottom sheet
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una Foto'),
                onTap: () {
                  profileController.pickImage(ImageSource.camera);
                  Get.back(); // Cerrar el bottom sheet
                },
              ),
              if (profileController.pickedImageFile.value != null || 
                  (profileController.userProfile.value?.profileImageUrl != null &&
                   profileController.userProfile.value!.profileImageUrl!.isNotEmpty)
              ) ...[
                const Divider(),
                 ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                  title: Text('Eliminar Imagen Actual', style: TextStyle(color: Colors.red[700])),
                  onTap: () {
                    // Lógica para eliminar: limpiar pickedImage y poner URL/FileId a null en el perfil
                    profileController.pickedImageFile.value = null; 
                    // Para que se elimine del backend, se debe guardar el perfil con URL y FileId nulos
                    // Esto se haría en la página de Editar Perfil al guardar.
                    // Aquí solo limpiamos la previsualización.
                    // Si quieres que se refleje inmediatamente en DB, necesitarías una función `removeProfileImage`
                    Get.back();
                    Get.snackbar("Imagen Eliminada", "La imagen se quitará al guardar los cambios en 'Editar Perfil'.");
                  },
                ),
              ]
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // El ProfileController debería llamar a fetchUserProfile en su onInit
    // o cuando cambie el estado de autenticación.
    return Scaffold(
      // El AppBar es manejado por HomePage si esta es una de sus pestañas.
      body: Obx(() {
        if (profileController.isLoading.value && profileController.userProfile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final authUser = Get.find<AuthController>().appwriteUser.value;
        if (profileController.userProfile.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    authUser != null ? 'Aún no has configurado tu perfil.' : 'No se pudo cargar el perfil.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  if (authUser != null)
                    ElevatedButton.icon(
                      icon: Icon(Icons.add_circle_outline),
                      label: const Text("Crear Mi Perfil"),
                      onPressed: () {
                        // Crear perfil inicial y luego ir a editarlo
                        profileController.createInitialProfile(authUser.name, authUser.email)
                          .then((_) {
                              if(profileController.userProfile.value != null) {
                                Get.to(() => EditProfilePage(currentProfile: profileController.userProfile.value!));
                              }
                          });
                      },
                    ),
                  if (profileController.errorMessage.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(profileController.errorMessage.value, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
          );
        }

        final profile = profileController.userProfile.value!;
        return RefreshIndicator(
          onRefresh: () => profileController.fetchUserProfile(),
          child: ListView( // Usar ListView para permitir scroll si el contenido es largo
            padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 20.0),
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: () => _showImagePickerOptions(context),
                  child: Obx(() { // Obx para la imagen que puede cambiar
                    Widget avatarContent;
                    if (profileController.pickedImageFile.value != null) {
                      avatarContent = CircleAvatar(
                        radius: 70,
                        backgroundImage: FileImage(profileController.pickedImageFile.value!),
                      );
                    } else if (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty) {
                      avatarContent = CircleAvatar(
                        radius: 70,
                        backgroundImage: NetworkImage(profile.profileImageUrl!),
                        onBackgroundImageError: (exception, stackTrace) {
                          // Placeholder si hay error cargando la imagen de red
                          print("Error cargando NetworkImage: $exception");
                          // setState(() { _imageError = true; }); // si es StatefulWidget
                        },
                        child: (profile.profileImageUrl == null || profile.profileImageUrl!.isEmpty) // Condición redundante si NetworkImage falla
                            ? Icon(Icons.person, size: 70, color: Colors.grey[400]) // Placeholder
                            : null,
                      );
                    } else {
                      avatarContent = CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[200],
                        child: Icon(Icons.person_add_alt_1_outlined, size: 60, color: Colors.grey[500]),
                      );
                    }
                    return Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        avatarContent,
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text("Toca la imagen para cambiarla", style: TextStyle(color: Colors.grey[600], fontSize: 12))),
              const SizedBox(height: 30),
              _buildProfileInfoCard(context, Icons.badge_outlined, "Nombre Completo", profile.name),
              _buildProfileInfoCard(context, Icons.alternate_email_outlined, "Correo Electrónico", profile.email),
              _buildProfileInfoCard(context, Icons.phone_iphone_outlined, "Número de Teléfono", profile.phone ?? 'No especificado'),
              const SizedBox(height: 35),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Editar Información del Perfil'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () {
                  // Asegurarse de pasar el perfil actual (con la imagen remota si no hay pickedFile)
                  // pickedImageFile se maneja dentro del ProfileController
                  Get.to(() => EditProfilePage(currentProfile: profileController.userProfile.value!));
                },
              ),
              // El botón de Logout ahora está en el AppBar de HomePage.
              // Si también lo quieres aquí:
              // const SizedBox(height: 15),
              // OutlinedButton.icon(
              //   icon: const Icon(Icons.logout, color: Colors.redAccent),
              //   label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              //   style: OutlinedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(vertical: 14),
              //     side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
              //     textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              //   ),
              //   onPressed: () {
              //     Get.find<AuthController>().logout();
              //   },
              // ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileInfoCard(BuildContext context, IconData icon, String label, String value) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!)
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    value.isNotEmpty ? value : "No disponible",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}