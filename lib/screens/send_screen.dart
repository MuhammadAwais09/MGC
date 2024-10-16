import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart' as flutter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:fast_base58/fast_base58.dart';
import 'package:dio/dio.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  flutter.State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends flutter.State<SendScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  String _senderWalletAddress = '';
  double _transactionFee = 0.00011070;
  String _privateKey = '';
  bool _isLoading = false;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSenderAddress();
  }

  Future<void> _loadSenderAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _senderWalletAddress = prefs.getString('address') ?? '';
        _privateKey = prefs.getString('privateKey') ?? '';
      });
    } catch (e) {
      _showErrorDialog('Error loading sender address: $e');
    }
  }

  void _confirmTransaction() async {
    if (_isLoading) return;

    final recipientAddress = _addressController.text.trim();
    final amountStr = _amountController.text.trim();

    if (recipientAddress.isEmpty || amountStr.isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    double amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0) {
      _showErrorDialog('Please enter a valid amount.');
      return;
    }

    if (_balance < _transactionFee + amount) {
      _showErrorDialog('Insufficient funds.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final transactionData = {
      'timestamp': DateTime.now().toString(),
      'senderAddress': _senderWalletAddress,
      'recipientAddress': recipientAddress,
      'amount': amount,
      'fee': _transactionFee,
      'memo': _memoController.text.isEmpty ? 'No Memo' : _memoController.text,
    };

    final txid = generateTransactionId(transactionData);
    final signedTransaction = await signTransaction(transactionData, _privateKey);

    try {
      await broadcastTransaction(signedTransaction, txid);
    } catch (e) {
      _showErrorDialog('Error sending payment: $e');
    }
  }

  String generateTransactionId(Map<String, dynamic> transactionData) {
    final dataToHash = json.encode(transactionData);
    final bytes = utf8.encode(dataToHash);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> signTransaction(Map<String, dynamic> transactionData, String privateKeyHex) async {
    final dataToSign = json.encode(transactionData);
    final bytes = utf8.encode(dataToSign);

    // Convert the private key from hex to bytes
    final privateKeyBytes = _hexToBytes(privateKeyHex);

    // Create the signing key from the private key
    final curve = ECCurve_secp256k1();
    final domain = ECDomainParameters(curve as String);
    final privateKey = PrivateKeyParameter<ECPrivateKey>(
      ECPrivateKey(
        domain as BigInt?,
        BigInt.from(privateKeyBytes as num) as ECDomainParameters?,
      ),
    );

    // Create the signer instance
    final signer = ECDSASigner(SHA256Digest());
    signer.init(true, privateKey);

    // Sign the data
    final signature = signer.generateSignature(Uint8List.fromList(bytes));

    // Return the signature in hex format
    return signature.toString(); // Adjust as necessary to get the right format
  }
  Uint8List _hexToBytes(String hex) {
    final buffer = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      buffer[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return buffer;
  }

  Future<void> broadcastTransaction(String signedTransaction, String txid) async {
    final url = 'http://golduser1231:myhitshop123451@149.28.156.155:8096/';
    try {
      final dio = Dio(); // Create a dio instance
      final response = await dio.post(
        url,
        data: json.encode({
          'json rpc': '2.0',
          'id': 'curltest',
          'method': 'sendrawtransaction',
          'params': [signedTransaction],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
        _showSuccessDialog('Payment sent successfully!');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error sending payment: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error sending payment: $e');
    }
  }


  void _addFunds() async {
    final url = 'http://golduser1231:myhitshop123451@149.28.156.155:8096/';
    try {
      final prefs = await SharedPreferences.getInstance();
      final address = prefs.getString('address') ?? '';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'jsonrpc': '2.0',
          'id': 'curltest',
          'method': 'generatetoaddress',
          'params': [
            1, // Number of blocks to generate
            address,
          ],
        }),
      );
      _showSuccessDialog('Your fund will be processed in 10 minutes.');
      if (response.statusCode == 200) {
        _showSuccessDialog('Your fund updated successfully.');
      } else {
        _showErrorDialog('Error adding funds: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error adding funds: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: <Widget >[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Coins'),
      ),
      body: flutter.Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Recipient Address',
              ),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (MGC)',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'Memo (Optional)',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _confirmTransaction,
              child: const Text('Send Coins'),
            ),
            const SizedBox(height: 8.0),
            Container(
              margin: const EdgeInsets.only(top: 30.0),
              child: Text(
                'Please note that it may take up to 10 minutes for the funds to be updated, depending on your internet speed.',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _addFunds,
              child: const Text('Add Funds'),
            ),
          ],
        ),
      ),
    );
  }
}