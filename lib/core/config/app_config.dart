
import 'package:appwrite/appwrite.dart';
import 'package:distincia_carros/core/constants/appwrite_constants.dart';
import 'package:get/get.dart';


class AppConfig {
  static final Client _client = Client()
      .setEndpoint(AppwriteConstants.endpoint)
      .setProject(AppwriteConstants.projectId);

  static Client get client => _client;
  static Account get account => Account(_client);
  static Databases get databases =>
      Databases(_client); // No pasar databaseId aquí
  // Puedes agregar inicializaciones para otros servicios
}