import 'package:appwrite/appwrite.dart';
import 'package:distincia_carros/core/constants/appwrite_constants.dart';
import 'package:distincia_carros/data/models/trip_model.dart';
import 'package:distincia_carros/core/config/app_config.dart';
class TripRepository {
  final Databases _databases;

  TripRepository() : _databases = AppConfig.databases;

  Future<List<Trip>> getUserTrips(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tripsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt') 
        ],
      );
      return response.documents.map((doc) => Trip.fromMap(doc.data)).toList();
    } on AppwriteException catch (e) {
      print('AppwriteException en getUserTrips: ${e.message}');
      throw Exception('Error al obtener recorridos: ${e.message ?? "Error desconocido"}');
    } catch (e) {
      print('Error inesperado en getUserTrips: $e');
      throw Exception('Error inesperado al obtener recorridos.');
    }
  }

  Future<Trip> createTrip(Trip trip) async {
    try {
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tripsCollectionId,
        documentId: ID.unique(),
        data: trip.toMap(), 
        permissions: [
          Permission.read(Role.user(trip.userId)),
          Permission.update(Role.user(trip.userId)),
          Permission.delete(Role.user(trip.userId)),
        ],
      );
      return Trip.fromMap(document.data);
    } on AppwriteException catch (e) {
      print('AppwriteException en createTrip: ${e.message}');
      throw Exception('Error al crear recorrido: ${e.message ?? "Error desconocido"}');
    } catch (e) {
      print('Error inesperado en createTrip: $e');
      throw Exception('Error inesperado al crear recorrido.');
    }
  }

  Future<Trip> updateTrip(Trip trip) async {
    try {
      final document = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tripsCollectionId,
        documentId: trip.id,
        data: trip.toMap(), 
      );
      return Trip.fromMap(document.data);
    } on AppwriteException catch (e) {
      print('AppwriteException en updateTrip: ${e.message}');
      throw Exception('Error al actualizar recorrido: ${e.message ?? "Error desconocido"}');
    } catch (e) {
      print('Error inesperado en updateTrip: $e');
      throw Exception('Error inesperado al actualizar recorrido.');
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tripsCollectionId,
        documentId: tripId,
      );
    } on AppwriteException catch (e) {
      print('AppwriteException en deleteTrip: ${e.message}');
      throw Exception('Error al eliminar recorrido: ${e.message ?? "Error desconocido"}');
    } catch (e) {
      print('Error inesperado en deleteTrip: $e');
      throw Exception('Error inesperado al eliminar recorrido.');
    }
  }
}