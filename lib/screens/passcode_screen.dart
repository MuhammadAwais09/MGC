import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:mops_wallet_core/mops_wallet_core.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:hashlib/hashlib.dart' as hashlib;
import 'home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  _PasscodeScreenState createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  List<String> _pinDigits = ['', '', '', '', '', ''];
  List<String> _storedPinDigits = [];
  bool _isConfirming = false;
  bool _isLoading = false;
  String _errorMessage = '';
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  void _updatePin(int index, String value) {
    setState(() {
      _pinDigits[index] = value;
    });

    if (!_isConfirming && _pinDigits.every((digit) => digit.isNotEmpty)) {
      _storedPinDigits = List.from(_pinDigits);
      setState(() {
        _isConfirming = true;
        _pinDigits = ['', '', '', '', '', '']; // Reset for confirmation
        _errorMessage = ''; // Clear error message
      });
    }
  }


  void _onKeyPress(String value) {
    for (int i = 0; i < _pinDigits.length; i++) {
      if (_pinDigits[i].isEmpty) {
        _updatePin(i, value);
        return;
      }
    }
  }

  void _onDelete() {
    for (int i = _pinDigits.length - 1; i >= 0; i--) {
      if (_pinDigits[i].isNotEmpty) {
        _updatePin(i, '');
        return;
      }
    }
  }

  Future<void> _onConfirm() async {
    if (_pinDigits.join() == _storedPinDigits.join()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Generate seed phrase from PIN
        final seedPhrase = _generateSeedPhraseFromPin(_pinDigits.join());
        final prefs = await SharedPreferences.getInstance(); // Get SharedPreferences instance
        await prefs.setString('seedPhrase', seedPhrase);
        // Create wallet using the generated seed phrase
        final walletManager = WalletManager();
        final walletCreate = WalletCreate();
        final wallet = await walletCreate.createWallet('MGC', seedPhrase);

        // Convert mnemonic to seed
        final seed = bip39.mnemonicToSeed(seedPhrase);

        // Create a master key from the seed using BIP32
        final root = bip32.BIP32.fromSeed(seed);

        // Derive a child key (e.g., for the first account)
        final child = root.derivePath("m/44'/0'/0'/0/0"); // Example BIP44 path

        // Extract private and public keys
        final privateKeyBytes = child.privateKey;
        final publicKeyBytes = child.publicKey;

        // Convert private and public keys to hexadecimal strings
        final privateKeyHex = privateKeyBytes!.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
        final publicKeyHex = publicKeyBytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

        // Convert public key to Base58
        final publicKeyBase58 = Base58Encode(Uint8List.fromList(publicKeyBytes));

        // Generate wallet address from Base58 public key
        final address = _generateWalletAddress(publicKeyBase58);

        setState(() {
          _isLoading = false;
        });


        await prefs.setString('privateKey', privateKeyHex); // Store private key
        await prefs.setString('publicKey', publicKeyHex); // Store public key
        await prefs.setString('address', address); // Store wallet address

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              privateKey: privateKeyHex,  // Use the hex format
              publicKey: publicKeyHex,    // Use the hex format
              address: address,
              seedPhrase: seedPhrase,
            ),
          ),
        );
      } catch (e, stackTrace) {
        // Log the error to the console for debugging
        debugPrint('Error: $e');
        debugPrint('Stack Trace: $stackTrace');  // Add stack trace for more details

        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred while creating the wallet. Please try again.';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Passcodes do not match. Please try again.';
        _pinDigits = ['', '', '', '', '', '']; // Reset for retry
      });
    }
  }


  Future<String?> _getStoredSeedPhrase() async {
    return await secureStorage.read(key: 'seedPhrase');
  }

  String _generateSeedPhraseFromPin(String pin) {
    // Generate a unique salt for each wallet
    final salt = base64.encode(List<int>.generate(32, (i) => math.Random.secure().nextInt(256)));

    // Concatenate PIN and salt
    final pinWithSalt = '$pin$salt';

    // Generate SHA-256 hash of the concatenated string
    final bytes = utf8.encode(pinWithSalt);
    final hash = hashlib.sha256.convert(Uint8List.fromList(bytes));

    // Convert the hash bytes to a hex string
    final hexString = hash.bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    // Check the length of the hex string
    if (hexString.length != 64) {
      throw Exception('Hex string length is incorrect: ${hexString.length}');
    }

    // Generate a mnemonic phrase from the hex string
    final mnemonic = bip39.entropyToMnemonic(hexString.substring(0, 32)); // Use first 32 characters of hexString (128-bit) for 12-word mnemonic
    return mnemonic;
  }

  String _generateWalletAddress(String publicKeyBase58) {
    // Decode the Base58 public key
    final publicKeyBytes = Base58Decode(publicKeyBase58);

    // Perform RIPEMD-160 hash on the public key
    final ripemd160 = hashlib.ripemd160.convert(Uint8List.fromList(publicKeyBytes));
    final publicKeyHash = ripemd160.bytes;

    // Modify version byte to make the address start with "M" instead of "L"
    final versionByte = [0x32]; // Modified version byte for "M" starting address

    // Create address by adding version byte and checksum
    final addressBytes = Uint8List.fromList(versionByte + publicKeyHash);
    final checksum = hashlib.sha256.convert(hashlib.sha256.convert(addressBytes).bytes).bytes.sublist(0, 4);
    final addressWithChecksum = Uint8List.fromList(addressBytes + checksum);

    // Encode the final address to Base58
    final addressBase58 = Base58Encode(addressWithChecksum);
    return addressBase58;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Passcode'),
        backgroundColor: const Color(0xFFF9F5D7),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9F5D7),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isConfirming)
                  const Text(
                    'Please retype your pin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )
                else
                  const Text(
                    'Set Pin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Your pin will be used to unlock your Manhattan Wallet and send money',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black54),
                      ),
                      child: Center(
                        child: Text(
                          _pinDigits[index],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Remember this pin. If you forget it, you won\'t be able to access your Manhattan Gold Coin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ],
                if (_isLoading) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text('Wallet Created'),
                ],
              ],
            ),
          ),
          Container(
            color: const Color(0xFFF9F5D7),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumberButton('1'),
                    _buildNumberButton('2'),
                    _buildNumberButton('3'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumberButton('4'),
                    _buildNumberButton('5'),
                    _buildNumberButton('6'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumberButton('7'),
                    _buildNumberButton('8'),
                    _buildNumberButton('9'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 45),
                    _buildNumberButton('0'),
                    _buildDeleteButton(),
                  ],
                ),
              ],
            ),
          ),
          if (_isConfirming)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _onConfirm,
                child: const Text('Confirm'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String text) {
    return SizedBox(
      width: 45,
      height: 45,
      child: ElevatedButton(
        onPressed: () => _onKeyPress(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF9F5D7),
          foregroundColor: Colors.black,
          shape: const RoundedRectangleBorder(),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: 45,
      height: 45,
      child: ElevatedButton(
        onPressed: _onDelete,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF9F5D7),
          foregroundColor: Colors.black,
          shape: const RoundedRectangleBorder(),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: const Icon(Icons.backspace),
      ),
    );
  }
}
