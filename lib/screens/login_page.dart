import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/agency_provider.dart';
import '../providers/favorite_provider.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Se connecter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.lock_person, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            final success = await auth.login(
                              _emailController.text,
                              _passwordController.text,
                              agencyProvider: context.read<AgencyProvider>(),
                            );
                            if (success && mounted) {
                              // Refresh favorites for the logged in user
                              context.read<FavoriteProvider>().loadFavoritesFromApi();
                              
                              // Handle pending favorite
                              if (auth.pendingFavorite != null) {
                                context.read<FavoriteProvider>().toggleFavorite(auth.pendingFavorite!);
                                auth.setPendingFavorite(null); // Clear it
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Article ajouté aux favoris !')),
                                );
                              }
                              Navigator.pop(context); 
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('L\'email ou le mot de passe est incorrect.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Se connecter'),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('Pas de compte ? S\'inscrire ici'),
            ),
          ],
        ),
      ),
    );
  }
}
