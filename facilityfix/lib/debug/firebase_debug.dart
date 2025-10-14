import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseDebugUtils {
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Check Firebase initialization
      results['firebase_apps'] = Firebase.apps.map((app) => {
        'name': app.name,
        'options': {
          'projectId': app.options.projectId,
          'apiKey': app.options.apiKey.substring(0, 10) + '...',
        }
      }).toList();
      
      // 2. Check Firestore instance
      final firestore = FirebaseFirestore.instance;
      results['firestore_instance'] = 'Created successfully';
      
      // 3. Check Firestore settings
      try {
        final settings = firestore.settings;
        results['firestore_settings'] = {
          'persistence_enabled': settings.persistenceEnabled,
          'host': settings.host,
          'ssl_enabled': settings.sslEnabled,
          'cache_size_bytes': settings.cacheSizeBytes,
        };
      } catch (e) {
        results['firestore_settings_error'] = e.toString();
      }
      
      // 4. Try simple read operation
      try {
        print('Attempting Firestore read test...');
        final testDoc = await firestore
            .collection('test')
            .doc('connection_test')
            .get()
            .timeout(Duration(seconds: 10));
        
        results['read_test'] = {
          'success': true,
          'exists': testDoc.exists,
          'metadata_from_cache': testDoc.metadata.isFromCache,
          'metadata_has_pending_writes': testDoc.metadata.hasPendingWrites,
        };
      } catch (e) {
        results['read_test'] = {
          'success': false,
          'error': e.toString(),
          'error_type': e.runtimeType.toString(),
        };
      }
      
      // 5. Try simple write operation
      try {
        print('Attempting Firestore write test...');
        await firestore
            .collection('test')
            .doc('connection_test')
            .set({
              'timestamp': FieldValue.serverTimestamp(),
              'test': true,
            })
            .timeout(Duration(seconds: 10));
        
        results['write_test'] = {
          'success': true,
        };
      } catch (e) {
        results['write_test'] = {
          'success': false,
          'error': e.toString(),
          'error_type': e.runtimeType.toString(),
        };
      }
      
      // 6. Check network connectivity
      try {
        print('Testing network connectivity...');
        results['network_test'] = 'Network check not implemented for Flutter web';
      } catch (e) {
        results['network_test'] = 'Error: ${e.toString()}';
      }
      
    } catch (e) {
      results['general_error'] = e.toString();
    }
    
    return results;
  }
  
  static void printDiagnostics(Map<String, dynamic> results) {
    print('\n=== FIREBASE DIAGNOSTICS ===');
    results.forEach((key, value) {
      print('$key: $value');
    });
    print('=== END DIAGNOSTICS ===\n');
  }
}