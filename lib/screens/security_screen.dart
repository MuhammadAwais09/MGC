import 'package:flutter/material.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Center'),
        backgroundColor: const Color(0xFFF9F5D7),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Enhance your Wallet Security',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Take the following steps to secure your wallet:',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Option 1: Set or Change PIN
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.blue),
              title: const Text('Set or Change Wallet PIN'),
              subtitle: const Text('Secure your wallet with a 6-digit PIN.'),
              onTap: () {
                // Navigate to the Set/Change PIN screen
              },
            ),
            const Divider(),

            // Option 2: Backup Seed Phrase
            ListTile(
              leading: const Icon(Icons.security, color: Colors.red),
              title: const Text('Backup Seed Phrase'),
              subtitle: const Text('Ensure you have securely backed up your seed phrase.'),
              onTap: () {
                // Show backup seed phrase screen
              },
            ),
            const Divider(),

            // Option 3: Lock Wallet
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.orange),
              title: const Text('Lock Wallet'),
              subtitle: const Text('Temporarily lock your wallet for security.'),
              onTap: () {
                // Lock wallet functionality
              },
            ),
            const Divider(),

            const SizedBox(height: 24),
            const Text(
              'Security Tips:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 16),

            const Text(
              '- **Never share your seed phrase with anyone.**\n'
                  '- **Regularly backup your wallet data.**\n'
                  '- **Use a strong PIN to protect your wallet.**\n'
                  '- **Lock your wallet when not in use.**\n'
                  '- **Be cautious of phishing attacks. Always verify URLs before entering sensitive information.**\n'
                  '- **Keep your device secure with antivirus software and updates.**\n'
                  '- **Consider using a hardware wallet for storing large amounts.**',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
