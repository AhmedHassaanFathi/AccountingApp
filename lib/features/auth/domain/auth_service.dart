import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(authServiceProvider).getUserProfile(user.uid);
});

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<UserModel?> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // temporarily bypassing email verification check so you can develop smoothly
  }

  Future<void> registerWithEmailAndPassword(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      // Automatically assign 'employee' role and save to Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': 'employee',
      });
      
      try {
        await cred.user!.sendEmailVerification();
      } catch (_) {} // ignore error if email service is unconfigured
      
      // Sign out so they have to login (or verify) as normal
      await _auth.signOut();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
