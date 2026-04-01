import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/main_navigation.dart';
import 'providers/theme_provider.dart';
import 'providers/order_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/home_provider.dart';
import 'providers/agency_provider.dart';
import 'providers/notification_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:store_app/l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/navigation_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await NotificationService.initialize();
  await initializeDateFormatting('fr_FR', null);

  // Create AuthProvider early so we can restore the session before showing UI
  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        // Use the already-initialized authProvider (with session restored)
        ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => AgencyProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const CafeApp(),
    ),
  );
}

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: '6eme app',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
        Locale('ar', ''),
      ],
      builder: (context, child) {
        // Enforce RTL for Arabic
        return Directionality(
          textDirection: localeProvider.locale.languageCode == 'ar' 
              ? TextDirection.rtl 
              : TextDirection.ltr,
          child: child!,
        );
      },
      home: const MainNavigation(),
    );
  }
}
