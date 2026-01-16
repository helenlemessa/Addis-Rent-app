// test_main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AddisRent Test',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AddisRent Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('App is working!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PropertyListScreen()),
                );
              },
              child: const Text('Go to Properties'),
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyListScreen extends StatelessWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Properties')),
      body: ListView(
        children: [
          ListTile(title: const Text('Property 1'), subtitle: const Text('Bole - ETB 10,000'), onTap: () {}),
          ListTile(title: const Text('Property 2'), subtitle: const Text('Megenagna - ETB 8,000'), onTap: () {}),
          ListTile(title: const Text('Property 3'), subtitle: const Text('Piassa - ETB 12,000'), onTap: () {}),
        ],
      ),
    );
  }
}