import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:manhattangoldcoin/screens/security_screen.dart';
import 'faqs_screen.dart';
import 'main_screen.dart';
import 'send_screen.dart'; // Import the SendScreen file
import 'receive_screen.dart'; // Import the ReceiveScreen file
import 'buy_screen.dart'; // Import the BuyScreen file
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class HomeScreen extends StatefulWidget {
  final String privateKey;
  final String publicKey;
  final String address;
  final String seedPhrase;

  const HomeScreen({
    Key? key,
    required this.privateKey,
    required this.publicKey,
    required this.address,
    required this.seedPhrase,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isWalletLocked = false; // Track wallet lock state
  double _balance = 0.0; // Store the balance
  bool _isLoading = true; // To indicate loading state
  bool _isWalletSynced = false;
  int _syncProgress = 0;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    _syncWallet();
  }


  Future<List<List<dynamic>>> fetchAddressTxs(String address) async {
    final url = Uri.parse(
        'https://explorer.manhattangoldcoin.com/ext/getaddresstxsajax/$address?draw=1&columns%5B0%5D%5Bdata%5D=0&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=false&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=1&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=false&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B2%5D%5Bdata%5D=2&columns%5B2%5D%5Bname%5D=&columns%5B2%5D%5Bsearchable%5D=true&columns%5B2%5D%5Borderable%5D=false&columns%5B2%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B2%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B3%5D%5Bdata%5D=3&columns%5B3%5D%5Bname%5D=&columns%5B3%5D%5Bsearchable%5D=true&columns%5B3%5D%5Borderable%5D=false&columns%5B3%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B3%5D%5Bsearch%5D%5Bregex%5D=false&start=0&length=50&search%5Bvalue%5D=&search%5Bregex%5D=false&_=1728371423664');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final data = jsonResponse['data'] as List<dynamic>;
      return data.map((e) => e as List<dynamic>).toList();
    } else {
      throw Exception('Failed to load address transactions');
    }
  }


  void _syncWallet() async {
    final url =
        'http://golduser1231:myhitshop123451@149.28.156.155:8096/';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'jsonrpc': '2.0',
          'id': 'curltest',
          'method': 'getblockchaininfo',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final blockchainInfo = json.decode(response.body);
        final blockCount = blockchainInfo['result']['blocks'];

        setState(() {
          _syncProgress = 0;
        });

        await _syncBlocks(blockCount);
      } else {
        _showErrorDialog('Error syncing wallet: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error syncing wallet: $e');
    }
  }

  Future<void> _syncBlocks(int blockCount) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/wallet_data.json');

    // Check if the file already exists and load the existing data
    List<Map<String, dynamic>> blocks = [];
    if (await file.exists()) {
      final jsonData = await file.readAsString();
      blocks = jsonDecode(jsonData).cast<Map<String, dynamic>>();
    }

    // Find the last synced block index
    int lastSyncedBlockIndex = blocks.length;

    for (int i = lastSyncedBlockIndex; i < blockCount; i++) {
      final blockHash = await _getBlockHash(i);
      if (blockHash != null) {
        final blockData = await _getBlock(blockHash);
        if (blockData != null) {
          blocks.add(blockData);

          // Store the synced wallet data to a JSON file
          await file.writeAsString(jsonEncode(blocks));

          setState(() {
            _syncProgress = (((i + 1) / blockCount) * 100).floor();
          });
        }
      }
    }

    setState(() {
      _isWalletSynced = true; // Update wallet sync status
      _syncProgress = 100;
    });
  }
  Future<String?> _getBlockHash(int blockNumber) async {
    final url = 'http://golduser1231:myhitshop123451@149.28.156.155:8096/';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'jsonrpc': '2.0',
          'id': 'curltest',
          'method': 'getblockhash',
          'params': [blockNumber],
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body)['result'];
      } else if (response.statusCode == 404) {
        _showErrorDialog('Block not found');
        return null;
      } else {
        _showErrorDialog('Error getting block hash: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _showErrorDialog('Error getting block hash: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getBlock(String blockHash) async {
    final url = 'http://golduser1231:myhitshop123451@149.28.156.155:8096/';
    try {
      final response = await http.post(
        Uri.parse(url ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'jsonrpc': '2.0',
          'id': 'curltest',
          'method': 'getblock',
          'params': [blockHash],
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body)['result'];
      } else if (response.statusCode == 404) {
        _showErrorDialog('Block not found');
        return null;
      } else {
        _showErrorDialog('Error getting block data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _showErrorDialog('Error getting block data: $e');
      return null;
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



  // Fetch the wallet balance using the provided API
  Future<void> _fetchBalance() async {
    final apiUrl = 'https://explorer.manhattangoldcoin.com/ext/getbalance/${widget.address}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final balanceString = response.body.trim();
        final balance = double.parse(balanceString);

        // Store the balance in SharedPreferences synchronously
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('balance', balance.toStringAsFixed(8));

        setState(() {
          _balance = balance;
          _isLoading = false;
        });
      } else {
        setState(() {
          _balance = 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _balance = 0.0;
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 1: // "Send" button tapped
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SendScreen()),
          );
          break;
        case 2: // "Receive" button tapped
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReceiveScreen(walletAddress: widget.address)),
          );
          break;
        case 3: // "Buy" button tapped
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BuyScreen()),
          );
          break;
      }
    });
  }

  void _lockWallet() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lock Wallet'),
          content: const Text('Do you want to lock the wallet? '),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                setState(() {
                  _isWalletLocked = true; // Lock the wallet
                });
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _unlockWallet() {
    setState(() {
      _isWalletLocked = false; // Unlock the wallet
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manhattan Gold Coin Wallet'),
        backgroundColor: const Color(0xFFF9F5D7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _showBottomDialog();
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: _isWalletLocked ? _buildLockedWallet() : _buildHomeContent(),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem('History', Icons.history, 0),
            _buildBottomNavItem('Send', Icons.send, 1),
            _buildBottomNavItem('Receive', Icons.arrow_downward, 2),
            _buildBottomNavItem('Buy', Icons.shopping_cart, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F5D7),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Balance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _isLoading
                    ? const CircularProgressIndicator()
                    : Row(
                  children: [
                    Image.asset(
                      'assets/icons/icon3.jpeg', // Path to your asset icon
                      width: 36, // Set the size of the icon
                      height: 36,
                      // Optional: to change the icon color
                    ),
                    const SizedBox(width: 8), // Space between icon and balance
                    Text(
                      '$_balance', // Display fetched balance
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Important: Save your Seed Phrase!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This seed phrase is your only way to access your wallet. Make sure to store it in a secure place and do not share it with anyone.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            widget.seedPhrase, // Assuming `seedPhrase` is passed to this widget
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center, // Center the seed phrase for better readability
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.seedPhrase));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seed Phrase copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Seed Phrase'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9F5D7),
              foregroundColor: Colors.black,
            ),
          ),
          // const SizedBox(height: 8),
          // Text(
          //   widget.publicKey,
          //   style: const TextStyle(fontSize: 14, color: Colors.black54),
          // ),
          const SizedBox(height: 24),
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder(
              future: fetchAddressTxs(widget.address),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final transactions = snapshot.data as List<List<dynamic>>;
                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final amount = transaction[2] as int; // Change to int
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.black,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // title: Text('#${index + 1}'),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(amount / 100000000).toStringAsFixed(8)} MGC', // Display amount in MGC
                                style: const TextStyle(color: Colors.red),
                              ),
                              Text(
                                '${transaction[0]}', // Display date and time
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          _isWalletSynced
              ? const Text('Wallet synced successfully!')
              : Text('Syncing wallet... ($_syncProgress%)'),
        ],
      ),
    );
  }

  Widget _buildLockedWallet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    });

    return Container();
  }

  void _showBottomDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: const Color(0xFFF9F5D7),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.security, color: Colors.black),
                title: const Text('Security Center'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecurityScreen()), // Navigate to SecurityScreen
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent, color: Colors.black),
                title: const Text('Customer Support'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FAQsScreen()), // Navigate to FaqScreen
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.black),
                title: const Text('Lock Wallet'),
                onTap: () {
                  Navigator.pop(context);
                  _lockWallet();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavItem(String label, IconData icon, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index ? Colors.black : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: _selectedIndex == index ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}