import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import 'login_page.dart';
import 'main_navigation.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Provider.of<NavigationProvider>(context, listen: false).mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Profil'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: auth.isAuthenticated 
        ? _buildUserProfile(context, auth) 
        : _buildLoginPrompt(context),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: 30),
              child: ElevatedButton(
                onPressed: () {
                  Provider.of<NavigationProvider>(context, listen: false).pushOnCurrentTab(context, const LoginPage());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            _buildMenuSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Theme.of(context).primaryColor,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(auth.user?.name ?? 'Utilisateur', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(auth.user?.email ?? '', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        Expanded(child: _buildMenuSection(context, isLogged: true)),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, {bool isLogged = false}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 10),
        _buildMenuItem(Icons.favorite_border, 'Mes favoris'),
        _buildMenuItem(Icons.inventory_2_outlined, 'Catégories'),
        
        const SizedBox(height: 20),
        const Text('PARAMÈTRES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 10),
        _buildMenuItem(Icons.description_outlined, 'Politique de confidentialité'),
        _buildMenuItem(Icons.settings_outlined, 'Paramètre', onTap: () {
           Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        }),
        _buildMenuItem(Icons.help_outline, 'Aide'),

        if (isLogged) ...[
          const SizedBox(height: 20),
          _buildMenuItem(Icons.logout, 'Se déconnecter', color: Colors.red, onTap: () {
            Provider.of<AuthProvider>(context, listen: false).logout();
            Provider.of<CartProvider>(context, listen: false).clear();
            Provider.of<NavigationProvider>(context, listen: false).setSelectedIndex(0);
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavigation()), (route) => false);
          }),
        ],

        const SizedBox(height: 30),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('CMI', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            const Text('BIENTÔT\nDISPONIBLE', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Color color = Colors.black54, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color == Colors.black54 ? Colors.blue : color),
      title: Text(title, style: TextStyle(color: color == Colors.black54 ? Colors.black87 : color)),
      onTap: onTap ?? () {},
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
