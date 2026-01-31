import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/models/user_model.dart';

class AssistantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<UserModel>> getAssistants(String clientId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('createdBy', isEqualTo: clientId)
        .where('role', isEqualTo: 'assistant')
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> createAssistant(
      String name, String email, String password, String clientId) async {
    // Store current user to restore session later
    final currentUser = _auth.currentUser;
    final currentEmail = currentUser?.email;

    // Create user in Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document in Firestore
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'id': credential.user!.uid,
      'name': name,
      'email': email,
      'role': 'assistant',
      'createdBy': clientId,
      'fcmToken': null,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Sign out the newly created assistant
    await _auth.signOut();

    // Re-authenticate the original client user if we have their email
    // Note: Client will need to re-login if session is lost
    if (currentEmail != null) {
      // We can't automatically re-login without the password
      // The client's Firebase Auth session should still be valid
    }
  }

  Future<void> updateAssistant(
      String assistantId, String name, String email) async {
    await _firestore.collection('users').doc(assistantId).update({
      'name': name,
      'email': email,
    });
  }

  Future<void> deleteAssistant(String assistantId) async {
    await _firestore.collection('users').doc(assistantId).delete();
  }

  Future<void> resetAssistantPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
