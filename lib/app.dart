import 'package:pointo/screens/auth/deep_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';
import './providers/theme_provider.dart';
import './providers/locale_provider.dart';
import './theme/theme_asset.dart';
import './router/router_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './main.dart';
import 'package:provider/provider.dart' as provider;
import 'package:pointo/services/network_service.dart';
import 'package:pointo/widgets/network_wrapper.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final DeepLinkHandler _deepLinkHandler = DeepLinkHandler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      // ignore: unused_local_variable
      final session = data.session;
      final event = data.event;

      print("Auth event received in MyApp: $event");

      if (event == AuthChangeEvent.passwordRecovery) {
        print("Password recovery event detected in MyApp");
        if (navigatorKey.currentState != null) {
          print("Navigating to reset password screen from MyApp");
          navigatorKey.currentState!.pushNamed('/reset_password');
        }
      }
    });

    NetworkService().addListener(_onNetworkStatusChanged);
  }

  void _onNetworkStatusChanged() {
    final networkService = NetworkService();
    
    if (networkService.hasError) {
      print("Network error detected globally: ${networkService.errorMessage}");
    } else if (networkService.isConnected) {
      print("Network connection restored globally");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkHandler.dispose();
    NetworkService().removeListener(_onNetworkStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);
    final localeAsync = ref.watch(localeProvider);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final initialRoute = user == null ? '/signin' : '/home_page';

    return localeAsync.when(
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error loading locale: $err')),
        ),
      ),
      data: (locale) => provider.ChangeNotifierProvider(
        create: (context) => NetworkService(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PoinTo',
          themeMode: theme.themeMode,
          theme: customLightTheme,
          darkTheme: customDarkTheme,
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ru'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: initialRoute,
          routes: routes,
          navigatorKey: navigatorKey,
          onGenerateRoute: onGenerateRoute,
          builder: (context, child) {
            return provider.Consumer<NetworkService>(
              builder: (context, networkService, _) {
                return NetworkWrapper(
                  onRetry: _handleGlobalRetry,
                  child: child ?? Container(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _handleGlobalRetry() {
    print("Global retry requested");
    
    if (navigatorKey.currentState != null) {
      final currentRoute = ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
      if (currentRoute != null && currentRoute != '/') {
        if (NetworkService().isConnected && !NetworkService().hasError) {
          navigatorKey.currentState!.pushReplacementNamed(currentRoute);
        }
      }
    }
  }
}