import 'dart:io';
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

    try {
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userCollectionId,
        documentId: ID.unique(), 
        data: profile.toMap(),
        permissions: [ 
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
  Future<Map<String, String>> uploadProfileImage(String userId, File imageFile) async {
    try {
      final uploadedFile = await _storage.createFile(
        bucketId: AppwriteConstants.profileImagesBucketId,
        fileId: ID.unique(), 
        file: InputFile.fromPath(
          path: imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        permissions: [
          Permission.read(Role.any()), 
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
      final String imageUrl =
          "${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.profileImagesBucketId}/files/${uploadedFile.$id}/view?project=${AppwriteConstants.projectId}&mode=admin"; 
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
      Map<String, dynamic> dataToUpdate = profile.toMap(); 

      if (newImageFile != null) {
        if (profile.profileImageFileId != null && profile.profileImageFileId!.isNotEmpty) {
          try {
            await _storage.deleteFile(
              bucketId: AppwriteConstants.profileImagesBucketId,
              fileId: profile.profileImageFileId!,
            );
            print("Imagen de perfil anterior eliminada: ${profile.profileImageFileId}");
          } catch (e) {
            print("Advertencia: No se pudo eliminar la imagen de perfil anterior (${profile.profileImageFileId}): $e");
          }
        }
        final uploadResult = await uploadProfileImage(profile.userId, newImageFile);
        dataToUpdate['profileImageUrl'] = uploadResult['url'];
        dataToUpdate['profileImageFileId'] = uploadResult['fileId'];
      } else if (profile.profileImageUrl == null && profile.profileImageFileId == null) {

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

            dataToUpdate['profileImageUrl'] = null;
            dataToUpdate['profileImageFileId'] = null;
        }
      }
      final document = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userCollectionId,
        documentId: profile.id, 
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