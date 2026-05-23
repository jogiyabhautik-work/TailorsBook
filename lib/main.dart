import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/supabase_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/language_provider.dart';
import 'providers/template_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/order_provider.dart';
import 'providers/worker_provider.dart';
import 'providers/fabric_provider.dart';
import 'providers/dashboard_provider.dart';
import 'core/utils/app_refresh_controller.dart';

import 'l10n/app_localizations.dart';
export 'l10n/app_localizations.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/update_password_screen.dart';
import 'widgets/common/provider_wrappers.dart';
import 'core/utils/local_database.dart';
import 'core/utils/design_system.dart';

// Global client accessor — use anywhere in your app
SupabaseClient get supabase => Supabase.instance.client;

// Global UI messaging and navigation
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void showGlobalSnackBar(String message, {bool isError = false}) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade800 : Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env — failure is non-fatal
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint("dotenv load failed (proceeding anyway): $e");
  }

  // Always try to init Supabase even if dotenv fails
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    
    await LocalDatabase.init();
  } catch (e) {
    debugPrint("CRITICAL STARTUP ERROR: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LanguageProvider _languageProvider = LanguageProvider();

  late final TemplateProvider _templateProvider;
  late final CustomerProvider _customerProvider;
  late final OrderProvider _orderProvider;
  late final WorkerProvider _workerProvider;
  late final FabricProvider _fabricProvider;
  late final DashboardProvider _dashboardProvider;
  late final AppRefreshController _refreshController;

  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _templateProvider = TemplateProvider();
    _customerProvider = CustomerProvider();
    _fabricProvider = FabricProvider();
    _orderProvider = OrderProvider(fabricProvider: _fabricProvider);
    _workerProvider = WorkerProvider(orderProvider: _orderProvider);
    _dashboardProvider = DashboardProvider();
    _refreshController = AppRefreshController();
    
    _customerProvider.fetchCustomers();
    _templateProvider.fetchMeasurements();
    _orderProvider.fetchOrders();
    _workerProvider.fetchWorkers();
    _fabricProvider.fetchFabrics();

    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('Forgot Password Redirect: AuthChangeEvent.passwordRecovery received!');
        navigatorKey.currentState?.pushNamed('/update-password');
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppRefreshControllerWrapper(
      notifier: _refreshController,
      child: LanguageProviderWrapper(
        notifier: _languageProvider,
        child: TemplateProviderWrapper(
          notifier: _templateProvider,
          child: CustomerProviderWrapper(
            notifier: _customerProvider,
            child: OrderProviderWrapper(
              notifier: _orderProvider,
              child: WorkerProviderWrapper(
                notifier: _workerProvider,
                child: FabricProviderWrapper(
                  notifier: _fabricProvider,
                  child: DashboardProviderWrapper(
                    notifier: _dashboardProvider,
                    child: Builder(
                        builder: (context) {
                          // Language support is postponed. Locale is locked to English.
                          // See lib/providers/language_provider.dart for the feature flag.
                          return MaterialApp(
                          navigatorKey: navigatorKey,
                          debugShowCheckedModeBanner: false,
                          scaffoldMessengerKey: scaffoldMessengerKey,
                          title: 'TailorsBook',
                          routes: {
                            '/update-password': (context) => const UpdatePasswordScreen(),
                          },
                          locale: const Locale('en'),
                          supportedLocales: AppLocalizations.supportedLocales,
                          localizationsDelegates: const [
                            AppLocalizations.delegate,
                            GlobalMaterialLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                            GlobalCupertinoLocalizations.delegate,
                          ],
                        theme: ThemeData(
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: DesignSystem.primaryContainer,
                            primary: DesignSystem.primaryContainer,
                            onPrimary: DesignSystem.surfaceContainerLowest,
                            secondary: DesignSystem.secondary,
                            surface: DesignSystem.surface,
                          ),
                          textTheme: GoogleFonts.manropeTextTheme(),
                          scaffoldBackgroundColor: DesignSystem.surface,
                          cardTheme: CardThemeData(
                            color: DesignSystem.surfaceContainerLowest,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                              side: BorderSide(color: DesignSystem.outlineVariant),
                            ),
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: DesignSystem.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                              borderSide: BorderSide(
                                color: DesignSystem.primaryContainer.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: DesignSystem.s16,
                              vertical: DesignSystem.s14,
                            ),
                          ),
                          elevatedButtonTheme: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DesignSystem.primaryContainer,
                              foregroundColor: DesignSystem.surfaceContainerLowest,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: DesignSystem.s14,
                                horizontal: DesignSystem.s24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
                              ),
                              textStyle: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                           ),
                           useMaterial3: true,
                         ),
                         home: const SplashScreen(),
                       );
                     },
                   ),
                 ),
               ),
             ),
           ),
         ),
       ),
     ),
    );
  }
}
