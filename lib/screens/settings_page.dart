import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/cart_provider.dart';
import 'app_drawer.dart';
import 'main_navigation.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

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
          const Text(
            'Mon Compte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Informations personnelles'),
            subtitle: Text(auth.user?.name ?? 'Non connecté'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (!auth.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez vous connecter d\'abord')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Sécurité et mot de passe'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (!auth.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez vous connecter d\'abord')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                );
              }
            },
          ),
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
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return BottomNavigationBar(
            currentIndex: 0,
            onTap: (index) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainNavigation()),
                (route) => false,
              );
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
              const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Cafés'),
              const BottomNavigationBarItem(icon: Icon(Icons.cake_outlined), label: 'Anniversaire'),
              const BottomNavigationBarItem(icon: Icon(Icons.event_outlined), label: 'Événements'),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text('${cart.itemCount}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      )
                  ],
                ),
                label: 'Panier',
              ),
            ],
          );
        },
      ),
    );
  }
}
