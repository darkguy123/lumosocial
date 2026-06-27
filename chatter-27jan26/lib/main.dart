import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LumoApp());
}

class LumoApp extends StatelessWidget {
  const LumoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumo Social',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xff66fcf1),
        scaffoldBackgroundColor: const Color(0xff0b0c10),
      ),
      home: const LumoLoginScreen(),
    );
  }
}

class LumoLoginScreen extends StatefulWidget {
  const LumoLoginScreen({super.key});

  @override
  State<LumoLoginScreen> createState() => _LumoLoginScreenState();
}

class _LumoLoginScreenState extends State<LumoLoginScreen> {
  final _identityController = TextEditingController();
  bool _loading = false;
  String _message = "";

  Future<void> _handleRegisterUser() async {
    setState(() {
      _loading = true;
      _message = "";
    });

    try {
      final response = await http.post(
        Uri.parse("https://social.equipmentmarket.ng/api/addUser"),
        headers: {
          "Content-Type": "application/json",
          "apikey": "123",
        },
        body: jsonEncode({
          "identity": _identityController.text,
          "login_type": 1,
          "device_type": 0, // Android
          "device_token": "android_token_placeholder",
          "full_name": "Lumo Android User",
        }),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == true || data['message'] == "User already exists") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_identity", _identityController.text);
        
        setState(() {
          _message = "Connected to Lumo Social successfully!";
        });
      } else {
        setState(() {
          _message = data['message'] ?? "Connection failed";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Network error connecting to backend";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Lumo Social",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Always be there, even when far away",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _identityController,
                decoration: const InputDecoration(
                  labelText: "Enter Username or Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _handleRegisterUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xff6366f1),
                ),
                child: _loading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Connect to Backend", style: TextStyle(fontSize: 16)),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(_message, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
