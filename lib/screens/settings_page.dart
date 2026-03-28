import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/agency_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'app_drawer.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _notificationsEnabled = true;

  // ── User change-password dialog ─────────────────────────────────────────
  void _showUserChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.blue),
              SizedBox(width: 8),
              Text('Changer le mot de passe'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentCtrl,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                          () => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: const Text('Enregistrer'),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (currentCtrl.text.isEmpty ||
                          newCtrl.text.isEmpty ||
                          confirmCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Veuillez remplir tous les champs')),
                        );
                        return;
                      }
                      final password = newCtrl.text;
                      final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
                      final hasNumber = password.contains(RegExp(r'[0-9]'));
                      if (password.length < 8 || !hasLetter || !hasNumber) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Le nouveau mot de passe doit contenir au moins 8 caractères, dont une lettre et un chiffre.')),
                        );
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Les mots de passe ne correspondent pas')),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final result = await ApiService.changeUserPassword(
                          currentCtrl.text,
                          newCtrl.text,
                        );

                        if (!mounted) return;
                        Navigator.pop(ctx);

                        final isError = result.containsKey('errors') ||
                            (result['message'] != null &&
                                result['message']
                                    .toString()
                                    .toLowerCase()
                                    .contains('incorrect'));

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ??
                                (isError
                                    ? 'Erreur lors du changement de mot de passe'
                                    : 'Mot de passe mis à jour avec succès ✓')),
                            backgroundColor:
                                isError ? Colors.red : Colors.green,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur de connexion au serveur'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ── Agency change-password dialog ────────────────────────────────────────
  void _showAgencyChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.blue),
              SizedBox(width: 8),
              Text('Changer le mot de passe'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current password
                TextField(
                  controller: currentCtrl,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                          () => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // New password
                TextField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Confirm new password
                TextField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: const Text('Enregistrer'),
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validation
                      if (currentCtrl.text.isEmpty ||
                          newCtrl.text.isEmpty ||
                          confirmCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Veuillez remplir tous les champs')),
                        );
                        return;
                      }
                      final password = newCtrl.text;
                      final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
                      final hasNumber = password.contains(RegExp(r'[0-9]'));
                      if (password.length < 8 || !hasLetter || !hasNumber) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Le nouveau mot de passe doit contenir au moins 8 caractères, dont une lettre et un chiffre.')),
                        );
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Les mots de passe ne correspondent pas')),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final result = await ApiService.changeAgencyPassword(
                          currentCtrl.text,
                          newCtrl.text,
                        );

                        if (!mounted) return;
                        Navigator.pop(ctx);

                        final isError = result.containsKey('errors') ||
                            (result['message'] != null &&
                                result['message']
                                    .toString()
                                    .toLowerCase()
                                    .contains('incorrect'));

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ??
                                (isError
                                    ? 'Erreur lors du changement de mot de passe'
                                    : 'Mot de passe mis à jour avec succès ✓')),
                            backgroundColor:
                                isError ? Colors.red : Colors.green,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur de connexion au serveur'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final agencyProvider = Provider.of<AgencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final isAgency = agencyProvider.isAgencyAuthenticated;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Préférences de l\'application',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Mode Sombre'),
            subtitle: const Text('Activer ou désactiver le thème sombre'),
            secondary: const Icon(Icons.brightness_6),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (bool value) {
              themeProvider.toggleTheme();
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Recevoir des alertes et promotions'),
            secondary: const Icon(Icons.notifications_active),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(height: 32),

          // ── Account section ──────────────────────────────────────────────
          const Text(
            'Mon Compte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (isAgency) ...[
            // Agency account info (read-only display)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.business, color: Colors.white),
              ),
              title: Text(
                agencyProvider.agency?.name ?? 'Agence',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(agencyProvider.agency?.email ?? ''),
            ),
            const SizedBox(height: 8),
            // Change password tile for agency
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.blue),
              title: const Text('Changer le mot de passe'),
              subtitle: const Text('Modifier le mot de passe de votre compte agence'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showAgencyChangePasswordDialog,
            ),
          ] else ...[
            // Regular user tiles
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Informations personnelles'),
              subtitle: Text(auth.user?.name ?? 'Non connecté'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                if (!auth.isAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Veuillez vous connecter d\'abord')),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditProfilePage()),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Sécurité et mot de passe'),
              subtitle: const Text('Modifier votre mot de passe'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                if (!auth.isAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Veuillez vous connecter d\'abord')),
                  );
                } else {
                  _showUserChangePasswordDialog();
                }
              },
            ),
          ],

          const Divider(height: 32),
          const Text(
            'À propos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Conditions d\'utilisation'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
     
    );
  }
}
