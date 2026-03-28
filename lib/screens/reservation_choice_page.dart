import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_app/l10n/app_localizations.dart';
import 'anniversary_page.dart';
import 'cafes_page.dart';
import 'app_drawer.dart';
import '../providers/navigation_provider.dart';

class ReservationChoicePage extends StatefulWidget {
  const ReservationChoicePage({super.key});

  @override
  State<ReservationChoicePage> createState() => _ReservationChoicePageState();
}

class _ReservationChoicePageState extends State<ReservationChoicePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildChoiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      // Drawer is now in MainNavigation
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Provider.of<NavigationProvider>(context, listen: false).mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Réservations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Que souhaitez-vous réserver ?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: _buildChoiceCard(
                  context,
                  title: l10n.anniversary, // Usually "Anniversaire" 
                  subtitle: 'Organiser un événement mémorable (Anniversaire...).',
                  icon: Icons.cake,
                  color: Colors.pinkAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnniversaryPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _buildChoiceCard(
                  context,
                  title: 'Réserver une table',
                  subtitle: 'Réserver une table dans l\'un de nos cafés.',
                  icon: Icons.restaurant,
                  color: theme.primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CafesPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
