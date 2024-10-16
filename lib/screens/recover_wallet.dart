import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // Replace with your actual HomeScreen import

class RecoverWalletScreen extends StatefulWidget {
  const RecoverWalletScreen({super.key});

  @override
  _RecoverWalletScreenState createState() => _RecoverWalletScreenState();
}

class _RecoverWalletScreenState extends State<RecoverWalletScreen> {
  final _seedPhraseController = TextEditingController();
  String _errorMessage = '';

  // Method to recover wallet
  Future<void> _recoverWallet() async {
    final enteredSeedPhrase = _seedPhraseController.text.trim();

    // Get the stored seed phrase from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final storedSeedPhrase = prefs.getString('seedPhrase');

    // Check if the entered seed phrase matches the stored one
    if (storedSeedPhrase != null && enteredSeedPhrase == storedSeedPhrase) {
      // Seed phrase matches, retrieve wallet details
      final publicKey = prefs.getString('publicKey') ?? '';
      final privateKey = prefs.getString('privateKey') ?? '';
      final address = prefs.getString('address') ?? '';

      // Navigate to the HomeScreen and pass wallet details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            seedPhrase: storedSeedPhrase,
            publicKey: publicKey,
            privateKey: privateKey,
            address: address,
          ),
        ),
      );
    } else {
      // Seed phrase doesn't match, show an error message
      setState(() {
        _errorMessage = 'Seed phrase does not match. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Wallet'),
        backgroundColor: const Color(0xFFF9F5D7), // Match background color with the main screen
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            const Text(
              'Recover your wallet by entering your recovery seed phrase.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Add a TextField for entering the recovery phrase
            TextField(
              controller: _seedPhraseController,
              decoration: const InputDecoration(
                labelText: 'Enter Seed Phrase',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty) // Display error message if seed phrase doesn't match
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recoverWallet, // Add logic for recovering the wallet
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFECD245), // Button color
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Recover Wallet',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
