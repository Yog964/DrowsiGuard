/// ============================================================
/// USER MODEL
/// ============================================================
/// This file defines the User data model.
/// It holds all user-related information used across the app.
///
/// Future Scope:
///   - Connect to MongoDB for persistent user storage
///   - Add authentication tokens
///   - Add profile image URL from cloud storage
/// ============================================================

class UserModel {
  // Unique identifier for the user (will map to MongoDB _id)
  final String id;

  // User's full name
  final String name;

  // User's email address (used for login)
  final String email;

  // User's phone number
  final String phone;

  // URL or path to user's profile image
  final String profileImageUrl;

  // User's vehicle number (relevant for driver context)
  final String vehicleNumber;

  // Emergency contact number
  final String emergencyContact;

  /// Constructor with named parameters for clarity
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl = '',
    this.vehicleNumber = '',
    this.emergencyContact = '',
  });

  /// Factory constructor to create a UserModel from a JSON map.
  /// This will be used when fetching data from MongoDB in the future.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
    );
  }

  /// Converts the UserModel to a JSON map.
  /// This will be used when sending data to MongoDB in the future.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'vehicleNumber': vehicleNumber,
      'emergencyContact': emergencyContact,
    };
  }

  /// Creates a copy of the UserModel with optional updated fields.
  /// Useful for editing profile without mutating the original object.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? vehicleNumber,
    String? emergencyContact,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  /// Returns a dummy/mock user for development and testing.
  /// Replace this with actual API calls when backend is ready.
  static UserModel getMockUser() {
    return UserModel(
      id: 'usr_001',
      name: 'Rahul Sharma',
      email: 'rahul.sharma@email.com',
      phone: '+91 98765 43210',
      profileImageUrl: '',
      vehicleNumber: 'MH 12 AB 1234',
      emergencyContact: '+91 91234 56789',
    );
  }
}
