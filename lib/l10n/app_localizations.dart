import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

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
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @myDetails.
  ///
  /// In en, this message translates to:
  /// **'My Details'**
  String get myDetails;

  /// No description provided for @manageProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile and farm information'**
  String get manageProfileDesc;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @landInformation.
  ///
  /// In en, this message translates to:
  /// **'Land Information'**
  String get landInformation;

  /// No description provided for @farmName.
  ///
  /// In en, this message translates to:
  /// **'Farm Name'**
  String get farmName;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @saveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get saveDetails;

  /// No description provided for @updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Details updated successfully!'**
  String get updateSuccess;

  /// No description provided for @errorEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get errorEnterName;

  /// No description provided for @errorEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get errorEnterPhone;

  /// No description provided for @errorEnterFarmName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your farm name'**
  String get errorEnterFarmName;

  /// No description provided for @errorEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter your location'**
  String get errorEnterLocation;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @postNewJob.
  ///
  /// In en, this message translates to:
  /// **'Post a New Job'**
  String get postNewJob;

  /// No description provided for @jobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find skilled workers for your cinnamon plantation needs'**
  String get jobSubtitle;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @jobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Cinnamon Harvester'**
  String get jobTitleHint;

  /// No description provided for @jobType.
  ///
  /// In en, this message translates to:
  /// **'Job Type'**
  String get jobType;

  /// No description provided for @selectJobType.
  ///
  /// In en, this message translates to:
  /// **'Select Job Type'**
  String get selectJobType;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job Description'**
  String get jobDescription;

  /// No description provided for @jobDescHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the cinnamon farming tasks required'**
  String get jobDescHint;

  /// No description provided for @plantationLocation.
  ///
  /// In en, this message translates to:
  /// **'Plantation Location'**
  String get plantationLocation;

  /// No description provided for @workersNeeded.
  ///
  /// In en, this message translates to:
  /// **'Number of Workers Needed'**
  String get workersNeeded;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @postJobButton.
  ///
  /// In en, this message translates to:
  /// **'Post Job'**
  String get postJobButton;

  /// No description provided for @yourPostedJobs.
  ///
  /// In en, this message translates to:
  /// **'Your Posted Jobs'**
  String get yourPostedJobs;

  /// No description provided for @noJobsPosted.
  ///
  /// In en, this message translates to:
  /// **'No jobs posted yet. Your new jobs will appear here.'**
  String get noJobsPosted;

  /// No description provided for @jobPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job posted successfully!'**
  String get jobPostedSuccess;

  /// No description provided for @loginToPost.
  ///
  /// In en, this message translates to:
  /// **'Please log in again to post a job.'**
  String get loginToPost;

  /// No description provided for @failedToPost.
  ///
  /// In en, this message translates to:
  /// **'Failed to post job'**
  String get failedToPost;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a job title'**
  String get errorTitle;

  /// No description provided for @errorDesc.
  ///
  /// In en, this message translates to:
  /// **'Please enter a job description'**
  String get errorDesc;

  /// No description provided for @errorLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter the plantation location'**
  String get errorLocation;

  /// No description provided for @errorWorkers.
  ///
  /// In en, this message translates to:
  /// **'Enter valid worker count'**
  String get errorWorkers;

  /// No description provided for @errorWage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid wage'**
  String get errorWage;

  /// No description provided for @harvesting.
  ///
  /// In en, this message translates to:
  /// **'Cinnamon Harvesting'**
  String get harvesting;

  /// No description provided for @cutting.
  ///
  /// In en, this message translates to:
  /// **'Cinnamon Cutting'**
  String get cutting;

  /// No description provided for @peeling.
  ///
  /// In en, this message translates to:
  /// **'Cinnamon Peeling'**
  String get peeling;

  /// No description provided for @scraping.
  ///
  /// In en, this message translates to:
  /// **'Cinnamon Scraping'**
  String get scraping;

  /// No description provided for @rolling.
  ///
  /// In en, this message translates to:
  /// **'Cinnamon Rolling'**
  String get rolling;
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
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
