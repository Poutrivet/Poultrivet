import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farmer_model.dart';

/// We use email/password auth under the hood.
/// The "email" is derived from the phone number: +256700123456 → 256700123456@poulvet.app
/// This means no SMS, no billing — just standard Firebase email/password auth.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Convert phone to fake email ─────────────────────────────────────────────
  String _phoneToEmail(String phone) {
    // Strip all non-digits from phone, e.g. +256700123456 → 256700123456
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits@poulvet.app';
  }

  // ─── Sign Up ─────────────────────────────────────────────────────────────────
  Future<UserCredential> signUp({
    required String phoneNumber,
    required String password,
  }) async {
    final email = _phoneToEmail(phoneNumber);
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────────
  Future<UserCredential> signIn({
    required String phoneNumber,
    required String password,
  }) async {
    final email = _phoneToEmail(phoneNumber);
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─── Save farmer profile to Firestore ────────────────────────────────────────
  Future<void> saveFarmerProfile(FarmerModel farmer) async {
    await _firestore
        .collection('farmers')
        .doc(farmer.uid)
        .set(farmer.toMap());
  }

  // ─── Check if profile exists ──────────────────────────────────────────────────
  Future<bool> farmerProfileExists(String uid) async {
    final doc = await _firestore.collection('farmers').doc(uid).get();
    return doc.exists;
  }

  // ─── Get farmer profile ───────────────────────────────────────────────────────
  Future<FarmerModel?> getFarmerProfile(String uid) async {
    final doc = await _firestore.collection('farmers').doc(uid).get();
    if (doc.exists) return FarmerModel.fromMap(doc.data()!);
    return null;
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────────
  Future<void> signOut() async => await _auth.signOut();
}
