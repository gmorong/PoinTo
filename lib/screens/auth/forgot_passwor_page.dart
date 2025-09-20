import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Класс для управления лимитами восстановления пароля
class PasswordResetRateLimiter {
  static const String _prefsKey = 'password_reset_attempts';
  static const int _maxAttemptsPerHour = 5;

  /// Проверяет, может ли пользователь отправить запрос на сброс пароля
  static Future<bool> canRequestReset(String login) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsData = prefs.getString(_prefsKey) ?? '{}';
    final Map<String, dynamic> attemptsMap = json.decode(attemptsData);

    // Получаем записи для данного логина
    final List<int> attempts =
        attemptsMap[login] != null ? List<int>.from(attemptsMap[login]) : [];

    // Текущее время в миллисекундах
    final now = DateTime.now().millisecondsSinceEpoch;

    // Фильтруем попытки за последний час
    final recentAttempts = attempts
        .where((timestamp) => now - timestamp < 3600000 // 1 час в миллисекундах
            )
        .toList();

    // Проверяем, не превышен ли лимит
    if (recentAttempts.length >= _maxAttemptsPerHour) {
      return false;
    }

    // Добавляем новую попытку
    recentAttempts.add(now);
    attemptsMap[login] = recentAttempts;

    // Сохраняем обновленные данные
    await prefs.setString(_prefsKey, json.encode(attemptsMap));

    return true;
  }

  /// Возвращает количество оставшихся попыток сброса пароля
  static Future<int> getRemainingAttempts(String login) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsData = prefs.getString(_prefsKey) ?? '{}';
    final Map<String, dynamic> attemptsMap = json.decode(attemptsData);

    // Получаем записи для данного логина
    final List<int> attempts =
        attemptsMap[login] != null ? List<int>.from(attemptsMap[login]) : [];

    // Текущее время в миллисекундах
    final now = DateTime.now().millisecondsSinceEpoch;

    // Фильтруем попытки за последний час
    final recentAttempts = attempts
        .where((timestamp) => now - timestamp < 3600000 // 1 час в миллисекундах
            )
        .toList();

    return _maxAttemptsPerHour - recentAttempts.length;
  }

  /// Возвращает время в секундах до сброса лимита
  static Future<int> getTimeUntilReset(String login) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsData = prefs.getString(_prefsKey) ?? '{}';
    final Map<String, dynamic> attemptsMap = json.decode(attemptsData);

    // Получаем записи для данного логина
    final List<int> attempts =
        attemptsMap[login] != null ? List<int>.from(attemptsMap[login]) : [];

    if (attempts.isEmpty) return 0;

    // Сортируем по времени
    attempts.sort();

    // Получаем самую раннюю попытку за последний час
    final now = DateTime.now().millisecondsSinceEpoch;
    final recentAttempts = attempts
        .where((timestamp) => now - timestamp < 3600000 // 1 час в миллисекундах
            )
        .toList();

    if (recentAttempts.isEmpty) return 0;

    // Вычисляем время до сброса первой попытки
    final oldestAttempt = recentAttempts.first;
    final resetTime = oldestAttempt + 3600000; // +1 час
    final remainingTime = resetTime - now;

    return (remainingTime / 1000).round(); // Конвертируем в секунды
  }

  /// Форматирует оставшееся время в удобный формат
  String formatRemainingTime(BuildContext context, int secondsRemaining) {
  final minutes = (secondsRemaining / 60).floor();
  final seconds = secondsRemaining % 60;

  final loc = AppLocalizations.of(context)!;

  if (minutes > 0) {
    return '$minutes ${_formatMinutes(loc, minutes)} $seconds ${_formatSeconds(loc, seconds)}';
  } else {
    return '$seconds ${_formatSeconds(loc, seconds)}';
  }
}

  String _formatMinutes(AppLocalizations loc, int minutes) {
  if (minutes % 10 == 1 && minutes % 100 != 11) {
    return loc.minute;
  } else if ([2, 3, 4].contains(minutes % 10) &&
      ![12, 13, 14].contains(minutes % 100)) {
    return loc.minutes;
  } else {
    return loc.minutes1;
  }
}

String _formatSeconds(AppLocalizations loc, int seconds) {
  if (seconds % 10 == 1 && seconds % 100 != 11) {
    return loc.second;
  } else if ([2, 3, 4].contains(seconds % 10) &&
      ![12, 13, 14].contains(seconds % 100)) {
    return loc.seconds;
  } else {
    return loc.neconds1;
  }
}
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Глобальный ключ для работы с формой
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Клиент Supabase для аутентификации
  final SupabaseClient supabase = Supabase.instance.client;

  // Контроллеры полей ввода
  final _loginController = TextEditingController();

  // Фокусы для управления переходами между полями
  final _loginFocusNode = FocusNode();

  // Состояния UI
  String? _loginError;
  bool _isLoading = false;
  bool _resetSent = false;
  int _remainingAttempts = 5; // По умолчанию максимальное количество попыток
  int _timeUntilReset = 0; // Время до сброса лимита в секундах
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _updateRateLimitInfo();
  }

  /// Обновляет информацию о лимитах восстановления пароля
  Future<void> _updateRateLimitInfo() async {
    if (_loginController.text.isNotEmpty) {
      final login = _loginController.text.trim();
      final attempts =
          await PasswordResetRateLimiter.getRemainingAttempts(login);
      final timeUntilReset =
          await PasswordResetRateLimiter.getTimeUntilReset(login);

      setState(() {
        _remainingAttempts = attempts;
        _timeUntilReset = timeUntilReset;
      });

      // Запускаем таймер обратного отсчета, если есть ограничение
      if (_timeUntilReset > 0 && _remainingAttempts < 5) {
        _startCountdownTimer();
      }
    }
  }

  /// Запускает таймер обратного отсчета
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeUntilReset > 0) {
          _timeUntilReset--;
        } else {
          _updateRateLimitInfo();
          timer.cancel();
        }
      });
    });
  }

  /// Показывает диалог с ошибкой
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.error),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.success),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.resetEmailLimitNotice,
                    ),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  void _showRateLimitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.resetLimitExceeded),
          content: Text(
            AppLocalizations.of(context)!.resetLimitExceededMessage,
            semanticsLabel: AppLocalizations.of(context)!.waitBeforeNextAttempt(
                PasswordResetRateLimiter().formatRemainingTime(context, _timeUntilReset)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  /// Проверяет наличие SQL-инъекций во входных данных
  bool containsSqlInjection(String input) {
    final RegExp sqlInjectionPattern = RegExp(
      r'(\b(?:SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|EXEC|UNION|CREATE|WHERE|OR|AND)\b)|(--)|(;)',
      caseSensitive: false,
    );

    return sqlInjectionPattern.hasMatch(input);
  }

  /// Валидация поля логина
  String? validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.enterLogin;
    }

    // Проверка на разрешенные символы: английские буквы, цифры и нижнее подчеркивание
    final RegExp loginRegExp = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!loginRegExp.hasMatch(value)) {
      return AppLocalizations.of(context)!.usernameFormatHint;
    }

    return null;
  }

  /// Отправляет запрос на восстановление пароля
  Future<void> _resetPassword() async {
    setState(() {
      _loginError = null;
      _isLoading = true;
    });

    try {
      // Валидация логина перед отправкой
      final login = _loginController.text.trim();

      // Проверка логина
      final loginValidation = validateLogin(login);
      if (loginValidation != null) {
        setState(() {
          _loginError = loginValidation;
          _isLoading = false;
        });
        return;
      }

      // Дополнительная проверка на SQL-инъекции
      if (containsSqlInjection(login)) {
        _showErrorDialog(
            AppLocalizations.of(context)!.invalidCharactersDetected);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Проверяем лимит запросов
      final canRequest = await PasswordResetRateLimiter.canRequestReset(login);
      if (!canRequest) {
        setState(() {
          _isLoading = false;
        });

        // Обновляем информацию о лимитах
        await _updateRateLimitInfo();

        // Показываем диалог с информацией о лимите
        _showRateLimitDialog();
        return;
      }

      // Находим пользователя по логину для получения email
      final userInDb = await supabase
          .from('users')
          .select('email')
          .eq('login', login)
          .maybeSingle();

      if (userInDb == null) {
        // Проверяем, есть ли пользователь с таким логином среди неподтвержденных
        final unconfirmedUser = await supabase
            .from('unconfirmed_users')
            .select('email')
            .eq('login', login)
            .maybeSingle();

        if (unconfirmedUser != null) {
          setState(() {
            _loginError = AppLocalizations.of(context)!.emailNotConfirmed;
            _isLoading = false;
          });
          return;
        } else {
          setState(() {
            _loginError = AppLocalizations.of(context)!.userNotFound;
            _isLoading = false;
          });
          return;
        }
      }

      // Получаем email пользователя
      final email = userInDb['email'] as String;

      // Отправляем запрос на сброс пароля
      await supabase.auth.resetPasswordForEmail(email);

      // Обновляем информацию о лимитах
      await _updateRateLimitInfo();

      // Показываем сообщение об успехе
      setState(() {
        _resetSent = true;
        _isLoading = false;
      });

      _showSuccessDialog(AppLocalizations.of(context)!.passwordResetEmailSent);
    } catch (error) {
      // Обработка ошибок
      String errorMessage = AppLocalizations.of(context)!.passwordResetError;
      if (error is AuthException) {
        errorMessage =
            AppLocalizations.of(context)!.errorWithDetails(error.message);
      }
      _showErrorDialog(errorMessage);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Скрываем клавиатуру при нажатии вне текстовых полей
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        // Заголовок приложения
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.forgotPassword),
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        // Основной контент
        body: Form(
          key: _formKey,
          child: Center(
            child: Card(
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(32.0),
                constraints: const BoxConstraints(maxWidth: 350),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Иконка
                      Icon(
                        Icons.lock_reset,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Text(
                        AppLocalizations.of(context)!.resetPassword,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      _gap(),

                      // Информационный текст
                      Text(
                        AppLocalizations.of(context)!.resetPasswordInstructions,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      _gap(),

                      if (!_resetSent) ...[
                        // Поле ввода логина
                        TextFormField(
                          controller: _loginController,
                          focusNode: _loginFocusNode,
                          textCapitalization: TextCapitalization.none,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          // Используем валидацию
                          validator: validateLogin,
                          // Показываем ошибку, если она есть
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.login,
                            hintText: AppLocalizations.of(context)!.enterLogin,
                            prefixIcon: const Icon(Icons.person_outline),
                            border: const OutlineInputBorder(),
                            errorText: _loginError,
                          ),
                          // Применяем фильтр для ограничения символов до английских букв, цифр и подчеркивания
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9_]')),
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _updateRateLimitInfo();
                            }
                          },
                        ),
                        _gap(),

                        // Информация о лимите запросов
                        if (_remainingAttempts < 5) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.amber.shade800,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .remainingAttempts(
                                                _remainingAttempts),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_timeUntilReset > 0 &&
                                    _remainingAttempts == 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .nextAttemptAvailable(
                                            PasswordResetRateLimiter()
                                                .formatRemainingTime(
                                                    context,
                                                    _timeUntilReset)),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _gap(),
                        ],

                        // Кнопка отправки
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: (_isLoading || _remainingAttempts == 0)
                                ? null
                                : () {
                                    // Скрываем клавиатуру перед проверкой формы
                                    FocusScope.of(context).unfocus();

                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      _resetPassword();
                                    }
                                  },
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.sendResetLink,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ] else ...[
                        // Сообщение об успехе
                        Icon(
                          Icons.check_circle_outline,
                          size: 60,
                          color: Colors.green,
                        ),
                        _gap(),
                        Text(
                          AppLocalizations.of(context)!.checkYourEmail,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        _gap(),
                        // Информация о лимите
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade800,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _gap(),
                        // Кнопка возврата к экрану входа
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.backToSignIn,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Вспомогательный виджет для создания отступов
  Widget _gap() => const SizedBox(height: 16);

  @override
  void dispose() {
    // Освобождаем ресурсы при уничтожении виджета
    _loginController.dispose();
    _loginFocusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
