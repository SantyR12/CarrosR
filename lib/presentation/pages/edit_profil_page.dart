
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
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) Get.back();
      }
    } else {
        Get.snackbar(
            "Campos Inválidos",
            "Por favor, corrige los errores en el formulario.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange[800],
            colorText: Colors.white);
    }
  }

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
                leading: Icon(Icons.photo_library_outlined, color: Theme.of(context).primaryColor),
                title: const Text('Seleccionar de la Galería'),
                onTap: () {
                  profileController.pickImage(ImageSource.gallery);
                  Get.back();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: Theme.of(context).primaryColor),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (profileController.pickedImageFile.value != null || 
                _nameController.text != widget.currentProfile.name ||
                _phoneController.text != (widget.currentProfile.phone ?? '')) {
              Get.dialog(
                AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  title: const Text("Descartar Cambios", style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text("Tienes cambios sin guardar. ¿Estás seguro de que quieres salir y descartarlos?"),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(), 
                      child: Text("Continuar Editando", style: TextStyle(color: theme.primaryColorDark))
                    ),
                    TextButton(
                      onPressed: (){
                        profileController.pickedImageFile.value = null; 
                        Get.back(); 
                        Get.back(); 
                      },
                      child: Text("Descartar y Salir", style: TextStyle(color: Colors.red[700]))
                    ),
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
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
              : TextButton( 
                  onPressed: _handleSaveProfile,
                  child: Text("GUARDAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: () => _showImagePickerOptions(context),
                  child: Obx(() {
                    ImageProvider<Object>? backgroundImage;
                    if (profileController.pickedImageFile.value != null) {
                      backgroundImage = FileImage(profileController.pickedImageFile.value!);
                    } else if (widget.currentProfile.profileImageUrl != null && widget.currentProfile.profileImageUrl!.isNotEmpty) {
                      backgroundImage = NetworkImage(widget.currentProfile.profileImageUrl!);
                    }

                    return Container(
                      width: 160, height: 160, 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        border: Border.all(color: theme.primaryColor.withOpacity(0.5), width: 3),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0,4))
                        ],
                        image: backgroundImage != null ? DecorationImage(image: backgroundImage, fit: BoxFit.cover) : null,
                      ),
                      child: backgroundImage == null
                          ? Icon(Icons.person_add_alt_1_outlined, size: 70, color: Colors.grey[500])
                          : Stack( 
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 160, height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.25), 
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.camera_alt_outlined, color: Colors.white.withOpacity(0.9), size: 40),
                                )
                              ],
                            ),
                    );
                  }),
                ),
              ),
              TextButton.icon(
                icon: Icon(Icons.photo_camera_outlined, size: 20, color: theme.primaryColorDark),
                label: Text("Cambiar Foto", style: TextStyle(color: theme.primaryColorDark, fontWeight: FontWeight.w500)),
                onPressed: () => _showImagePickerOptions(context),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
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
                  labelText: 'Correo Electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true, 
                  fillColor: Colors.grey[200], 
                  disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey[300]!)
                  )
                ),
                enabled: false,
                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Número de Teléfono',
                  hintText: 'Opcional',
                  prefixIcon: Icon(Icons.phone_iphone_outlined),
                ),
                keyboardType: TextInputType.phone,
                 inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
              ),
              const SizedBox(height: 40),
              Obx(() => ElevatedButton.icon(
                  icon: profileController.isLoading.value
                      ? const SizedBox.shrink()
                      : const Icon(Icons.save_outlined), 
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
    );
  }
}