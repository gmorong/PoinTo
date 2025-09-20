import 'package:pointo/providers/locale_provider.dart';
import 'package:pointo/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'forgot_passwor_page.dart';

class SignInPage1 extends ConsumerStatefulWidget {
  const SignInPage1({Key? key}) : super(key: key);

  @override
  ConsumerState<SignInPage1> createState() => _SignInPage1State();
}

class _SignInPage1State extends ConsumerState<SignInPage1> {
  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _loginError;
  String? _passwordError;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final SupabaseClient supabase = Supabase.instance.client;

  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  final _loginFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _rememberMe = prefs.getBool('remember_me') ?? true;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки настроек: $e');
    }
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(themeNotifierProvider);
    final localeAsync = ref.watch(localeProvider);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isDarkTheme = notifier.themeMode == ThemeMode.dark;
            Locale? locale = localeAsync.whenOrNull(data: (loc) => loc);
            if (locale == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.settings),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.darkMode),
                    value: isDarkTheme,
                    onChanged: (value) {
                      notifier.toggleTheme(value);
                      setState(() {}); 
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Locale>(
                    value: locale,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.language,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: const Locale('ru'),
                        child: Text('Русский'),
                      ),
                      DropdownMenuItem(
                        value: const Locale('en'),
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (locale) {
                      if (locale != null) {
                        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                        ref.read(localeProvider.notifier).setLocale(locale);
                        setState(() {
                          locale = locale;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(AppLocalizations.of(context)!.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

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

  bool containsSqlInjection(String input) {
    final RegExp sqlInjectionPattern = RegExp(
      r'(\b(?:SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|EXEC|UNION|CREATE|WHERE|OR|AND)\b)|(--)|(;)',
      caseSensitive: false,
    );

    return sqlInjectionPattern.hasMatch(input);
  }

  String? validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.enterLogin;
    }

    final RegExp loginRegExp = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!loginRegExp.hasMatch(value)) {
      return AppLocalizations.of(context)!.usernameFormatHint;
    }

    return null;
  }

  Future<void> _signIn() async {
    setState(() {
      _loginError = null;
      _passwordError = null;
      _isLoading = true;
    });

    try {
      final login = _loginController.text.trim();
      final password = _passwordController.text.trim();

      final loginValidation = validateLogin(login);
      if (loginValidation != null) {
        setState(() {
          _loginError = loginValidation;
          _isLoading = false;
        });
        return;
      }

      if (password.isEmpty) {
        setState(() {
          _passwordError = AppLocalizations.of(context)!.enterPassword;
          _isLoading = false;
        });
        return;
      }

      if (password.length < 6) {
        setState(() {
          _passwordError = AppLocalizations.of(context)!.passwordTooShort;
          _isLoading = false;
        });
        return;
      }

      if (containsSqlInjection(login) || containsSqlInjection(password)) {
        _showErrorDialog(
            AppLocalizations.of(context)!.invalidCharactersDetected);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userInDb = await supabase
          .from('users')
          .select('email')
          .eq('login', login)
          .maybeSingle();

      String? email;

      if (userInDb != null) {
        email = userInDb['email'] as String;
      } else {
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

      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', _rememberMe);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home_page');
        }
      }
    } catch (error) {
      String errorMessage = AppLocalizations.of(context)!.signInError;
      if (error is AuthException) {
        switch (error.message) {
          case 'Invalid login credentials':
            errorMessage = AppLocalizations.of(context)!.invalidCredentials;
            break;
          case 'Email not confirmed':
            errorMessage = AppLocalizations.of(context)!.emailNotConfirmed;
            break;
          case 'Invalid password':
            errorMessage = AppLocalizations.of(context)!.invalidPassword;
            break;
          default:
            errorMessage = AppLocalizations.of(context)!
                .errorWithDetails(error.toString());
        }
      }
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(''),
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, ref),
            tooltip: AppLocalizations.of(context)!.settings,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () => Navigator.pushNamed(context, '/registration'),
              tooltip: AppLocalizations.of(context)!.registration,
            ),
          ],
        ),
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
                      Icon(
                        Icons.account_circle,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Text(
                        AppLocalizations.of(context)!.signIn,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      _gap(),

                      TextFormField(
                        controller: _loginController,
                        focusNode: _loginFocusNode,
                        textCapitalization: TextCapitalization.none,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_passwordFocusNode);
                        },
                        validator: validateLogin,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.login,
                          hintText: AppLocalizations.of(context)!.enterLogin,
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const OutlineInputBorder(),
                          errorText: _loginError,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9_]')),
                        ],
                      ),
                      _gap(),

                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        textInputAction: TextInputAction.done,
                        obscureText: !_isPasswordVisible,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.enterPassword;
                          }
                          if (value.length < 6) {
                            return AppLocalizations.of(context)!
                                .passwordTooShort;
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                          hintText: AppLocalizations.of(context)!.enterPassword,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: const OutlineInputBorder(),
                          errorText: _passwordError,
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            tooltip: _isPasswordVisible
                                ? AppLocalizations.of(context)!.hidePassword
                                : AppLocalizations.of(context)!.showPassword,
                          ),
                        ),
                      ),
                      _gap(),

                      CheckboxListTile(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? true;
                          });
                        },
                        title: Text(AppLocalizations.of(context)!.rememberMe),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      _gap(),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      FocusScope.of(context).unfocus();

                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        _signIn();
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
                                      AppLocalizations.of(context)!.signIn,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordPage()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.forgotPassword,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _gap(),
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

  Widget _gap() => const SizedBox(height: 16);

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _loginFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}
