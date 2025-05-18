// lib/data/repositories/profile_repository.dart
import 'dart:io';
import 'dart:typed_data'; // Necesario para el tipo de getFileView si lo usaras, pero no para la URL
import 'package:appwrite/appwrite.dart';
import 'package:distincia_carros/core/constants/appwrite_constants.dart';
import 'package:distincia_carros/data/models/user_profile_model.dart';
import 'package:distincia_carros/core/config/app_config.dart';

class ProfileRepository {
  final Databases _databases;
  final Storage _storage;

  ProfileRepository()
      : _databases = AppConfig.databases,
        _storage = Storage(AppConfig.client);

  Future<UserProfile?> getUserProfile(String userId) async {
    // ... (sin cambios)
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userCollectionId,
        queries: [Query.equal('userId', userId), Query.limit(1)],
      );
      if (response.documents.isNotEmpty) {
        return UserProfile.fromMap(response.documents.first.data);
      }
      return null;
    } on AppwriteException catch (e) {
      print('AppwriteException en getUserProfile: ${e.message}');
      throw Exception('Error al obtener perfil: ${e.message ?? "Error desconocido"}');
    } catch (e) {
      print('Error inesperado en getUserProfile: $e');
      throw Exception('Error inesperado al obtener perfil.');
    }
  }

  Future<UserProfile> createUserProfile(UserProfile profile) async {
    // ... (sin cambios)
    try {
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userCollectionId,
        documentId: ID.unique(), // Appwrite generará un ID único
        data: profile.toMap(),
        permissions: [ // Permisos a nivel de documento
          Permission.read(Role.user(profile.userId)),
          Permission.update(Role.user(profile.userId)),
          Permission.delete(Role.user(profile.userId)),
        ],
      );
      return UserProfile.fromMap(document.data);
    } on AppwriteException catch (e) {
      print('AppwriteException en createUserProfile: ${e.message}');
      throw Exception('Error al crear perfil: ${e.message ?? "Error desconocido"}');
    } catch (e) {
      print('Error inesperado en createUserProfile: $e');
      throw Exception('Error inesperado al crear perfil.');
    }
  }

  // Este método ahora devolverá la URL construida y el ID del archivo.
  Future<Map<String, String>> uploadProfileImage(String userId, File imageFile) async {
    try {
      final uploadedFile = await _storage.createFile(
        bucketId: AppwriteConstants.profileImagesBucketId,
        fileId: ID.unique(), // Appwrite genera un ID único para el archivo
        file: InputFile.fromPath(
          path: imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        permissions: [
          Permission.read(Role.any()), // Para que la URL de visualización sea públicamente accesible
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );

      // Construir la URL de visualización manualmente
      final String imageUrl =
          "${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.profileImagesBucketId}/files/${uploadedFile.$id}/view?project=${AppwriteConstants.projectId}&mode=admin"; // Añade &mode=admin si la clave de API del lado del servidor tiene acceso, o asegúrate que Role.any() tenga READ en el archivo. Para URLs públicas sin autenticación, la estructura es suficiente si el permiso del archivo es Role.any() con READ.
                                                                                                                                // Si la clave API usada en AppConfig.client tiene privilegios de lectura global o es una clave de API de proyecto, esta URL funciona.
                                                                                                                                // Para URLs que no requieren una sesión de usuario o clave API en el cliente, el permiso del archivo a `Role.any()` para `read` es clave.

      return {'url': imageUrl, 'fileId': uploadedFile.$id};
    } on AppwriteException catch (e) {
      print('Error subiendo imagen de perfil: ${e.message}');
      throw Exception('Error al subir imagen: ${e.message ?? "Error desconocido"}');
    } catch (e) {
      print('Error inesperado subiendo imagen de perfil: $e');
      throw Exception('Error inesperado al subir imagen.');
    }
  }

  Future<UserProfile> updateUserProfile(UserProfile profile, {File? newImageFile}) async {
    try {
      Map<String, dynamic> dataToUpdate = profile.toMap(); // Obtener los datos actuales

      // Si se proporciona un nuevo archivo de imagen
      if (newImageFile != null) {
        // 1. Eliminar la imagen anterior de Appwrite Storage si existe un fileId
        if (profile.profileImageFileId != null && profile.profileImageFileId!.isNotEmpty) {
          try {
            await _storage.deleteFile(
              bucketId: AppwriteConstants.profileImagesBucketId,
              fileId: profile.profileImageFileId!,
            );
            print("Imagen de perfil anterior eliminada: ${profile.profileImageFileId}");
          } catch (e) {
            // No detener la actualización si la eliminación falla (podría no existir o haber un error)
            print("Advertencia: No se pudo eliminar la imagen de perfil anterior (${profile.profileImageFileId}): $e");
          }
        }
        
        // 2. Subir la nueva imagen y obtener su URL y fileId
        final uploadResult = await uploadProfileImage(profile.userId, newImageFile);
        dataToUpdate['profileImageUrl'] = uploadResult['url'];
        dataToUpdate['profileImageFileId'] = uploadResult['fileId'];
      } else if (profile.profileImageUrl == null && profile.profileImageFileId == null) {
        // Si newImageFile es null Y la URL/FileID en el perfil también son null (o se quieren borrar)
        // Asegúrate que los campos en dataToUpdate estén explícitamente nulos o ausentes
        // para que se borren en la base de datos si así lo deseas.
        // Si solo se actualizan otros campos y no la imagen, profile.toMap() ya manejará esto.
        // Si el objetivo es eliminar la imagen existente sin subir una nueva:
        if (profile.profileImageFileId != null && profile.profileImageFileId!.isNotEmpty) {
             try {
                await _storage.deleteFile(
                    bucketId: AppwriteConstants.profileImagesBucketId,
                    fileId: profile.profileImageFileId!,
                );
                print("Imagen de perfil eliminada (sin reemplazo): ${profile.profileImageFileId}");
                dataToUpdate['profileImageUrl'] = null;
                dataToUpdate['profileImageFileId'] = null;
            } catch (e) {
                print("Advertencia: No se pudo eliminar la imagen de perfil (${profile.profileImageFileId}) al intentar borrarla: $e");
            }
        } else {
            // Si no hay newImageFile y no hay fileId previo, simplemente no actualizamos los campos de imagen.
            // O si el objetivo es borrar explícitamente la URL si no hay fileId:
            dataToUpdate['profileImageUrl'] = null;
            dataToUpdate['profileImageFileId'] = null;
        }
      }


      // 3. Actualizar el documento del perfil en la base de datos
      final document = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userCollectionId,
        documentId: profile.id, // El $id del documento de perfil existente
        data: dataToUpdate,
      );
      return UserProfile.fromMap(document.data);
    } on AppwriteException catch (e) {
       print('AppwriteException en updateUserProfile: ${e.message}');
      throw Exception('Error al actualizar perfil: ${e.message ?? "Error desconocido"}');
    } catch (e) {
      print('Error inesperado en updateUserProfile: $e');
      throw Exception('Error inesperado al actualizar perfil.');
    }
  }
}