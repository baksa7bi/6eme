import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'login_page.dart';
import 'anniversary_page.dart';
import 'orders_page.dart';
import 'my_reservations_page.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'add_product_page.dart';
import 'add_event_page.dart';
import 'favorites_page.dart';
import 'settings_page.dart';

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
                _buildMenuItem(context, Icons.favorite_border, 'Mes favoris', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesPage()));
                }),
                _buildMenuItem(context, Icons.inventory_2_outlined, 'Mes Commandes', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersPage()));
                }),
                _buildMenuItem(context, Icons.event_note_outlined, 'Mes Réservations', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReservationsPage()));
                }),
                
                const Divider(),
                
                _buildMenuItem(context, Icons.settings_outlined, 'Paramètres', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                }),
                _buildMenuItem(context, Icons.brightness_6, 'Thème Sombre/Clair', () {
                   Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                }),
                _buildMenuItem(context, Icons.help_outline, 'Aide & Support', () {}),

                if (auth.isAuthenticated) ...[
                  if (auth.user?.isContentManager ?? false) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('GESTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    ),
                    _buildMenuItem(context, Icons.add_box_outlined, 'Ajouter un Produit', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage()));
                    }),
                    _buildMenuItem(context, Icons.event, 'Ajouter un Évènement', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEventPage()));
                    }),
                  ],
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
          // Instagram Icon
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: IconButton(
              icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.pink, size: 30),
              onPressed: () async {
                final Uri url = Uri.parse('https://www.instagram.com/6eme.cafe/');
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Impossible d\'ouvrir Instagram')),
                  );
                }
              },
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
