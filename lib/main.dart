import 'package:pointo/screens/auth/deep_link_handler.dart';
import 'package:pointo/utils/conditional_local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:pointo/services/network_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final MethodChannel _macOSUrlChannel =
    const MethodChannel('custom_link_channel');

void main() async {
  print("=== MAIN START ===");

  // Устанавливаем обработчик ошибок в самом начале
  FlutterError.onError = (FlutterErrorDetails details) {
    print("Flutter error caught in main: ${details.exception}");
    print("Stack trace: ${details.stack}");
    FlutterError.presentError(details);
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();
    print("Flutter widgets binding initialized");

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        print("[DEBUG] $message");
      }
    };

    print("Initializing NetworkService...");
    NetworkService().initialize();

    print("Loading environment variables...");
    await dotenv.load(fileName: ".env").timeout(
          Duration(seconds: 10),
          onTimeout: () => throw TimeoutException("Failed to load .env file"),
        );

    print("Loading shared preferences...");
    final prefs = await SharedPreferences.getInstance().timeout(
      Duration(seconds: 10),
      onTimeout: () =>
          throw TimeoutException("Failed to load SharedPreferences"),
    );

    final rememberMe = prefs.getBool('remember_me') ?? false;
    print("Remember me setting: $rememberMe");

    String urlApi = dotenv.get('apiUrl');
    String keyApi = dotenv.get('apiKey');

    print("API URL: $urlApi");
    print("API Key: ${keyApi.isNotEmpty ? 'Present' : 'Missing'}");

    // Очищаем токены более безопасно
    print("Clearing potentially invalid tokens...");
    try {
      await prefs.remove('recovery_token').timeout(Duration(seconds: 5));
      await prefs.remove('recovery_email').timeout(Duration(seconds: 5));
      print("Tokens cleared successfully");
    } catch (e) {
      print("Error clearing tokens (continuing anyway): $e");
    }

    String redirectTo;
    if (kIsWeb) {
      redirectTo = 'https://gmorong.github.io/app-redirect/';
    } else if (Platform.isMacOS) {
      redirectTo = 'io.supabase.pointo://reset-callback/';
    } else if (Platform.isIOS || Platform.isAndroid) {
      redirectTo = 'io.supabase.pointo://reset-callback/';
    } else {
      redirectTo = 'io.supabase.pointo://reset-callback/';
    }

    print("=== PoinTo Initialization ===");
    print("Platform: ${Platform.operatingSystem}");
    print("Using redirect URL: $redirectTo");

    print("Initializing deep links...");
    await initializeDeepLinks().timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print("Deep links initialization timeout, continuing...");
      },
    );

    print("Initializing Supabase...");
    await Supabase.initialize(
      url: urlApi,
      anonKey: keyApi,
      debug: kDebugMode,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: ConditionalLocalStorage(rememberMe: rememberMe),
      ),
    ).timeout(
      Duration(seconds: 30),
      onTimeout: () =>
          throw TimeoutException("Supabase initialization timeout"),
    );

    print("Supabase initialized successfully with PKCE auth flow");

    // Проверяем текущую сессию безопасно
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        print("User is already signed in: ${session.user.email}");
      } else {
        print("No active session found");
      }
    } catch (e) {
      print("Error checking current session: $e");
    }

    print("Initializing DeepLinkHandler...");
    final deepLinkHandler = DeepLinkHandler();

    // Запускаем инициализацию DeepLinkHandler асинхронно, чтобы не блокировать
    _initializeDeepLinkHandlerAsync(deepLinkHandler);

    if (Platform.isMacOS) {
      print("Running macOS authentication diagnostics:");
      print("Auth flow type: PKCE");
      print("Redirect URL: $redirectTo");

      setupMacOSUrlChannelHandler(deepLinkHandler);

      print(
          "Reset password route available: ${navigatorKey.currentState?.canPop() ?? false}");
    }

    print("Setting up auth state listener...");
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final session = data.session;

        print("Auth event received: $event");

        try {
          if (event == AuthChangeEvent.signedIn) {
            print("User signed in successfully: ${session?.user.email}");
          } else if (event == AuthChangeEvent.signedOut) {
            print("User signed out");
          } else if (event == AuthChangeEvent.passwordRecovery) {
            print("Password recovery event received");
            if (navigatorKey.currentState != null) {
              print("Navigating to reset password screen");
              navigatorKey.currentState!.pushNamed('/reset_password');
            } else {
              print(
                  "Cannot navigate to reset password screen - navigatorKey not available");
            }
          } else if (event == AuthChangeEvent.tokenRefreshed) {
            print("Token refreshed");
          } else if (event == AuthChangeEvent.userUpdated) {
            print("User updated");
          } else if (event == AuthChangeEvent.mfaChallengeVerified) {
            print("MFA challenge verified");
          }
        } catch (e) {
          print("Error in auth state change handler: $e");
        }
      }, onError: (error) {
        print("Error in auth state change stream: $error");
      });
    } catch (e) {
      print("Error setting up auth state listener: $e");
    }

    print("Main initialization completed successfully");
  } catch (e, stackTrace) {
    print("CRITICAL ERROR during initialization: $e");
    print("Stack trace: $stackTrace");

    // Не бросаем исключение, чтобы приложение могло запуститься
    // Пользователь увидит ошибку в UI
  }

  print("Starting Flutter app...");
  runApp(ProviderScope(child: MyApp()));
  print("=== MAIN END ===");
}

// Асинхронная инициализация DeepLinkHandler
void _initializeDeepLinkHandlerAsync(DeepLinkHandler deepLinkHandler) {
  print("Starting async DeepLinkHandler initialization...");

  Future.delayed(Duration(milliseconds: 500), () async {
    try {
      await deepLinkHandler.initUniLinks().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print("DeepLinkHandler initialization timeout");
        },
      );
      print("DeepLinkHandler initialized successfully");

      // Печатаем диагностику
      deepLinkHandler.printDiagnostics();
    } catch (e, stackTrace) {
      print("Error initializing DeepLinkHandler: $e");
      print("Stack trace: $stackTrace");
    }
  });
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

Future<void> initializeDeepLinks() async {
  print("=== initializeDeepLinks() START ===");

  try {
    if (Platform.isMacOS) {
      print("Setting up deep links for macOS...");
      print("MacOS deep links will be handled via AppDelegate");
    } else {
      print(
          "Deep links for ${Platform.operatingSystem} will be initialized by DeepLinkHandler");
    }
  } catch (e) {
    print("Error setting up deep links: $e");
  }

  print("=== initializeDeepLinks() END ===");
}

void setupMacOSUrlChannelHandler(DeepLinkHandler deepLinkHandler) {
  print("=== setupMacOSUrlChannelHandler() START ===");

  if (!Platform.isMacOS) {
    print("Not macOS, skipping URL channel setup");
    return;
  }

  try {
    _macOSUrlChannel.setMethodCallHandler((call) async {
      print("Method channel call received: ${call.method}");

      if (call.method == 'onDeepLink') {
        final String url = call.arguments as String;
        print("Received deeplink in main via method channel: $url");

        try {
          final uri = Uri.parse(url);
          await deepLinkHandler.handleReceivedUri(uri);
          print("Deep link handled successfully");
          return "success";
        } catch (e) {
          print("Error handling URL in main: $e");
          return "error";
        }
      }
      return null;
    });

    print("macOS URL channel handler set up successfully");
  } catch (e) {
    print("Error setting up macOS URL channel: $e");
  }

  print("=== setupMacOSUrlChannelHandler() END ===");
}
