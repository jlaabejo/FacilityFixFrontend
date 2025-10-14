import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestWidget extends StatefulWidget {
  @override
  _FirebaseTestWidgetState createState() => _FirebaseTestWidgetState();
}

class _FirebaseTestWidgetState extends State<FirebaseTestWidget> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase connection...';
    });

    try {
      // 1. Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = 'ERROR: User not authenticated. Please login first.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _status = 'User authenticated: ${user.email}\nTesting Firestore...';
      });

      // 2. Test Firestore read access
      final firestore = FirebaseFirestore.instance;
      
      // Try to read from a test collection (should work with new rules)
      final testResult = await firestore
          .collection('test')
          .doc('connection_test')
          .get()
          .timeout(Duration(seconds: 10));

      setState(() {
        _status = 'SUCCESS: Firestore connection working!\n'
                 'Test document exists: ${testResult.exists}\n'
                 'From cache: ${testResult.metadata.isFromCache}';
      });

      // 3. Test chat collections access
      try {
        final chatRoomsQuery = await firestore
            .collection('chat_rooms')
            .limit(1)
            .get()
            .timeout(Duration(seconds: 5));
        
        setState(() {
          _status += '\nChat rooms accessible: ✅\n'
                    'Found ${chatRoomsQuery.docs.length} chat rooms';
        });
      } catch (chatError) {
        setState(() {
          _status += '\nChat rooms access failed: ❌\n'
                    'Error: $chatError\n'
                    'This means Firestore rules need to be updated.';
        });
      }

    } catch (e) {
      setState(() {
        _status = 'ERROR: Firebase connection failed\n'
                 'Error: $e\n\n'
                 'This usually means:\n'
                 '1. Firestore rules are blocking access\n'
                 '2. Network connectivity issues\n'
                 '3. Invalid Firebase configuration';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Connection Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testFirebaseConnection,
              child: _isLoading 
                ? CircularProgressIndicator()
                : Text('Test Firebase Connection'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Instructions:\n'
              '1. Make sure you are logged in\n'
              '2. Update Firestore rules with chat collections\n'
              '3. Test the connection',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}