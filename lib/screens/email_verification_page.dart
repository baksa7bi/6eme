import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:store_app/l10n/app_localizations.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isLoading = false;
  bool _isChecking = false;

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.resendVerificationEmail();
      if (mounted) {
        final success = response.containsKey('message') || response.containsKey('status');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Lien de vérification envoyé à votre adresse e-mail.' 
                : 'Échec de l\'envoi du lien.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);
    try {
      // Refresh user profile from API to check if email_verified_at is now set
      await context.read<AuthProvider>().refreshUser();
    } catch (e) {
      debugPrint('Error checking status: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 100,
                color: Colors.orange,
              ),
              const SizedBox(height: 30),
              const Text(
                'Vérification de l\'e-mail',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Un lien de vérification a été envoyé à :\n${auth.user?.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const Text(
                'Veuillez cliquer sur le lien dans l\'e-mail pour activer votre compte. Si vous ne le voyez pas, vérifiez votre dossier spam.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              if (_isChecking)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _checkVerificationStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('J\'ai vérifié mon e-mail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: _isLoading ? null : _resendVerificationEmail,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Renvoyer l\'e-mail de vérification', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              
              const Spacer(),
              
              // Logout block at bottom
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Se déconnecter', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  auth.logout();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
