import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agency_provider.dart';
import '../providers/auth_provider.dart';
import 'agency_dashboard_page.dart';

class AgencyLoginPage extends StatefulWidget {
  const AgencyLoginPage({super.key});

  @override
  State<AgencyLoginPage> createState() => _AgencyLoginPageState();
}

class _AgencyLoginPageState extends State<AgencyLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    final success = await context.read<AgencyProvider>().login(
      _emailController.text.trim(),
      _passwordController.text,
      authProvider: context.read<AuthProvider>(),
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AgencyDashboardPage()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiants incorrects')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion Agence')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.business, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Agency'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Se Connecter'),
                  ),
          ],
        ),
      ),
    );
  }
}
