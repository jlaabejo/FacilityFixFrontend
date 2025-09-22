import 'package:firebase_auth/firebase_auth.dart';
import 'facilityfix_api_service.dart';
import '../models/api_models.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FacilityFixAPIService _apiService = FacilityFixAPIService();

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Sign in with Firebase
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get Firebase ID token
      final idToken = await credential.user!.getIdToken();

      // Exchange token with backend
      final authResponse = await _apiService.exchangeToken(idToken!);

      return authResponse;
    } catch (e) {
      print('[FacilityFix] Sign in error: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  // Register new user
  Future<AuthResponse> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
    String? buildingId,
    String? unitId,
    String? department,
  }) async {
    try {
      // Create Firebase user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user!.updateDisplayName('$firstName $lastName');

      // Get Firebase ID token
      final idToken = await credential.user!.getIdToken();

      // Register with backend
      final registrationRequest = UserRegistrationRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        role: role,
        buildingId: buildingId,
        unitId: unitId,
        department: department,
      );

      final userResponse = await _apiService.registerUser(registrationRequest);

      // Exchange token with backend
      final authResponse = await _apiService.exchangeToken(idToken!);

      return authResponse;
    } catch (e) {
      print('[FacilityFix] Registration error: $e');
      throw Exception('Failed to register: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _apiService.clearAuthToken();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('[FacilityFix] Sign out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get current user token
  Future<String?> getCurrentUserToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('[FacilityFix] Get token error: $e');
      return null;
    }
  }

  // Refresh authentication
  Future<void> refreshAuth() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken(true); // Force refresh
        await _apiService.exchangeToken(idToken!);
      }
    } catch (e) {
      print('[FacilityFix] Refresh auth error: $e');
      throw Exception('Failed to refresh authentication: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        final userResponse = await _apiService.getCurrentUserProfile(idToken!);
        return userResponse;
      }
      return null;
    } catch (e) {
      print('[FacilityFix] Get current user error: $e');
      return null;
    }
  }
}
