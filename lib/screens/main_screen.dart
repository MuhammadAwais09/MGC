import 'package:flutter/material.dart';
import 'package:manhattangoldcoin/screens/recover_wallet.dart';
import 'passcode_screen.dart'; // Import the PasscodeScreen file

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5D7), // Background color
      appBar: AppBar(
        title: null, // Clear AppBar title
        backgroundColor: const Color(0xFFF9F5D7), // Match background color
        elevation: 0, // Remove shadow
        centerTitle: true, // Center title (although title is null)
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensure buttons are near bottom
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top center icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/logo.png', // Replace with your image path
                  width: 150, // Set size as needed
                  height: 100,
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Secure text
            const Text(
              'Your trusted partner in digital currency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            // Main image
            Image.asset(
              'assets/icons/splash1.png', // Replace with your image path
              width: 200, // Increased size
              height: 200,
            ),
            const SizedBox(height: 30),
            // Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity, // Full width
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PasscodeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5DEB3), // Button color
                      foregroundColor: Colors.black, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Round corners
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Create Wallet!',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity, // Full width
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RecoverWalletScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFECD245), // Button color
                      foregroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Round corners
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Recover Wallet',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
            // App version
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0), // Space at the bottom
              child: Text(
                'App Version: 1.0.0', // Update the version as needed
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
