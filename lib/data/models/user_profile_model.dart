class UserProfile {
  final String id; 
  final String userId; 
  String name;
  String email;
  String? phone;
  String? profileImageUrl;
  String? profileImageFileId; 

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