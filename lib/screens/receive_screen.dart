import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart'; // Import the share_plus package
import 'package:flutter/services.dart'; // Import for Clipboard functionality

class ReceiveScreen extends StatefulWidget {
  final String walletAddress; // Declare walletAddress as final and required

  // Constructor to accept dynamic wallet address
  const ReceiveScreen({super.key, required this.walletAddress});

  @override
  _ReceiveScreenState createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  String? qrCodeUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQrCode();
  }

  Future<void> fetchQrCode() async {
    try {
      // Use the wallet address from the widget
      String apiUrl = 'https://explorer.manhattangoldcoin.com/qr/${widget.walletAddress}';

      // Make the GET request
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // If the server returns a valid response, use the QR code image URL
        setState(() {
          qrCodeUrl = apiUrl; // Use the same API URL for the QR code image
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load QR code');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle exception
      print('Error fetching QR code: $e');
    }
  }

  void _shareQrCode() {
    if (qrCodeUrl != null) {
      // Share the URL of the QR code
      Share.share(qrCodeUrl!, subject: 'My Wallet QR Code');
    }
  }

  void _copyToClipboard() {
    // Copy wallet address to clipboard using widget's walletAddress
    Clipboard.setData(ClipboardData(text: widget.walletAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet address copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Money'),
        backgroundColor: const Color(0xFFF9F5D7), // AppBar color
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Your QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: isLoading
                  ? const CircularProgressIndicator() // Loading indicator
                  : qrCodeUrl != null
                  ? Image.network(
                qrCodeUrl!, // Display the fetched QR code
                height: 200,
                width: 200,
              )
                  : const Text('Failed to load QR code'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _shareQrCode, // Share functionality added
              icon: const Icon(Icons.share),
              label: const Text('Share QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9F5D7), // Button color
                foregroundColor: Colors.black, // Text color
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _copyToClipboard, // Copy to clipboard functionality
              icon: const Icon(Icons.copy),
              label: const Text('Copy Wallet Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9F5D7), // Button color
                foregroundColor: Colors.black, // Text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
