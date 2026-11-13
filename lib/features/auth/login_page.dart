import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'participant';

  Future<void> _submit(bool signUp) async {
    final auth = FirebaseAuth.instance;
    final email = _email.text.trim();
    try {
      if (signUp) {
        // create user in firebase
        final cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: _password.text,
        );

        // write the profile document to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'email': email,
          'role': _role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: _password.text);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Campus Event Management',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role (for new accounts)', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'participant', child: Text('Event Participant')),
                    DropdownMenuItem(value: 'organizer', child: Text('Event Organizer')),
                    DropdownMenuItem(value: 'staff', child: Text('Check-in Staff')),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: () => _submit(false), child: const Text('Log in')),
                ),
                TextButton(onPressed: () => _submit(true), child: const Text('Create account')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}