import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParticipantHomePage extends StatelessWidget {
  const ParticipantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome! Browse and register for campus events.'),
      ),
    );
  }
}