import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/favorite_provider.dart';
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
import 'add_manager_page.dart';
import 'settings_page.dart';
import 'coupons_page.dart';
import 'manager_coupons_page.dart';
import 'agencies_page.dart';
import 'agency_login_page.dart';
import 'agency_dashboard_page.dart';
import 'admin_agency_visits_page.dart';
import '../providers/agency_provider.dart';
import '../providers/locale_provider.dart';
import 'package:store_app/l10n/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final agencyProvider = Provider.of<AgencyProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
              : agencyProvider.isAgencyAuthenticated
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.business, size: 36, color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      agencyProvider.agency?.name ?? 'Agence',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      agencyProvider.agency?.email ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Compte Agence', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                )
              : Column(
                  children: [
                    const Icon(Icons.account_circle, size: 60, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(l10n.welcome, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(l10n.login),
                    ),
                  ],
                ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(context, Icons.home, l10n.home, () {
                  Navigator.pop(context);
                }),
                if (auth.isAuthenticated) ...[
                  _buildMenuItem(context, Icons.favorite_border, l10n.favorites, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesPage()));
                  }),
                  _buildMenuItem(context, Icons.confirmation_num_outlined, l10n.myCoupons, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CouponsPage()));
                  }),
                  _buildMenuItem(context, Icons.inventory_2_outlined, l10n.myOrders, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersPage()));
                  }),
                  _buildMenuItem(context, Icons.event_note_outlined, l10n.myReservations, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReservationsPage()));
                  }),
                ],
                
                _buildMenuItem(context, Icons.cake_outlined, l10n.anniversary, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AnniversaryPage()));
                }),
                _buildMenuItem(context, Icons.event, l10n.events, () {
                  // If there is an events list page, push it here
                  // For now, let's just keep the events icon for consistency
                }),
                
                const Divider(),
                _buildMenuItem(context, Icons.settings_outlined, l10n.settings, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                }),
                _buildMenuItem(context, Icons.brightness_6, l10n.themeToggle, () {
                   context.read<ThemeProvider>().toggleTheme();
                }),
                _buildMenuItem(context, Icons.help_outline, l10n.helpSupport, () {}),

                if (auth.isAuthenticated) ...[
                  if ((auth.user?.isContentManager ?? false) || (auth.user?.isManager ?? false)) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(l10n.management, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    ),
                    _buildMenuItem(context, Icons.add_box_outlined, l10n.addProduct, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage()));
                    }),
                    _buildMenuItem(context, Icons.event, l10n.addEvent, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEventPage()));
                    }),
                    if ((auth.user?.isManager ?? false) || (auth.user?.isAdmin ?? false))
                      _buildMenuItem(context, Icons.confirmation_number, l10n.activeCoupons, () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagerCouponsPage()));
                      }),
                    if ((auth.user?.isManager ?? false) || (auth.user?.isAdmin ?? false))
                      _buildMenuItem(context, Icons.receipt_long, l10n.visitsCommissions, () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAgencyVisitsPage()));
                      }),
                    if (auth.user?.isAdmin ?? false) ...[
                      _buildMenuItem(context, Icons.business, l10n.manageAgencies, () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AgenciesPage()));
                      }),
                      _buildMenuItem(context, Icons.person_add, l10n.addManager, () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddManagerPage()));
                      }),
                    ],
                  ],
                  const Divider(),
                  _buildMenuItem(context, Icons.logout, l10n.logout, () {
                    auth.logout();
                    context.read<FavoriteProvider>().clearFavorites();
                    Navigator.pop(context);
                  }, color: Colors.red),
                ],

                // ── Agency logout (shown only when agency is logged in) ───
                if (agencyProvider.isAgencyAuthenticated) ...[
                  const Divider(),
                  _buildMenuItem(context, Icons.logout, l10n.logoutAgency, () {
                    agencyProvider.logout();
                    Navigator.pop(context);
                  }, color: Colors.red),
                ],
              ],
            ),
          ),
          
          
          // Bottom section with Instagram in Middle and Language Dropdown on Right
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                // Left filler to help center the middle item
                const Expanded(child: SizedBox()),
                
                // Instagram icon in the middle
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.pink, size: 28),
                  onPressed: () async {
                    final Uri url = Uri.parse('https://www.instagram.com/6eme.cafe/');
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.instagramError)),
                      );
                    }
                  },
                ),
                
                // Language switcher dropdown on the right
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: localeProvider.locale.languageCode,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              localeProvider.setLocale(Locale(newValue));
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'fr', child: Text('FR')),
                            DropdownMenuItem(value: 'en', child: Text('EN')),
                            DropdownMenuItem(value: 'ar', child: Text('AR')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
