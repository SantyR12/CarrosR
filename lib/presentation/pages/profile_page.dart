import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/controller/profile_controller.dart';
import 'package:distincia_carros/presentation/pages/edit_profil_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatelessWidget {
  final ProfileController profileController = Get.find<ProfileController>();
  final AuthController authController = Get.find<AuthController>();

  ProfilePage({super.key});

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: Theme.of(context).primaryColorDark),
                title: const Text('Seleccionar de la Galería'),
                onTap: () {
                  profileController.pickImage(ImageSource.gallery);
                  Get.back();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: Theme.of(context).primaryColorDark),
                title: const Text('Tomar una Foto'),
                onTap: () {
                  profileController.pickImage(ImageSource.camera);
                  Get.back();
                },
              ),
              if (profileController.pickedImageFile.value != null ||
                  (profileController.userProfile.value?.profileImageUrl != null &&
                   profileController.userProfile.value!.profileImageUrl!.isNotEmpty)) ...[
                const Divider(height: 1, indent: 16, endIndent: 16, thickness: 0.5),
                ListTile(
                  leading: Icon(Icons.delete_sweep_outlined, color: Colors.red[600]),
                  title: Text('Eliminar Imagen Seleccionada', style: TextStyle(color: Colors.red[700])),
                  onTap: () {
                    profileController.pickedImageFile.value = null;
                    Get.back();
                    Get.snackbar(
                      "Previsualización Limpia",
                      "La imagen se quitará definitivamente al guardar los cambios en 'Editar Perfil'.",
                       snackPosition: SnackPosition.BOTTOM,
                       backgroundColor: Colors.orange[700],
                       colorText: Colors.white
                    );
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
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body:Stack( 
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fondohomee.jpg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.45),
                  BlendMode.darken
                ),
              ),
            ),
          ), 
          Obx(() {
        if (profileController.isLoading.value && profileController.userProfile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final authUserFromController = authController.appwriteUser.value;
        if (profileController.userProfile.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.person_search_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    authUserFromController != null ? 'Aún no has configurado tu perfil.' : 'No se pudo cargar el perfil.',
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[800], fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    authUserFromController != null ? 'Crea uno para personalizar tu experiencia.' : 'Intenta de nuevo más tarde o contacta soporte.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (authUserFromController != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text("Configurar Mi Perfil"),
                      onPressed: () {
                        profileController.createInitialProfile(authUserFromController.name, authUserFromController.email)
                            .then((_) {
                          if (profileController.userProfile.value != null) {
                            Get.to(() => EditProfilePage(currentProfile: profileController.userProfile.value!));
                          }
                        });
                      },
                    ),
                  if (profileController.errorMessage.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        profileController.errorMessage.value,
                        style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        final profile = profileController.userProfile.value!;
        return RefreshIndicator(
          onRefresh: () => profileController.fetchUserProfile(),
          color: theme.primaryColor,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: () => _showImagePickerOptions(context),
                  child: Obx(() {
                    Widget avatarContent;
                    if (profileController.pickedImageFile.value != null) {
                      avatarContent = CircleAvatar(
                        radius: 75,
                        backgroundImage: FileImage(profileController.pickedImageFile.value!),
                      );
                    } else if (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty) {
                      avatarContent = CircleAvatar(
                        radius: 75,
                        backgroundImage: NetworkImage(profile.profileImageUrl!),
                        onBackgroundImageError: (exception, stackTrace) {
                          print("Error cargando NetworkImage en ProfilePage: $exception");
                        },
                        backgroundColor: Colors.grey[200],
                        child: (profile.profileImageUrl == null || profile.profileImageUrl!.isEmpty)
                            ? Icon(Icons.person, size: 70, color: Colors.grey[400])
                            : null,
                      );
                    } else {
                      avatarContent = CircleAvatar(
                        radius: 75,
                        backgroundColor: Colors.grey[200],
                        child: Icon(Icons.person_add_alt_1_rounded, size: 70, color: Colors.grey[500]),
                      );
                    }
                    return Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        avatarContent,
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(1,1))
                            ]
                          ),
                          child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  "Toca la imagen para cambiarla",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                )
              ),
              const SizedBox(height: 32),
              _buildProfileInfoCard(context, Icons.account_circle_outlined, "Nombre ", profile.name, theme: theme ),
              _buildProfileInfoCard(context, Icons.alternate_email_rounded, "Correo Electrónico", profile.email, theme: theme),
              _buildProfileInfoCard(context, Icons.phone_android_outlined, "Número de Teléfono", profile.phone ?? 'No especificado', theme: theme),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_note_outlined, size: 22),
                label: const Text('Editar Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                style: theme.elevatedButtonTheme.style?.copyWith(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                ),
                onPressed: () {
                  if (profileController.userProfile.value != null) {
                    Get.to(() => EditProfilePage(currentProfile: profileController.userProfile.value!));
                  } else {
                    Get.snackbar("Error", "No se pudo cargar el perfil para editar.");
                  }
                },
              ),
              const SizedBox(height: 16), 
              OutlinedButton.icon(
                icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                label: Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w500, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error.withOpacity(0.7), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      title: const Text("Confirmar Cierre de Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text("¿Estás seguro de que quieres cerrar sesión?"),
                      actionsAlignment: MainAxisAlignment.spaceBetween,
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(), 
                          child: Text("CANCELAR", style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.back(); 
                            authController.logout(); 
                          },
                          child: Text("CERRAR SESIÓN", style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(BuildContext context, IconData icon, String label, String value, {required ThemeData theme}) {
    // ... (esta función no cambia)
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor, size: 26),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : "No especificado",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.85)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}