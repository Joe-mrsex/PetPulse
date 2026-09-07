import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// ENUMS
// -----------------------------------------------------------------------------
enum UserRole { adopter, shelter }

enum HousingType { apartment, house }

enum MatchStatus { pending, accepted, rejected }

extension UserRoleX on UserRole {
  String get label => this == UserRole.adopter ? 'Adoptante' : 'Refugio / Rescatista';
  String get value => this == UserRole.adopter ? 'adopter' : 'shelter';

  static UserRole fromValue(String? v) => v == 'shelter' ? UserRole.shelter : UserRole.adopter;
}

extension HousingTypeX on HousingType {
  String get label => this == HousingType.apartment ? 'Departamento' : 'Casa con Patio';
  String get value => this == HousingType.apartment ? 'apartment' : 'house';
  IconData get icon => this == HousingType.apartment ? Icons.apartment_rounded : Icons.house_rounded;

  static HousingType fromValue(String? v) => v == 'house' ? HousingType.house : HousingType.apartment;
}

extension MatchStatusX on MatchStatus {
  String get value {
    switch (this) {
      case MatchStatus.pending:
        return 'pending';
      case MatchStatus.accepted:
        return 'accepted';
      case MatchStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case MatchStatus.pending:
        return 'Pendiente de aprobación';
      case MatchStatus.accepted:
        return 'Aceptado';
      case MatchStatus.rejected:
        return 'No aprobado';
    }
  }

  Color get color {
    switch (this) {
      case MatchStatus.pending:
        return const Color(0xFFF59E0B);
      case MatchStatus.accepted:
        return const Color(0xFF10B981);
      case MatchStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case MatchStatus.pending:
        return Icons.schedule_rounded;
      case MatchStatus.accepted:
        return Icons.check_circle_rounded;
      case MatchStatus.rejected:
        return Icons.cancel_rounded;
    }
  }

  static MatchStatus fromValue(String? v) {
    switch (v) {
      case 'accepted':
        return MatchStatus.accepted;
      case 'rejected':
        return MatchStatus.rejected;
      default:
        return MatchStatus.pending;
    }
  }
}

// -----------------------------------------------------------------------------
// PERFIL DE USUARIO (Firestore: collection "users")
// -----------------------------------------------------------------------------
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl; // Obligatoria antes de usar la app.
  final String? phone;

  // Ubicación (elegida desde Google Maps).
  final double? latitude;
  final double? longitude;
  final String? addressLabel;

  // Solo adoptantes.
  final HousingType? housingType;
  final bool? hasChildren;
  final bool? hasOtherPets;
  final String? bio;

  // Solo refugios / rescatistas.
  final String? organizationName;
  final String? organizationDescription;
  final String? legalIdOrRuc;

  final bool onboardingComplete;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.phone,
    this.latitude,
    this.longitude,
    this.addressLabel,
    this.housingType,
    this.hasChildren,
    this.hasOtherPets,
    this.bio,
    this.organizationName,
    this.organizationDescription,
    this.legalIdOrRuc,
    this.onboardingComplete = false,
    this.createdAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  UserProfile copyWith({
    String? name,
    String? photoUrl,
    String? phone,
    double? latitude,
    double? longitude,
    String? addressLabel,
    HousingType? housingType,
    bool? hasChildren,
    bool? hasOtherPets,
    String? bio,
    String? organizationName,
    String? organizationDescription,
    String? legalIdOrRuc,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressLabel: addressLabel ?? this.addressLabel,
      housingType: housingType ?? this.housingType,
      hasChildren: hasChildren ?? this.hasChildren,
      hasOtherPets: hasOtherPets ?? this.hasOtherPets,
      bio: bio ?? this.bio,
      organizationName: organizationName ?? this.organizationName,
      organizationDescription: organizationDescription ?? this.organizationDescription,
      legalIdOrRuc: legalIdOrRuc ?? this.legalIdOrRuc,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.value,
      'photoUrl': photoUrl,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'addressLabel': addressLabel,
      'housingType': housingType?.value,
      'hasChildren': hasChildren,
      'hasOtherPets': hasOtherPets,
      'bio': bio,
      'organizationName': organizationName,
      'organizationDescription': organizationDescription,
      'legalIdOrRuc': legalIdOrRuc,
      'onboardingComplete': onboardingComplete,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRoleX.fromValue(map['role'] as String?),
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      addressLabel: map['addressLabel'],
      housingType: map['housingType'] == null ? null : HousingTypeX.fromValue(map['housingType']),
      hasChildren: map['hasChildren'],
      hasOtherPets: map['hasOtherPets'],
      bio: map['bio'],
      organizationName: map['organizationName'],
      organizationDescription: map['organizationDescription'],
      legalIdOrRuc: map['legalIdOrRuc'],
      onboardingComplete: map['onboardingComplete'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// -----------------------------------------------------------------------------
// MASCOTA (Firestore: collection "pets")
// -----------------------------------------------------------------------------
class Pet {
  final String id;
  final String shelterId;
  final String shelterName;
  final String name;
  final String species;
  final String age;
  final String breed;
  final String? addressLabel;
  final double? latitude;
  final double? longitude;
  final String imageUrl;
  final String housingTag;
  final String description;
  final String? vaccineCardUrl; // Puede ser imagen o PDF.
  final Map<String, bool> healthChecklist;
  final bool active;
  final DateTime? createdAt;

  const Pet({
    required this.id,
    required this.shelterId,
    required this.shelterName,
    required this.name,
    required this.species,
    required this.age,
    required this.breed,
    this.addressLabel,
    this.latitude,
    this.longitude,
    required this.imageUrl,
    required this.housingTag,
    required this.description,
    this.vaccineCardUrl,
    this.healthChecklist = const {},
    this.active = true,
    this.createdAt,
  });

  IconData get housingIcon =>
      housingTag.toLowerCase().contains('depart') ? Icons.apartment_rounded : Icons.house_rounded;

  Map<String, dynamic> toMap() {
    return {
      'shelterId': shelterId,
      'shelterName': shelterName,
      'name': name,
      'species': species,
      'age': age,
      'breed': breed,
      'addressLabel': addressLabel,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'housingTag': housingTag,
      'description': description,
      'vaccineCardUrl': vaccineCardUrl,
      'healthChecklist': healthChecklist,
      'active': active,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }

  factory Pet.fromMap(String id, Map<String, dynamic> map) {
    return Pet(
      id: id,
      shelterId: map['shelterId'] ?? '',
      shelterName: map['shelterName'] ?? '',
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      age: map['age'] ?? '',
      breed: map['breed'] ?? '',
      addressLabel: map['addressLabel'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      housingTag: map['housingTag'] ?? '',
      description: map['description'] ?? '',
      vaccineCardUrl: map['vaccineCardUrl'],
      healthChecklist: Map<String, bool>.from(map['healthChecklist'] ?? {}),
      active: map['active'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// -----------------------------------------------------------------------------
// SOLICITUD / MATCH (Firestore: collection "matches")
// -----------------------------------------------------------------------------
class AdoptionMatch {
  final String id;
  final String petId;
  final String petName;
  final String petImageUrl;
  final String shelterId;
  final String shelterName;
  final String adopterId;
  final String adopterName;
  final String? adopterPhotoUrl;
  final MatchStatus status;
  final DateTime? createdAt;
  final String chatId;

  const AdoptionMatch({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petImageUrl,
    required this.shelterId,
    required this.shelterName,
    required this.adopterId,
    required this.adopterName,
    this.adopterPhotoUrl,
    required this.status,
    this.createdAt,
    required this.chatId,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'petName': petName,
      'petImageUrl': petImageUrl,
      'shelterId': shelterId,
      'shelterName': shelterName,
      'adopterId': adopterId,
      'adopterName': adopterName,
      'adopterPhotoUrl': adopterPhotoUrl,
      'status': status.value,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'chatId': chatId,
    };
  }

  factory AdoptionMatch.fromMap(String id, Map<String, dynamic> map) {
    return AdoptionMatch(
      id: id,
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? '',
      petImageUrl: map['petImageUrl'] ?? '',
      shelterId: map['shelterId'] ?? '',
      shelterName: map['shelterName'] ?? '',
      adopterId: map['adopterId'] ?? '',
      adopterName: map['adopterName'] ?? '',
      adopterPhotoUrl: map['adopterPhotoUrl'],
      status: MatchStatusX.fromValue(map['status']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      chatId: map['chatId'] ?? id,
    );
  }
}

// -----------------------------------------------------------------------------
// MENSAJE DE CHAT (Firestore: collection "chats/{chatId}/messages")
// -----------------------------------------------------------------------------
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
    };
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate(),
    );
  }
}
