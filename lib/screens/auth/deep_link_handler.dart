import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:flutter/foundation.dart';

class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();

  factory DeepLinkHandler() => _instance;

  DeepLinkHandler._internal();

  String? recoveryToken;
  String? userEmail;
  final MethodChannel _macOSChannel = const MethodChannel('custom_link_channel');
  bool _isInitialized = false;

  final StreamController<Map<String, String?>> _paramsController =
      StreamController<Map<String, String?>>.broadcast();

  Stream<Map<String, String?>> get paramsStream => _paramsController.stream;

  Future<void> initUniLinks() async {
    print("=== DeepLinkHandler.initUniLinks() START ===");
    
    if (_isInitialized) {
      print("DeepLinkHandler already initialized. Skipping...");
      return;
    }
    
    try {
      _isInitialized = true;
      
      print("DeepLinkHandler: Starting initialization...");
      print("DeepLinkHandler: Platform: ${Platform.operatingSystem}");
      
      // Очищаем любые проблемные токены при старте с timeout
      print("DeepLinkHandler: Clearing invalid tokens...");
      await _clearInvalidTokens().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print("DeepLinkHandler: Clear tokens timeout, continuing...");
        },
      );
      
      // Получаем сохраненные значения с timeout
      print("DeepLinkHandler: Loading saved params...");
      await _loadSavedParams().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print("DeepLinkHandler: Load params timeout, continuing...");
        },
      );

      if (Platform.isMacOS) {
        print("DeepLinkHandler: Initializing macOS links...");
        _initMacOSLinks();
      } else {
        print("DeepLinkHandler: Initializing mobile links...");
        _initMobileLinks();
      }
      
      print("DeepLinkHandler: initialization completed successfully");
      
    } catch (e, stackTrace) {
      print("DeepLinkHandler: Error during initialization: $e");
      print("DeepLinkHandler: Stack trace: $stackTrace");
      // Не бросаем исключение, чтобы не блокировать приложение
    }
    
    print("=== DeepLinkHandler.initUniLinks() END ===");
  }

  void _initMacOSLinks() {
    print("DeepLinkHandler: Setting up macOS method channel...");
    
    try {
      _macOSChannel.setMethodCallHandler((call) async {
        print("DeepLinkHandler: Received method call: ${call.method}");
        
        if (call.method == 'onDeepLink') {
          final String link = call.arguments;
          print('DeepLinkHandler: Received macOS deep link: $link');
          
          try {
            final uri = Uri.parse(link);
            await handleReceivedUri(uri);
            return "success";
          } catch (e) {
            print("DeepLinkHandler: Error parsing macOS URI: $e");
            return "error";
          }
        }
        return null;
      });
      
      print("DeepLinkHandler: macOS method channel setup completed");
    } catch (e) {
      print("DeepLinkHandler: Error setting up macOS channel: $e");
    }
  }

  void _initMobileLinks() {
    print("DeepLinkHandler: Mobile platform initialization");
    print("DeepLinkHandler: Mobile deep links will be handled natively");
  }

  Future<void> handleReceivedUri(Uri uri) async {
    print("=== DeepLinkHandler.handleReceivedUri() START ===");
    print("DeepLinkHandler: URI: $uri");
    print("DeepLinkHandler: URI scheme: ${uri.scheme}");
    print("DeepLinkHandler: URI host: ${uri.host}");
    print("DeepLinkHandler: URI path: ${uri.path}");
    print("DeepLinkHandler: URI query: ${uri.query}");
    print("DeepLinkHandler: URI fragment: ${uri.fragment}");

    try {
      // Извлекаем параметры из query и fragment
      final params = <String, String>{};
      
      // Добавляем query parameters
      if (uri.queryParameters.isNotEmpty) {
        print("DeepLinkHandler: Adding query parameters: ${uri.queryParameters}");
        params.addAll(uri.queryParameters);
      }
      
      // Парсим fragment если есть
      if (uri.fragment.isNotEmpty) {
        print("DeepLinkHandler: Parsing fragment: ${uri.fragment}");
        final fragmentParams = _parseFragment(uri.fragment);
        params.addAll(fragmentParams);
      }

      print("DeepLinkHandler: All extracted params: $params");

      // Получаем токен из разных возможных параметров
      String? token = params['access_token'] ?? 
                     params['token'] ?? 
                     params['recovery_token'];

      // Если нашли токен, обновляем
      if (token != null) {
        print("DeepLinkHandler: Found token in URI: ${_sanitizeTokenForLogging(token)}");
        recoveryToken = token;
      } else {
        print("DeepLinkHandler: No token found in URI");
      }

      // Извлекаем email
      String? email = params['email'] ?? params['user_email'];
      if (email != null) {
        print("DeepLinkHandler: Found email: $email");
        userEmail = email;
      } else {
        print("DeepLinkHandler: No email found in URI");
      }

      // Сохраняем параметры
      if (recoveryToken != null || userEmail != null) {
        print("DeepLinkHandler: Saving extracted parameters...");
        await _saveParams();

        // Оповещаем подписчиков
        _paramsController.add({
          'token': recoveryToken,
          'email': userEmail,
        });
      }

      // Проверяем тип ссылки и восстанавливаем сессию
      final type = params['type'];
      print("DeepLinkHandler: Link type: $type");
      
      if (type == 'recovery' && recoveryToken != null) {
        print("DeepLinkHandler: Password recovery link detected");
        // Запускаем восстановление сессии асинхронно, чтобы не блокировать
        _restoreSessionAsync();
      } else {
        print("DeepLinkHandler: Not a recovery link or no token available");
      }
      
    } catch (e, stackTrace) {
      print("DeepLinkHandler: Error in handleReceivedUri: $e");
      print("DeepLinkHandler: Stack trace: $stackTrace");
    }
    
    print("=== DeepLinkHandler.handleReceivedUri() END ===");
  }

  // Асинхронное восстановление сессии, чтобы не блокировать основной поток
  void _restoreSessionAsync() {
    print("DeepLinkHandler: Starting async session restore...");
    
    Future.delayed(Duration(milliseconds: 100), () async {
      try {
        await _restoreSession();
      } catch (e) {
        print("DeepLinkHandler: Async session restore failed: $e");
      }
    });
  }

  // Улучшенный парсинг fragment
  Map<String, String> _parseFragment(String fragment) {
    final params = <String, String>{};
    
    try {
      print("DeepLinkHandler: Parsing fragment: '$fragment'");
      
      // Убираем # в начале если есть
      String cleanFragment = fragment.startsWith('#') ? fragment.substring(1) : fragment;
      print("DeepLinkHandler: Clean fragment: '$cleanFragment'");
      
      // Разделяем по &
      final pairs = cleanFragment.split('&');
      print("DeepLinkHandler: Fragment pairs: $pairs");
      
      for (final pair in pairs) {
        if (pair.trim().isEmpty) continue;
        
        final keyValue = pair.split('=');
        if (keyValue.length >= 2) {
          try {
            final key = Uri.decodeComponent(keyValue[0]);
            final value = Uri.decodeComponent(keyValue[1]);
            params[key] = value;
            print("DeepLinkHandler: Parsed param: '$key' = '$value'");
          } catch (e) {
            print("DeepLinkHandler: Error decoding param '$pair': $e");
          }
        }
      }
      
      print("DeepLinkHandler: Final fragment params: $params");
    } catch (e) {
      print("DeepLinkHandler: Error parsing fragment: $e");
    }
    
    return params;
  }

  // Маскируем токен для логгирования
  String _sanitizeTokenForLogging(String? token) {
    if (token == null) return 'null';
    if (token.length > 20) {
      return '${token.substring(0, 20)}...';
    }
    return token;
  }

  Future<void> _restoreSession() async {
    print("=== DeepLinkHandler._restoreSession() START ===");
    
    if (recoveryToken == null) {
      print("DeepLinkHandler: No recovery token available");
      return;
    }
    
    try {
      print("DeepLinkHandler: Token: ${_sanitizeTokenForLogging(recoveryToken)}");
      print("DeepLinkHandler: Email: $userEmail");
      
      // Проверка инициализации Supabase
      try {
        final client = Supabase.instance.client;
        if (client == null) {
          print("DeepLinkHandler: Supabase client is not available");
          return;
        }
      } catch (e) {
        print("DeepLinkHandler: Supabase is not initialized: $e");
        return;
      }
      
      if (Supabase.instance.client.auth == null) {
        print("DeepLinkHandler: Supabase auth is not available");
        return;
      }
      
      // Проверяем валидность токена перед использованием
      print("DeepLinkHandler: Validating JWT token...");
      if (!_isValidJWT(recoveryToken!)) {
        print("DeepLinkHandler: Invalid JWT token detected, clearing...");
        await clearTokens();
        return;
      }
      
      print("DeepLinkHandler: Token validation passed, attempting recovery");
      
      // Пробуем восстановить сессию разными способами с таймаутом
      bool sessionRestored = false;
      
      try {
        // Способ 1: Для password recovery используем verifyOTP
        if (userEmail != null) {
          print("DeepLinkHandler: Attempting verifyOTP with email: $userEmail");
          
          final response = await Supabase.instance.client.auth.verifyOTP(
            token: recoveryToken!,
            type: OtpType.recovery,
            email: userEmail,
          ).timeout(Duration(seconds: 10));
          
          if (response.session != null) {
            print("DeepLinkHandler: Session recovered successfully using verifyOTP");
            print("DeepLinkHandler: User ID: ${response.session!.user.id}");
            sessionRestored = true;
          } else {
            print("DeepLinkHandler: verifyOTP returned null session");
          }
        } else {
          print("DeepLinkHandler: No email available for verifyOTP");
        }
        
        // Способ 2: recoverSession для новых версий (если первый не сработал)
        if (!sessionRestored) {
          print("DeepLinkHandler: Trying recoverSession");
          final response = await Supabase.instance.client.auth.recoverSession(
            recoveryToken!
          ).timeout(Duration(seconds: 10));
          
          if (response.session != null) {
            print("DeepLinkHandler: Session recovered successfully using recoverSession");
            print("DeepLinkHandler: User ID: ${response.session!.user.id}");
            sessionRestored = true;
          } else {
            print("DeepLinkHandler: recoverSession returned null session");
          }
        }
        
        if (!sessionRestored) {
          print("DeepLinkHandler: All recovery methods failed to create session");
        }
        
      } catch (e) {
        print("DeepLinkHandler: Session recovery failed: $e");
        
        // Если токен невалидный, очищаем его
        if (e.toString().contains('InvalidJWTToken') || 
            e.toString().contains('expired') ||
            e.toString().contains('invalid') ||
            e.toString().contains('FormatException')) {
          print("DeepLinkHandler: Token is invalid/expired, clearing...");
          await clearTokens();
        }
        
        // Уведомляем подписчиков об ошибке
        _paramsController.add({
          'token': null,
          'email': userEmail,
          'error': 'Token invalid or expired: ${e.toString()}',
        });
      }
      
      // Проверка итоговой сессии
      final session = Supabase.instance.client.auth.currentSession;
      print("DeepLinkHandler: Final session check: ${session != null ? 'Valid' : 'null'}");
      
      if (session != null) {
        print("DeepLinkHandler: User authenticated: ${session.user.email}");
        print("DeepLinkHandler: Session expires at: ${DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)}");
        
        // Очищаем использованный токен
        print("DeepLinkHandler: Clearing used recovery token");
        await clearTokens();
      }
      
    } catch (e, stackTrace) {
      print("DeepLinkHandler: Critical error during session restore: $e");
      print("DeepLinkHandler: Stack trace: $stackTrace");
      
      // При критической ошибке очищаем токен
      try {
        await clearTokens();
      } catch (clearError) {
        print("DeepLinkHandler: Error clearing tokens: $clearError");
      }
    }
    
    print("=== DeepLinkHandler._restoreSession() END ===");
  }
  
  // Простая проверка валидности JWT токена
  bool _isValidJWT(String token) {
    try {
      print("DeepLinkHandler: Validating JWT token structure...");
      
      // JWT состоит из 3 частей, разделенных точками
      final parts = token.split('.');
      if (parts.length != 3) {
        print("DeepLinkHandler: Invalid JWT format - wrong number of parts: ${parts.length}");
        return false;
      }
      
      // Проверяем, что все части не пустые
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isEmpty) {
          print("DeepLinkHandler: Invalid JWT format - empty part $i");
          return false;
        }
      }
      
      print("DeepLinkHandler: JWT format validation passed");
      return true;
      
    } catch (e) {
      print("DeepLinkHandler: JWT validation error: $e");
      return false;
    }
  }

  Future<void> _saveParams() async {
    print("=== DeepLinkHandler._saveParams() START ===");
    
    try {
      final prefs = await SharedPreferences.getInstance();

      if (recoveryToken != null) {
        await prefs.setString('recovery_token', recoveryToken!);
        print("DeepLinkHandler: Saved recovery token");
      } else {
        await prefs.remove('recovery_token');
        print("DeepLinkHandler: Removed recovery token");
      }

      if (userEmail != null) {
        await prefs.setString('recovery_email', userEmail!);
        print("DeepLinkHandler: Saved user email: $userEmail");
      } else {
        await prefs.remove('recovery_email');
        print("DeepLinkHandler: Removed user email");
      }
    } catch (e) {
      print("DeepLinkHandler: Error saving params: $e");
    }
    
    print("=== DeepLinkHandler._saveParams() END ===");
  }

  Future<void> _loadSavedParams() async {
    print("=== DeepLinkHandler._loadSavedParams() START ===");
    
    try {
      final prefs = await SharedPreferences.getInstance();

      recoveryToken = prefs.getString('recovery_token');
      userEmail = prefs.getString('recovery_email');

      print("DeepLinkHandler: Loaded from SharedPreferences:");
      print("Token: ${_sanitizeTokenForLogging(recoveryToken)}");
      print("Email: $userEmail");

      // Проверяем валидность загруженного токена
      if (recoveryToken != null) {
        print("DeepLinkHandler: Validating loaded token...");
        if (!_isValidJWT(recoveryToken!)) {
          print("DeepLinkHandler: Loaded token is invalid, clearing...");
          recoveryToken = null;
          await prefs.remove('recovery_token');
        } else {
          print("DeepLinkHandler: Loaded token is valid");
        }
      }

      if (recoveryToken != null || userEmail != null) {
        _paramsController.add({
          'token': recoveryToken,
          'email': userEmail,
        });
        
        // НЕ АВТОМАТИЧЕСКИ восстанавливаем сессию при загрузке
        // Пусть пользователь сам инициирует процесс
        if (recoveryToken != null) {
          print("DeepLinkHandler: Found saved token, but NOT auto-restoring session");
          print("DeepLinkHandler: Token will be used when user initiates recovery");
        }
      }
    } catch (e) {
      print("DeepLinkHandler: Error loading params: $e");
    }
    
    print("=== DeepLinkHandler._loadSavedParams() END ===");
  }
  
  // Очистка проблемных токенов при старте
  Future<void> _clearInvalidTokens() async {
    print("=== DeepLinkHandler._clearInvalidTokens() START ===");
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Получаем все ключи и ищем токены
      final keys = prefs.getKeys();
      print("DeepLinkHandler: Found SharedPreferences keys: $keys");
      
      // Проверяем и очищаем любые проблемные токены
      final savedToken = prefs.getString('recovery_token');
      if (savedToken != null) {
        print("DeepLinkHandler: Found saved token: ${_sanitizeTokenForLogging(savedToken)}");
        if (!_isValidJWT(savedToken)) {
          print("DeepLinkHandler: Clearing invalid token from storage");
          await prefs.remove('recovery_token');
        } else {
          print("DeepLinkHandler: Saved token appears valid");
        }
      } else {
        print("DeepLinkHandler: No saved token found");
      }
      
    } catch (e) {
      print("DeepLinkHandler: Error clearing invalid tokens: $e");
    }
    
    print("=== DeepLinkHandler._clearInvalidTokens() END ===");
  }

  void dispose() {
    print("=== DeepLinkHandler.dispose() ===");
    try {
      _paramsController.close();
      print("DeepLinkHandler: Disposed successfully");
    } catch (e) {
      print("DeepLinkHandler: Error during dispose: $e");
    }
  }
  
  // Метод для ручной обработки URL
  Future<void> processUrl(String url) async {
    print("=== DeepLinkHandler.processUrl() START ===");
    print("DeepLinkHandler: Processing URL: $url");
    
    try {
      final uri = Uri.parse(url);
      await handleReceivedUri(uri);
    } catch (e) {
      print("DeepLinkHandler: Error parsing manual URL: $e");
    }
    
    print("=== DeepLinkHandler.processUrl() END ===");
  }
  
  // Метод для очистки токенов
  Future<void> clearTokens() async {
    print("=== DeepLinkHandler.clearTokens() START ===");
    
    try {
      recoveryToken = null;
      userEmail = null;
      await _saveParams();
      
      _paramsController.add({
        'token': null,
        'email': null,
      });
      
      print("DeepLinkHandler: All tokens cleared successfully");
    } catch (e) {
      print("DeepLinkHandler: Error clearing tokens: $e");
    }
    
    print("=== DeepLinkHandler.clearTokens() END ===");
  }
  
  // Метод для принудительного восстановления сессии
  Future<void> forceRestoreSession() async {
    print("DeepLinkHandler: Force restore session requested");
    if (recoveryToken != null) {
      await _restoreSession();
    } else {
      print("DeepLinkHandler: No token available for force restore");
    }
  }
  
  // Диагностический метод
  void printDiagnostics() async {
    print("=== DeepLinkHandler DIAGNOSTICS ===");
    print("Initialized: $_isInitialized");
    print("Recovery Token: ${_sanitizeTokenForLogging(recoveryToken)}");
    print("User Email: $userEmail");
    print("Platform: ${Platform.operatingSystem}");
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      print("SharedPreferences keys: $keys");
      
      try {
        final client = Supabase.instance.client;
        final session = client.auth.currentSession;
        print("Current Supabase session: ${session != null ? 'Active' : 'None'}");
        if (session != null) {
          print("Session user: ${session.user.email}");
        }
      } catch (e) {
        print("Supabase not initialized or error: $e");
      }
    } catch (e) {
      print("Error in diagnostics: $e");
    }
    print("=== END DIAGNOSTICS ===");
  }
}