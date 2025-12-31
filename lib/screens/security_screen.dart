// lib/screens/security_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_model.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthModel>(context);
    final email = auth.userEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: const Color(0xFF1B1B1B),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1B1B1B),
      body: email == null
          ? const Center(
        child: Text(
          'Not signed in',
          style: TextStyle(color: Colors.white),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Data encrypted',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Email: $email',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const SwitchListTile(
              title: Text(
                'Enable 2FA (email OTP)',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Coming soon',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: false,
              onChanged: null,
            ),
            const SwitchListTile(
              title: Text(
                'Enable biometric login',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Coming soon',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: false,
              onChanged: null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await auth.sendPasswordResetEmail(email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to send reset email'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Request password reset (email)'),
            ),
          ],
        ),
      ),
    );
  }
}
