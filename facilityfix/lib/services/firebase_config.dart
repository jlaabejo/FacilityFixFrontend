import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Configuration and Helper Class
/// 
/// Ensure the following Firestore Security Rules are applied in Firebase Console:
/// ```
/// rules_version = '2';
/// service cloud.firestore {
///   match /databases/{database}/documents {
///     // Allow authenticated users to read/write their own chat rooms
///     match /rooms/{roomId} {
///       allow read, write: if request.auth != null && 
///         (request.auth.uid in resource.data.participants || 
///          request.auth.uid in request.resource.data.participants);
///       
///       // Allow read/write access to messages in rooms where user is a participant
///       match /messages/{messageId} {
///         allow read, write: if request.auth != null && 
///           request.auth.uid in get(/databases/$(database)/documents/rooms/$(roomId)).data.participants;
///       }
///     }
///   }
/// }
/// ```
class FirebaseConfig {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  // Collection references
  static CollectionReference get rooms => firestore.collection('rooms');
  static CollectionReference messagesCollection(String roomId) =>
      rooms.doc(roomId).collection('messages');

  // Storage references
  static Reference get storageRoot => storage.ref();
  static Reference userProfileImages(String userId) =>
      storageRoot.child('users/$userId/profile');
  static Reference userDocuments(String userId) =>
      storageRoot.child('users/$userId/documents');

  /// Get download URL from a Firebase Storage path or URL
  /// Handles multiple input formats:
  /// - gs://bucket/path/to/file
  /// - https://storage.googleapis.com/bucket/path/to/file
  /// - users/userId/profile/image.jpg (relative path)
  static Future<String?> getDownloadUrl(String pathOrUrl) async {
    try {
      print('[FirebaseConfig] Getting download URL for: $pathOrUrl');

      String path;

      // Handle gs:// URLs
      if (pathOrUrl.startsWith('gs://')) {
        // Extract path from gs://bucket-name/path/to/file
        final uri = Uri.parse(pathOrUrl);
        path = uri.path.substring(1); // Remove leading slash
        print('[FirebaseConfig] Extracted path from gs:// URL: $path');
      }
      // Handle https://storage.googleapis.com URLs
      else if (pathOrUrl.contains('storage.googleapis.com')) {
        // Extract path from URL
        final uri = Uri.parse(pathOrUrl);
        // Format: https://storage.googleapis.com/bucket-name/path/to/file
        final segments = uri.pathSegments;
        if (segments.length > 1) {
          // Skip bucket name and get the rest
          path = segments.sublist(1).join('/');
          print('[FirebaseConfig] Extracted path from googleapis URL: $path');
        } else {
          print('[FirebaseConfig] Invalid googleapis URL format');
          return null;
        }
      }
      // Handle firebasestorage.googleapis.com URLs (already authenticated)
      else if (pathOrUrl.contains('firebasestorage.googleapis.com')) {
        print('[FirebaseConfig] URL already authenticated, returning as-is');
        return pathOrUrl;
      }
      // Assume it's a relative path
      else {
        path = pathOrUrl;
        print('[FirebaseConfig] Using relative path: $path');
      }

      // Get the download URL from Firebase Storage
      final ref = storage.ref(path);
      final downloadUrl = await ref.getDownloadURL();

      print('[FirebaseConfig] Download URL obtained successfully');
      return downloadUrl;

    } catch (e) {
      print('[FirebaseConfig] Error getting download URL: $e');
      // If it's already a valid URL, return it
      if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
        return pathOrUrl;
      }
      return null;
    }
  }

  // Helper method to configure Firestore settings
  static void configureFirestore() {
    try {
      // Enable offline persistence for better performance
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print('Firestore settings configured successfully');
    } catch (e) {
      print('Error configuring Firestore settings: $e');
    }
  }
  
  // Test Firebase connection with more detailed diagnostics
  static Future<bool> testConnection() async {
    try {
      print('Testing Firebase connection...');
      
      // First try to check if Firebase app is initialized
      final app = Firebase.app();
      print('Firebase app name: ${app.name}');
      print('Firebase project ID: ${app.options.projectId}');
      
      // Try a simple read operation instead of write (less permission issues)
      await FirebaseFirestore.instance
          .collection('_connection_test')
          .limit(1)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );
      
      print('Firebase connection test successful - read operation completed');
      return true;
      
    } catch (e) {
      print('Firebase connection test failed: $e');
      
      // Check if we can at least access Firestore instance and settings
      try {
        print('Checking Firestore settings availability...');
        final settings = FirebaseFirestore.instance.settings;
        if (settings.persistenceEnabled == true) {
          print('Firestore settings accessible: persistence enabled');
          print('Firebase SDK is working, connection issues may be due to:');
          print('- Network connectivity issues');
          print('- Firestore security rules restrictions');
          print('- Authentication requirements');
          print('Continuing with offline persistence support...');
          return true; // Allow offline operations
        } else {
          print('Firestore settings accessible but persistence disabled');
          return false;
        }
      } catch (e2) {
        print('Cannot access Firestore settings: $e2');
        print('Firebase SDK may not be properly initialized');
        return false;
      }
    }
  }
}