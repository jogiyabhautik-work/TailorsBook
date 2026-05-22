import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context, [Type? type]) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ─── Supported locales (English, Hindi, Gujarati only) ──────────────────────
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('gu'), // Gujarati
  ];

  // ─── Language display names ────────────────────────────────────────────────
  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
    'gu': 'ગુજરાતી (Gujarati)',
  };

  Map<String, String>? _localizedStrings;
  static Map<String, String>? _fallbackStrings;

  Future<void> loadJson() async {
    // Load current language JSON
    try {
      String jsonString = await rootBundle.loadString('assets/l10n/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      debugPrint('Error loading localization for ${locale.languageCode}: $e');
      _localizedStrings = {};
    }

    // Load English fallback if current is not English and fallback is not loaded yet
    if (locale.languageCode != 'en' && _fallbackStrings == null) {
      try {
        String jsonString = await rootBundle.loadString('assets/l10n/en.json');
        Map<String, dynamic> jsonMap = json.decode(jsonString);
        _fallbackStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      } catch (e) {
        debugPrint('Error loading English fallback: $e');
        _fallbackStrings = {};
      }
    }
  }

  static Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.loadJson();
    return localizations;
  }

  String translate(String key, [Map<String, String>? params]) {
    String text = '';
    if (_localizedStrings != null && _localizedStrings!.containsKey(key)) {
      text = _localizedStrings![key]!;
    }
    if ((text.isEmpty) && locale.languageCode != 'en') {
      if (_fallbackStrings != null && _fallbackStrings!.containsKey(key)) {
        text = _fallbackStrings![key]!;
      }
    }
    if (text.isEmpty) text = key;

    if (params != null) {
      params.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }

  String _t(String key) => translate(key);

  // ─── Getters ───────────────────────────────────────────────────────────────
  String get appName => _t('app_name');
  String get welcomeBack => _t('welcome_back');
  String get loginSubtitle => _t('login_subtitle');
  String get email => _t('email');
  String get password => _t('password');
  String get forgotPassword => _t('forgot_password');
  String get login => _t('login');
  String get newToApp => _t('new_to_app');
  String get registerNow => _t('register_now');
  String get createProfile => _t('create_profile');
  String get registerSubtitle => _t('register_subtitle');
  String get fullName => _t('full_name');
  String get shopName => _t('shop_name');
  String get phone => _t('phone');
  String get shopEmail => _t('shop_email');
  String get choosePassword => _t('choose_password');
  String get getStarted => _t('get_started');
  String get alreadyJoined => _t('already_joined');
  String get loginInstead => _t('login_instead');
  String get myClients => _t('my_clients');
  String get customers => _t('customers');
  String get addNew => _t('add_new');
  String get searchCustomers => _t('search_customers');
  String get noCustomers => _t('no_customers');
  String get noCustomersHint => _t('no_customers_hint');
  String get noResults => _t('no_results');
  String get noResultsHint => _t('no_results_hint');
  String get newCustomer => _t('new_customer');
  String get saveCustomer => _t('save_customer');
  String get cancel => _t('cancel');
  String get nameHint => _t('name_hint');
  String get phoneHint => _t('phone_hint');
  String get address => _t('address');
  String get addressHint => _t('address_hint');
  String get newMeasurement => _t('new_measurement');
  String get selectCustomer => _t('select_customer');
  String get selectProduct => _t('select_product');
  String get enterMeasurements => _t('enter_measurements');
  String get saveMeasurements => _t('save_measurements');
  String get chooseCustomer => _t('choose_customer');
  String get home => _t('home');
  String get customer => _t('customer');
  String get measure => _t('measure');
  String get profile => _t('profile');
  String get orders => _t('orders');
  String get workers => _t('workers');
  String get worker => _t('worker');
  String get welcome => _t('welcome');
  String get quickActions => _t('quick_actions');
  String get recentOrders => _t('recent_orders');
  String get noRecentOrders => _t('no_recent_orders');
  String get viewAll => _t('view_all');
  String get dueToday => _t('due_today');
  String get active => _t('active');
  String get completed => _t('completed');
  String get statusAll => _t('status_all');
  String get statusPending => _t('status_pending');
  String get statusStitching => _t('status_stitching');
  String get statusFitting => _t('status_fitting');
  String get statusReady => _t('status_ready');
  String get statusDelivered => _t('status_delivered');
  String get statusCancelled => _t('status_cancelled');
  String get addClient => _t('add_client');
  String get invoice => _t('invoice');
  String get reports => _t('reports');
  String get logOut => _t('log_out');
  String get logoutTitle => _t('logout_title');
  String get logoutMsg => _t('logout_msg');
  String get cancelBtn => _t('cancel_btn');
  String get logoutBtn => _t('logout_btn');
  String get shopConfiguration => _t('shop_configuration');
  String get accountSettings => _t('account_settings');
  String get activeOrders => _t('active_orders');
  String get earnings => _t('earnings');
  String get selectLanguage => _t('select_language');
  String get language => _t('language');
  String get tailorType => _t('tailor_type');
  String get storeDetails => _t('store_details');
  String get accountBasics => _t('account_basics');
  String get location => _t('location');
  String get storeAddress => _t('store_address');
  String get pinCode => _t('pin_code');
  String get state => _t('state');
  String get enterNameError => _t('enter_name_error');
  String get enterPhoneError => _t('enter_phone_error');
  String get enterAddressError => _t('enter_address_error');
  String get validPhoneError => _t('valid_phone_error');
  String get loginMagicLink => _t('login_magic_link');
  String get magicLinkSent => _t('magic_link_sent');
  String get enterCredentialsError => _t('enter_credentials_error');
  String get enterEmailMagicError => _t('enter_email_magic_error');
  String get unexpectedError => _t('unexpected_error');
  String get fillFieldsError => _t('fill_fields_error');
  String get regSuccess => _t('reg_success');
  String get nameLengthError => _t('name_length_error');
  String get editCustomer => _t('edit_customer');
  String get updateCustomer => _t('update_customer');
  String get businessSnapshot => _t('business_snapshot');
  String get totalRevenue => _t('total_revenue');
  String get shopManagement => _t('shop_management');
  String get personalizeInvoice => _t('personalize_invoice');
  String get measurementTemplates => _t('measurement_templates');
  String get fabricInventory => _t('fabric_inventory');
  String get dataSecurity => _t('data_security');
  String get backupRestore => _t('backup_restore');
  String get privacySecurity => _t('privacy_security');
  String get personalHelp => _t('personal_help');
  String get helpGuide => _t('help_guide');
  String get masterProfile => _t('master_profile');

  // New keys for screen localization
  String get exitTitle => _t('exit_title');
  String get exitMessage => _t('exit_message');
  String get exitBtn => _t('exit_btn');
  String get newOrder => _t('new_order');
  String get recordMeasure => _t('record_measure');
  String get analytics => _t('analytics');
  String get overdue => _t('overdue');
  String get urgentOrders => _t('urgent_orders');
  String get overdueLabel => _t('overdue_label');
  String get dueTodayLabel => _t('due_today_label');
  String get dueIn1Day => _t('due_in_1_day');
  String get allCaughtUp => _t('all_caught_up');
  String get noUrgentOrdersHint => _t('no_urgent_orders_hint');
  String get invoiceSharedSuccess => _t('invoice_shared_success');
  String get searchCustomersOrders => _t('search_customers_orders');
  String get connectionError => _t('connection_error');
  String get connectionErrorOrdersSub => _t('connection_error_orders_sub');
  String get noOrdersAll => _t('no_orders_all');
  String get noOrdersAllSub => _t('no_orders_all_sub');
  String get noOrdersPending => _t('no_orders_pending');
  String get noOrdersPendingSub => _t('no_orders_pending_sub');
  String get noOrdersStitching => _t('no_orders_stitching');
  String get noOrdersStitchingSub => _t('no_orders_stitching_sub');
  String get noOrdersTrialing => _t('no_orders_trialing');
  String get noOrdersTrialingSub => _t('no_orders_trialing_sub');
  String get noOrdersReady => _t('no_orders_ready');
  String get noOrdersReadySub => _t('no_orders_ready_sub');
  String get noOrdersDelivered => _t('no_orders_delivered');
  String get noOrdersDeliveredSub => _t('no_orders_delivered_sub');
  String get unassigned => _t('unassigned');
  String get paid => _t('paid');
  String get clients => _t('clients');
  String get allClients => _t('all_clients');
  String get withDues => _t('with_dues');
  String get connectionErrorClientsSub => _t('connection_error_clients_sub');
  String get noMatchingClients => _t('no_matching_clients');
  String get noMatchingClientsSub => _t('no_matching_clients_sub');
  String get noClientsYet => _t('no_clients_yet');
  String get noClientsYetSub => _t('no_clients_yet_sub');
  String get topClient => _t('top_client');
  String get measured => _t('measured');
  String get noMeasures => _t('no_measures');
  String get activeTag => _t('active_tag');
  String get pendingBalance => _t('pending_balance');
  String get workshopCrew => _t('workshop_crew');
  String get connectionErrorWorkersSub => _t('connection_error_workers_sub');
  String get noCrewYet => _t('no_crew_yet');
  String get noCrewYetSub => _t('no_crew_yet_sub');
  String get pieceRateSpecialist => _t('piece_rate_specialist');
  String get monthlySalary => _t('monthly_salary');
  String get inactive => _t('inactive');
  String get viewPerformance => _t('view_performance');
  String get stitchSpecs => _t('stitch_specs');
  String get technicalSheet => _t('technical_sheet');
  String get draftMeasurement => _t('draft_measurement');
  String get changeBtn => _t('change_btn');
  String get searchClientSpecsHint => _t('search_client_specs_hint');
  String get quickAccess => _t('quick_access');
  String get startRecordingSpecs => _t('start_recording_specs');
  String get startRecordingSpecsSub => _t('start_recording_specs_sub');
  String get noClientsFound => _t('no_clients_found');
  String get unsavedChanges => _t('unsaved_changes');
  String get unsavedChangesMsg => _t('unsaved_changes_msg');
  String get continueEditing => _t('continue_editing');
  String get discard => _t('discard');
  String get shopConfigSub => _t('shop_config_sub');
  String get personalizeInvoiceSub => _t('personalize_invoice_sub');
  String get measurementTemplatesSub => _t('measurement_templates_sub');
  String get fabricInventorySub => _t('fabric_inventory_sub');
  String get backupRestoreSub => _t('backup_restore_sub');
  String get privacySecuritySub => _t('privacy_security_sub');
  String get appLanguage => _t('app_language');
  String get languagesList => _t('languages_list');
  String get helpGuideSub => _t('help_guide_sub');
  String get vaultSecurity => _t('vault_security');
  String get vaultSecurityMsg => _t('vault_security_msg');
  String get understood => _t('understood');
  String get langSaved => _t('lang_saved');
  String get langSaveFailed => _t('lang_save_failed');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ─── BuildContext Extension for easier access ────────────────────────────────
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String t(String key, [Map<String, String>? params]) => l10n.translate(key, params);
}
