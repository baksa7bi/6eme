import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'6eme App'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @cafes.
  ///
  /// In en, this message translates to:
  /// **'Cafes'**
  String get cafes;

  /// No description provided for @anniversary.
  ///
  /// In en, this message translates to:
  /// **'Anniversary'**
  String get anniversary;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a product...'**
  String get searchHint;

  /// No description provided for @unreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'unread notifications'**
  String get unreadNotifications;

  /// No description provided for @ourEstablishments.
  ///
  /// In en, this message translates to:
  /// **'Our Establishments'**
  String get ourEstablishments;

  /// No description provided for @noCafesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No cafes available'**
  String get noCafesAvailable;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @ourHistory.
  ///
  /// In en, this message translates to:
  /// **'Our History'**
  String get ourHistory;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @qualitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Selected beans'**
  String get qualitySubtitle;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @serviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fast & Smiling'**
  String get serviceSubtitle;

  /// No description provided for @freshness.
  ///
  /// In en, this message translates to:
  /// **'Freshness'**
  String get freshness;

  /// No description provided for @freshnessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local roasting'**
  String get freshnessSubtitle;

  /// No description provided for @joinClub.
  ///
  /// In en, this message translates to:
  /// **'Join the Club'**
  String get joinClub;

  /// No description provided for @joinClubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earn points and enjoy exclusive offers.'**
  String get joinClubSubtitle;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @modifyProduct.
  ///
  /// In en, this message translates to:
  /// **'Modify Product'**
  String get modifyProduct;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @coldDrinks.
  ///
  /// In en, this message translates to:
  /// **'Cold Drinks'**
  String get coldDrinks;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @iceCream.
  ///
  /// In en, this message translates to:
  /// **'Ice Cream'**
  String get iceCream;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'MANAGEMENT'**
  String get management;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// No description provided for @activeCoupons.
  ///
  /// In en, this message translates to:
  /// **'Active Coupons'**
  String get activeCoupons;

  /// No description provided for @visitsCommissions.
  ///
  /// In en, this message translates to:
  /// **'Visites & Commissions'**
  String get visitsCommissions;

  /// No description provided for @manageAgencies.
  ///
  /// In en, this message translates to:
  /// **'Manage Agencies'**
  String get manageAgencies;

  /// No description provided for @addManager.
  ///
  /// In en, this message translates to:
  /// **'Add Manager'**
  String get addManager;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @experienceTitle.
  ///
  /// In en, this message translates to:
  /// **'THE 6ÈME CAFÉ EXPERIENCE'**
  String get experienceTitle;

  /// No description provided for @experienceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'More than just a coffee, a meeting place where passion for taste meets art of living. Discover an exceptional selection of beans and a unique atmosphere.'**
  String get experienceSubtitle;

  /// No description provided for @ourCommitments.
  ///
  /// In en, this message translates to:
  /// **'Our Commitments'**
  String get ourCommitments;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @confirmOrderBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to confirm your order on site at {cafeName}?'**
  String confirmOrderBody(Object cafeName);

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @orderValidated.
  ///
  /// In en, this message translates to:
  /// **'Your order has been validated. You will receive a receipt shortly.'**
  String get orderValidated;

  /// No description provided for @viewMyOrders.
  ///
  /// In en, this message translates to:
  /// **'View My Orders'**
  String get viewMyOrders;

  /// No description provided for @chooseThisCafe.
  ///
  /// In en, this message translates to:
  /// **'Choose this cafe'**
  String get chooseThisCafe;

  /// No description provided for @seeMenu.
  ///
  /// In en, this message translates to:
  /// **'See Menu'**
  String get seeMenu;

  /// No description provided for @noCafesFound.
  ///
  /// In en, this message translates to:
  /// **'No cafes found'**
  String get noCafesFound;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @themeToggle.
  ///
  /// In en, this message translates to:
  /// **'Dark/Light Theme'**
  String get themeToggle;

  /// No description provided for @logoutAgency.
  ///
  /// In en, this message translates to:
  /// **'Logout Agency'**
  String get logoutAgency;

  /// No description provided for @instagramError.
  ///
  /// In en, this message translates to:
  /// **'Impossible to open Instagram'**
  String get instagramError;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @reserveTable.
  ///
  /// In en, this message translates to:
  /// **'Reserve a table'**
  String get reserveTable;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'added to cart'**
  String get addedToCart;

  /// No description provided for @welcomeGift.
  ///
  /// In en, this message translates to:
  /// **'Welcome Gift'**
  String get welcomeGift;

  /// No description provided for @claimNow.
  ///
  /// In en, this message translates to:
  /// **'Claim Now'**
  String get claimNow;

  /// No description provided for @alreadyClaimed.
  ///
  /// In en, this message translates to:
  /// **'Welcome gift already claimed on this device'**
  String get alreadyClaimed;

  /// No description provided for @congratsGift.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You received a welcome coupon.'**
  String get congratsGift;

  /// No description provided for @myCoupons.
  ///
  /// In en, this message translates to:
  /// **'My Coupons'**
  String get myCoupons;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @myReservations.
  ///
  /// In en, this message translates to:
  /// **'My Reservations'**
  String get myReservations;

  /// No description provided for @loginToAcquire.
  ///
  /// In en, this message translates to:
  /// **'Please login to acquire a coupon'**
  String get loginToAcquire;

  /// No description provided for @receiptAmount.
  ///
  /// In en, this message translates to:
  /// **'Receipt Amount'**
  String get receiptAmount;

  /// No description provided for @enterTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter the total receipt amount'**
  String get enterTotalAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @requestSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request sent successfully!'**
  String get requestSentSuccess;

  /// No description provided for @inProgressRequests.
  ///
  /// In en, this message translates to:
  /// **'In-progress requests'**
  String get inProgressRequests;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @noCouponsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No coupons available'**
  String get noCouponsAvailable;

  /// No description provided for @submitFiveTickets.
  ///
  /// In en, this message translates to:
  /// **'Submit 5 receipt photos to get a free coupon!'**
  String get submitFiveTickets;

  /// No description provided for @acquireCoupon.
  ///
  /// In en, this message translates to:
  /// **'Acquire a Coupon'**
  String get acquireCoupon;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
