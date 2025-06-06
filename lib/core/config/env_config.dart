import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {

  static String get appwriteEndpoint => dotenv.env['APPWRITE_ENDPOINT'] ?? '';
  static String get appwriteProjectId => dotenv.env['APPWRITE_PROJECT_ID'] ?? '';
  static String get appwriteDatabaseId => dotenv.env['APPWRITE_DATABASE_ID'] ?? '';
  static String get appwriteUserCollectionId => dotenv.env['APPWRITE_USER_COLLECTION_ID'] ?? '';
  static String get appwriteTripsCollectionId => dotenv.env['APPWRITE_TRIPS_COLLECTION_ID'] ?? '';
  static String get appwriteProfileImagesBucketId => dotenv.env['APPWRITE_PROFILE_IMAGES_BUCKET_ID'] ?? '';

  static String get mapTilerApiKey => dotenv.env['MAPTILER_API_KEY'] ?? '';
  static String get openRouteServiceApiKey => dotenv.env['OPENROUTESERVICE_API_KEY'] ?? '';


}