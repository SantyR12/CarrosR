// lib/data/models/user_profile_model.dart
import 'package:flutter/foundation.dart';

class UserProfile {
  final String id; // Appwrite document ID
  final String userId; // Appwrite Auth User ID
  String name;
  String email;
  String? phone;
  String? profileImageUrl;
  String? profileImageFileId; // Para gestionar el archivo en Appwrite Storage

  UserProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    this.profileImageFileId,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['\$id'],
      userId: map['userId'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      profileImageUrl: map['profileImageUrl'],
      profileImageFileId: map['profileImageFileId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'profileImageFileId': profileImageFileId,
    };
  }
}