import 'dart:io';
import 'package:distincia_carros/controller/profile_controller.dart';
import 'package:distincia_carros/data/models/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile currentProfile;
  const EditProfilePage({super.key, required this.currentProfile});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ProfileController profileController = Get.find<ProfileController>();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile.name);
    _emailController = TextEditingController(text: widget.currentProfile.email);
    _phoneController = TextEditingController(text: widget.currentProfile.phone ?? '');
  }
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  Future<void> _handleSaveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); 
      FocusScope.of(context).unfocus(); 
      await profileController.updateUserProfileData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );
      if (profileController.errorMessage.value.isEmpty && mounted) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) Get.back(); // Volver a la página de perfil
      }
    } else {
      Get.snackbar(
        "Campos Inválidos",
        "Por favor, corrige los errores en el formulario.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[800],
        colorText: Colors.white,
      );
    }
  }
  void _showImagePickerOptions(BuildContext context) {
    final ThemeData theme = Theme.of(context); 
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
                leading: Icon(Icons.photo_library_outlined, color: theme.primaryColorDark),
                title: const Text('Seleccionar de la Galería'),
                onTap: () {
                  profileController.pickImage(ImageSource.gallery);
                  Get.back();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: theme.primaryColorDark),
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
    final ThemeData theme = Theme.of(context);
    final Color textInputColorOnLightForm = theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.85);
    final Color labelInputColorOnLightForm = theme.brightness == Brightness.dark ? Colors.grey.shade400 : theme.primaryColorDark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            bool hasUnsavedChanges = profileController.pickedImageFile.value != null ||
                _nameController.text.trim() != widget.currentProfile.name ||
                _phoneController.text.trim() != (widget.currentProfile.phone ?? '');
            if (hasUnsavedChanges) {
              Get.dialog(
                AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  title: const Text("Descartar Cambios", style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text("Tienes cambios sin guardar. ¿Estás seguro de que quieres salir y descartarlos?"),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actions: [
                    TextButton(
                        onPressed: () => Get.back(),
                        child: Text("CONTINUAR EDITANDO", style: TextStyle(color: theme.primaryColorDark, fontWeight: FontWeight.bold))),
                    TextButton(
                        onPressed: () {
                          profileController.pickedImageFile.value = null; 
                          Get.back(); 
                          Get.back(); 
                        },
                        child: Text("DESCARTAR Y SALIR", style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            } else {
              Get.back();
            }
          },
        ),
        actions: [
          Obx(() => profileController.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), 
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
              : TextButton(
                  onPressed: _handleSaveProfile,
                  child: Text("GUARDAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/fondohomee.jpg"), 
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6), 
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Center( 
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                margin: const EdgeInsets.symmetric(horizontal: 16.0), 
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95), 
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled, 
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => _showImagePickerOptions(context),
                        child: Obx(() {
                          ImageProvider<Object>? imageProviderToShow;
                          if (profileController.pickedImageFile.value != null) {
                            imageProviderToShow = FileImage(profileController.pickedImageFile.value!);
                          } else if (widget.currentProfile.profileImageUrl != null && widget.currentProfile.profileImageUrl!.isNotEmpty) {
                            imageProviderToShow = NetworkImage(widget.currentProfile.profileImageUrl!);
                          }
                          return Container(
                            width: 150, height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                              border: Border.all(color: theme.primaryColor.withOpacity(0.7), width: 3),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0,4))
                              ],
                              image: imageProviderToShow != null
                                  ? DecorationImage(image: imageProviderToShow, fit: BoxFit.cover)
                                  : null,
                            ),
                            child: imageProviderToShow == null
                                ? Icon(Icons.person_add_alt_1_rounded, size: 70, color: Colors.grey[600])
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container( 
                                        width: 150, height: 150,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.camera_alt_outlined, color: Colors.white.withOpacity(0.9), size: 40),
                                      )
                                    ],
                                  ),
                          );
                        }),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.photo_camera_outlined, size: 20, color: theme.primaryColorDark),
                        label: Text("Cambiar Foto de Perfil", style: TextStyle(color: theme.primaryColorDark, fontWeight: FontWeight.w500)),
                        onPressed: () => _showImagePickerOptions(context),
                      ),
                      const SizedBox(height: 24), 
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: textInputColorOnLightForm, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Nombre Completo',
                          labelStyle: TextStyle(color: labelInputColorOnLightForm, fontWeight: FontWeight.w500),
                          prefixIcon: Icon(Icons.person_outline_rounded, color: labelInputColorOnLightForm),
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
                        style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 16), 
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[700]),
                          filled: true,
                          fillColor: Colors.grey[200],
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.grey[350]!),
                          ),
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        style: TextStyle(color: textInputColorOnLightForm, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Número de Teléfono',
                          labelStyle: TextStyle(color: labelInputColorOnLightForm, fontWeight: FontWeight.w500),
                          hintText: 'Opcional',
                          prefixIcon: Icon(Icons.phone_iphone_outlined, color: labelInputColorOnLightForm),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 32),
                      Obx(() => ElevatedButton.icon(
                            icon: profileController.isLoading.value
                                ? const SizedBox.shrink()
                                : const Icon(Icons.save_alt_outlined),
                            label: profileController.isLoading.value
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                                : const Text('Guardar Cambios'),
                            style: theme.elevatedButtonTheme.style?.copyWith(
                                minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
                            ),
                            onPressed: profileController.isLoading.value ? null : _handleSaveProfile,
                          ),
                      ),
                      Obx(() {
                        if (profileController.errorMessage.value.isNotEmpty && !profileController.isLoading.value) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: Text(profileController.errorMessage.value, style: TextStyle(color: theme.colorScheme.error, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}