import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/agency_provider.dart';
import '../providers/favorite_provider.dart';
import 'register_page.dart';
import 'package:store_app/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.login)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
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
                              context.read<FavoriteProvider>().loadFavoritesFromApi();
                              if (auth.pendingFavorite != null) {
                                context.read<FavoriteProvider>().toggleFavorite(auth.pendingFavorite!);
                                auth.setPendingFavorite(null);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Succès !')),
                                );
                              }
                              Navigator.pop(context); 
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erreur d\'authentification'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(AppLocalizations.of(context)!.login),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("OU"),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            // Social Login Buttons
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     _SocialButton(
            //       icon: FontAwesomeIcons.google,
            //       color: Colors.red,
            //       onPressed: () => context.read<AuthProvider>().signInWithGoogle(
            //         agencyProvider: context.read<AgencyProvider>()
            //       ).then((success) {
            //         if (success && mounted) Navigator.pop(context);
            //       }),
            //     ),
            //     _SocialButton(
            //       icon: FontAwesomeIcons.facebookF,
            //       color: Colors.blue[900]!,
            //       onPressed: () => context.read<AuthProvider>().signInWithFacebook(
            //         agencyProvider: context.read<AgencyProvider>()
            //       ).then((success) {
            //         if (success && mounted) Navigator.pop(context);
            //       }),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 24),
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _SocialButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: FaIcon(icon, color: color, size: 28),
      ),
    );
  }
}
