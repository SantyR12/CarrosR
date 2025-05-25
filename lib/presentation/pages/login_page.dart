import 'package:distincia_carros/controller/auth_controller.dart';
import 'package:distincia_carros/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( 
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background_auth.jpg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4), 
                  BlendMode.darken
                ),
              ),
          
            ),
          ),


          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0), 
              child: Container( 
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9), 
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch, 
                    children: <Widget>[
                      Text(
                        "Bienvenido",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColorDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Inicia sesión para continuar",
                         textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Obx(
                        () => _authController.error.value.isNotEmpty
                            ? Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                  _authController.error.value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
                                ),
                            )
                            : SizedBox.shrink(),
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'El correo es requerido';
                          if (!GetUtils.isEmail(value.trim())) return 'Correo inválido';
                          return null;
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'La contraseña es requerida';
                          if (value.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      SizedBox(height: 28.0),
                      Obx(
                        () => ElevatedButton(
                          onPressed: _authController.isLoading.value
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    FocusScope.of(context).unfocus();
                                    _authController.login(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );
                                  }
                                },
                          child: _authController.isLoading.value
                              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                              : Text('Iniciar Sesión'),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      TextButton(
                        onPressed: () => Get.off(() => RegisterPage(), transition: Transition.rightToLeft),
                        child: Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(color: Theme.of(context).primaryColorDark)),
                      ),
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