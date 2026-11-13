// lib/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_page.dart';
import '../organizer/pages/organizer_home_page.dart';
import '../participant/pages/participant_home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading state while checking authentication
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // if not logged in, show the login page
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        final user = snapshot.data!;

        // if logged in, fetch their role from Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: _fetchOrCreateUserDoc(user),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('User profile data not found in database.'),
                      TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // extract role
            final data = userSnapshot.data!.data() as Map<String, dynamic>?;
            final role = data?['role'] ?? 'participant';

            switch (role) {
              case 'organizer':
                return const OrganizerHomePage();
              case 'participant':
              default:
                return const ParticipantHomePage();
            }
          },
        );
      },
    );
  }

  Future<DocumentSnapshot> _fetchOrCreateUserDoc(User user) async {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        await userDocRef.set({
          'email': user.email ?? '',
          'role': 'participant', // default fallback role
          'createdAt': FieldValue.serverTimestamp(),
        });
        return await userDocRef.get();
      }

      return docSnapshot;
    } catch (e) {
      debugPrint('Error fetching/creating user doc: $e');
      rethrow;
    }
  }
}