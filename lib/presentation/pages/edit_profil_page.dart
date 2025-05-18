// lib/presentation/pages/edit_profile_page.dart
import 'dart:io'; // Para File
import 'package:distincia_carros/controller/profile_controller.dart';
import 'package:distincia_carros/data/models/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // Para ImageSource

class EditProfilePage extends StatefulWidget {
  final UserProfile currentProfile; // Pasamos el perfil actual

  const EditProfilePage({super.key, required this.currentProfile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ProfileController profileController = Get.find<ProfileController>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController; // Email no es editable usualmente
  late TextEditingController _phoneController;
  
  // No necesitamos un File local aquí si el `profileController.pickedImageFile` se usa para la previsualización.

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile.name);
    _emailController = TextEditingController(text: widget.currentProfile.email);
    _phoneController = TextEditingController(text: widget.currentProfile.phone ?? '');
    // Si ProfilePage ya actualizó pickedImageFile en el controller, se usará.
    // Si no, y el usuario selecciona una imagen aquí, se actualizará en el controller.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    // No limpiar profileController.pickedImageFile aquí,
    // podría ser necesario si el usuario navega atrás y vuelve.
    // Se limpia después de guardar exitosamente.
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Para onSaved si los usas
      FocusScope.of(context).unfocus(); // Ocultar teclado

      // Los datos y la imagen (si pickedImageFile tiene valor) se toman del controlador
      await profileController.updateUserProfileData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        // El ProfileController usará su `pickedImageFile.value` si existe.
      );

      // El controlador maneja los snackbars de éxito/error.
      // Si no hay error, significa que se guardó (o al menos se intentó sin excepción).
      if (profileController.errorMessage.value.isEmpty) {
        Get.back(); // Volver a la página de perfil
      }
    }
  }

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
                  Get.back();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una Foto'),
                onTap: () {
                  profileController.pickImage(ImageSource.camera);
                  Get.back();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Mi Perfil'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            // Si hay una imagen seleccionada pero no guardada, preguntar
            if (profileController.pickedImageFile.value != null) {
              Get.dialog(
                AlertDialog(
                  title: Text("Descartar Cambios"),
                  content: Text("Tienes una nueva imagen seleccionada que no se ha guardado. ¿Deseas descartarla?"),
                  actions: [
                    TextButton(onPressed: () => Get.back(), child: Text("Continuar Editando")),
                    TextButton(onPressed: (){
                       profileController.pickedImageFile.value = null; // Limpiar la selección
                       Get.back(); // Cerrar dialogo
                       Get.back(); // Volver a la página anterior
                    }, child: Text("Descartar y Salir", style: TextStyle(color: Colors.orange[800]))),
                  ],
                )
              );
            } else {
              Get.back();
            }
          }
        ),
        actions: [
          Obx(() => profileController.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.save_alt_outlined),
                  tooltip: "Guardar Cambios",
                  onPressed: _handleSaveProfile,
                ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 20.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text("Actualiza tu información personal", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 25),
              Center(
                child: GestureDetector(
                  onTap: () => _showImagePickerOptions(context),
                  child: Obx(() { // Reaccionar a cambios en pickedImageFile
                    ImageProvider<Object>? backgroundImage;
                    if (profileController.pickedImageFile.value != null) {
                      backgroundImage = FileImage(profileController.pickedImageFile.value!);
                    } else if (widget.currentProfile.profileImageUrl != null && widget.currentProfile.profileImageUrl!.isNotEmpty) {
                      backgroundImage = NetworkImage(widget.currentProfile.profileImageUrl!);
                    }

                    return CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: backgroundImage,
                      onBackgroundImageError: backgroundImage is NetworkImage ? (exception, stackTrace) {
                        print("Error cargando imagen de red en EditProfile: $exception");
                        // No hacer nada aquí, el child se mostrará si backgroundImage es null
                      } : null,
                      child: backgroundImage == null
                          ? Icon(Icons.person_add_alt_1_outlined, size: 70, color: Colors.grey[500])
                          : null, // No mostrar icono si hay imagen
                    );
                  }),
                ),
              ),
              TextButton.icon(
                icon: Icon(Icons.camera_alt_outlined, size: 18, color: Theme.of(context).primaryColor),
                label: Text("Cambiar Foto de Perfil", style: TextStyle(color: Theme.of(context).primaryColor)),
                onPressed: () => _showImagePickerOptions(context),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'El nombre no puede estar vacío';
                  if (value.trim().length < 3) return 'El nombre es muy corto';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico (No editable)',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                enabled: false, // El email generalmente no se cambia desde el perfil
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Número de Teléfono',
                  hintText: 'Opcional',
                  prefixIcon: const Icon(Icons.phone_iphone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.phone,
                // Puedes añadir validadores si es necesario, ej. para formato de teléfono
              ),
              const SizedBox(height: 40),
              Obx(() => ElevatedButton.icon(
                  icon: profileController.isLoading.value 
                      ? const SizedBox.shrink() // No mostrar icono si está cargando
                      : const Icon(Icons.check_circle_outline),
                  label: profileController.isLoading.value
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  onPressed: profileController.isLoading.value ? null : _handleSaveProfile,
                ),
              ),
              Obx(() {
                if (profileController.errorMessage.value.isNotEmpty && !profileController.isLoading.value) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(profileController.errorMessage.value, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}