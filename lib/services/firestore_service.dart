import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// Toda la lectura/escritura de datos "de negocio" vive aquí. Cada método
/// habla directo con Firestore, así que los cambios se sincronizan en
/// tiempo real entre adoptantes y refugios (streams).
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _pets => _db.collection('pets');
  CollectionReference<Map<String, dynamic>> get _matches => _db.collection('matches');
  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');

  // ---------------------------------------------------------------------
  // PERFILES
  // ---------------------------------------------------------------------
  Future<void> createInitialProfile(UserProfile profile) {
    return _users.doc(profile.uid).set(profile.toMap());
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).update(data);
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data()!);
    });
  }

  // ---------------------------------------------------------------------
  // MASCOTAS
  // ---------------------------------------------------------------------
  Future<String> publishPet(Pet pet) async {
    final ref = _pets.doc();
    await ref.set(pet.toMap());
    return ref.id;
  }

  /// Todas las mascotas activas, excluyendo las publicadas por [excludeShelterId]
  /// (para que un refugio no vea sus propias mascotas en modo "explorar").
  Stream<List<Pet>> watchAvailablePets({String? excludeShelterId}) {
    return _pets.where('active', isEqualTo: true).snapshots().map((snap) {
      final pets = snap.docs.map((d) => Pet.fromMap(d.id, d.data())).toList();
      if (excludeShelterId != null) {
        pets.removeWhere((p) => p.shelterId == excludeShelterId);
      }
      return pets;
    });
  }

  Stream<List<Pet>> watchShelterPets(String shelterId) {
    return _pets.where('shelterId', isEqualTo: shelterId).snapshots().map(
        (snap) => snap.docs.map((d) => Pet.fromMap(d.id, d.data())).toList());
  }

  Future<void> updatePet(String petId, Map<String, dynamic> data) {
    return _pets.doc(petId).update(data);
  }

  Future<void> deletePet(String petId) {
    return _pets.doc(petId).delete();
  }

  // ---------------------------------------------------------------------
  // MATCHES / SOLICITUDES DE ADOPCIÓN
  // ---------------------------------------------------------------------
  /// Crea la solicitud de adopción y, junto con ella, el chat vinculado
  /// entre adoptante y refugio (mismo id para que sea 1:1 con el match).
  Future<void> requestAdoption({
    required Pet pet,
    required UserProfile adopter,
  }) async {
    final matchId = _uuid.v4();
    final match = AdoptionMatch(
      id: matchId,
      petId: pet.id,
      petName: pet.name,
      petImageUrl: pet.imageUrl,
      shelterId: pet.shelterId,
      shelterName: pet.shelterName,
      adopterId: adopter.uid,
      adopterName: adopter.name,
      adopterPhotoUrl: adopter.photoUrl,
      status: MatchStatus.pending,
      chatId: matchId,
    );
    await _matches.doc(matchId).set(match.toMap());
    await _chats.doc(matchId).set({
      'participants': [adopter.uid, pet.shelterId],
      'petName': pet.name,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageAt': null,
    });
  }

  Stream<List<AdoptionMatch>> watchMatchesForAdopter(String adopterId) {
    return _matches.where('adopterId', isEqualTo: adopterId).snapshots().map(
        (snap) => snap.docs.map((d) => AdoptionMatch.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000))));
  }

  /// Para el panel "técnico" del refugio: todas las solicitudes que recibió,
  /// con los datos completos del adoptante para poder evaluarlas.
  Stream<List<AdoptionMatch>> watchMatchesForShelter(String shelterId) {
    return _matches.where('shelterId', isEqualTo: shelterId).snapshots().map(
        (snap) => snap.docs.map((d) => AdoptionMatch.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000))));
  }

  /// Actualiza el estado de una solicitud. Si se ACEPTA:
  ///  - La mascota se marca `active: false` para que desaparezca del feed
  ///    de "Explorar" al instante (ya fue adoptada).
  ///  - Cualquier otra solicitud pendiente para esa misma mascota se
  ///    rechaza automáticamente, porque ya no hay mascota disponible.
  Future<void> updateMatchStatus(String matchId, MatchStatus status, {String? petId}) async {
    if (status == MatchStatus.accepted && petId != null) {
      final batch = _db.batch();
      batch.update(_matches.doc(matchId), {'status': status.value});
      batch.update(_pets.doc(petId), {'active': false});

      final otherPending = await _matches
          .where('petId', isEqualTo: petId)
          .where('status', isEqualTo: MatchStatus.pending.value)
          .get();
      for (final doc in otherPending.docs) {
        if (doc.id != matchId) {
          batch.update(doc.reference, {'status': MatchStatus.rejected.value});
        }
      }
      await batch.commit();
    } else {
      await _matches.doc(matchId).update({'status': status.value});
    }
  }

  // ---------------------------------------------------------------------
  // CHAT EN TIEMPO REAL
  // ---------------------------------------------------------------------
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final msg = ChatMessage(id: '', senderId: senderId, text: text);
    await _chats.doc(chatId).collection('messages').add(msg.toMap());
    await _chats.doc(chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>?> watchChatMeta(String chatId) {
    return _chats.doc(chatId).snapshots().map((d) => d.data());
  }
}
