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
      final idToken = await credential.user?.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      // Exchange token with backend
      final authResponse = await _apiService.exchangeToken(idToken);

      return authResponse;
    } on FirebaseAuthException catch (e) {
      print('[FacilityFix] Firebase Auth error: ${e.code} - ${e.message}');
      String errorMessage = 'Failed to sign in';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'Authentication failed';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('[FacilityFix] Sign in error: $e');
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Register new user
  Future<AuthResponse> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String birthDate,
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
      await credential.user?.updateDisplayName('$firstName $lastName');

      // Get Firebase ID token
      final idToken = await credential.user?.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token after registration');
      }

      // Register with backend
      final registrationRequest = UserRegistrationRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        birthDate: birthDate,
        role: role,
        buildingId: buildingId,
        unitId: unitId,
        staffDepartment: department,
      );

      await _apiService.registerUser(registrationRequest);

      // Exchange token with backend
      final authResponse = await _apiService.exchangeToken(idToken);

      return authResponse;
    } on FirebaseAuthException catch (e) {
      print('[FacilityFix] Firebase Auth registration error: ${e.code} - ${e.message}');
      String errorMessage = 'Failed to register';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('[FacilityFix] Registration error: $e');
      throw Exception('Failed to register: ${e.toString()}');
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
    } on FirebaseAuthException catch (e) {
      print('[FacilityFix] Firebase Auth get token error: ${e.code} - ${e.message}');
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
        if (idToken == null) {
          throw Exception('Failed to refresh authentication token');
        }
        await _apiService.exchangeToken(idToken);
      }
    } on FirebaseAuthException catch (e) {
      print('[FacilityFix] Firebase Auth refresh error: ${e.code} - ${e.message}');
      throw Exception('Failed to refresh authentication: ${e.message ?? e.code}');
    } catch (e) {
      print('[FacilityFix] Refresh auth error: $e');
      throw Exception('Failed to refresh authentication: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        if (idToken == null) {
          print('[FacilityFix] Failed to get ID token for current user');
          return null;
        }
        final userResponse = await _apiService.getCurrentUserProfile(idToken);
        return userResponse;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('[FacilityFix] Firebase Auth get current user error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('[FacilityFix] Get current user error: $e');
      return null;
    }
  }
}
