import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'login_page.dart';
import 'anniversary_page.dart';
import 'orders_page.dart';
import 'my_reservations_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            color: theme.primaryColor,
            child: auth.isAuthenticated 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      auth.user?.name ?? 'Utilisateur',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      auth.user?.email ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                )
              : Column(
                  children: [
                     const Icon(Icons.account_circle, size: 60, color: Colors.white),
                     const SizedBox(height: 10),
                     const Text('Bienvenue !', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 16),
                     ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(context, Icons.home, 'Accueil', () {
                  Navigator.pop(context); // Close drawer, already on home or main nav
                  // Ideally navigate to tab 0 if using a global key for MainNavigation, but for now just closing is fine
                }),
                _buildMenuItem(context, Icons.favorite_border, 'Mes favoris', () {}),
                _buildMenuItem(context, Icons.inventory_2_outlined, 'Mes Commandes', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersPage()));
                }),
                _buildMenuItem(context, Icons.event_note_outlined, 'Mes Réservations', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReservationsPage()));
                }),
                
                const Divider(),
                
                _buildMenuItem(context, Icons.settings_outlined, 'Paramètres', () {}),
                _buildMenuItem(context, Icons.brightness_6, 'Thème Sombre/Clair', () {
                   Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                }),
                _buildMenuItem(context, Icons.help_outline, 'Aide & Support', () {}),
                _buildMenuItem(context, Icons.info_outline, 'À propos', () {}),

                if (auth.isAuthenticated) ...[
                  const Divider(),
                  _buildMenuItem(context, Icons.logout, 'Se déconnecter', () {
                    auth.logout();
                    Navigator.pop(context);
                  }, color: Colors.red),
                ],
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Version 1.0.0', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? color}) {
    final theme = Theme.of(context);
    final textColor = color ?? theme.textTheme.bodyLarge?.color;
    final iconColor = color ?? theme.iconTheme.color;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
    );
  }
}
