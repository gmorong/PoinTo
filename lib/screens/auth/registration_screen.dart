import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _loginFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;

  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    
    String sanitized = input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
    
    return sanitized.trim();
  }

  String sanitizeLogin(String input) {
    if (input.isEmpty) return input;
    
    final RegExp allowedChars = RegExp(r'[^a-zA-Z0-9_]');
    return input.replaceAll(allowedChars, '').trim();
  }

  String? validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.enterLogin;
    }
    
    final RegExp loginRegExp = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!loginRegExp.hasMatch(value)) {
      return AppLocalizations.of(context)!.invalidCharactersDetected;
    }
    
    if (value.length < 4) {
      return AppLocalizations.of(context)!.loginMinLength;
    }
    
    if (value.length > 15) {
      return AppLocalizations.of(context)!.loginMaxLength;
    }
    
    return null;
  }

  Future<void> _signUp() async {
    final login = sanitizeLogin(_loginController.text.trim());
    final email = sanitizeInput(_emailController.text.trim());
    final password = _passwordController.text.trim();
    final firstName = sanitizeInput(_firstNameController.text.trim());
    final lastName = sanitizeInput(_lastNameController.text.trim());

    try {
      if (password != _confirmPasswordController.text.trim()) {
        _showErrorDialog(
          AppLocalizations.of(context)!.errorTitle,
          AppLocalizations.of(context)!.passwordsDoNotMatch,
        );
        return;
      }

      final existingLogin = await supabase
          .from('users')
          .select('login')
          .eq('login', login)
          .maybeSingle();

      final existingLoginUnconfirmed = await supabase
          .from('unconfirmed_users')
          .select('login')
          .eq('login', login)
          .maybeSingle();

      if (existingLogin != null || existingLoginUnconfirmed != null) {
        _showErrorDialog(
          AppLocalizations.of(context)!.errorTitle,
          AppLocalizations.of(context)!.loginAlreadyExists,
        );
        return;
      }

      final existingEmail = await supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      final existingEmailUnconfirmed = await supabase
          .from('unconfirmed_users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (existingEmail != null || existingEmailUnconfirmed != null) {
        _showErrorDialog(
          AppLocalizations.of(context)!.errorTitle,
          AppLocalizations.of(context)!.emailAlreadyExists,
        );
        return;
      }

      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        final userId = authResponse.user!.id;

        await supabase.from('unconfirmed_users').insert({
          'id': userId,
          'email': email,
          'login': login,
          'first_name': firstName,
          'last_name': lastName,
        });

        _showInfoDialog(
          AppLocalizations.of(context)!.registrationSuccessful,
          AppLocalizations.of(context)!.pleaseConfirmEmail,
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        _showErrorDialog(
          AppLocalizations.of(context)!.registrationError,
          AppLocalizations.of(context)!.somethingWentWrong,
        );
      }
    } on AuthException catch (e) {
      String errorMessage =
          AppLocalizations.of(context)!.registrationErrorWithDetails(e.message);
      if (e.message.contains('already registered')) {
        errorMessage = AppLocalizations.of(context)!.emailAlreadyRegistered;
      } else if (e.message.contains('invalid email')) {
        errorMessage = AppLocalizations.of(context)!.invalidEmailFormat;
      } else if (e.message.contains('weak password')) {
        errorMessage = AppLocalizations.of(context)!.weakPassword;
      }
      _showErrorDialog(
        AppLocalizations.of(context)!.registrationError,
        errorMessage,
      );
    } catch (e) {
      _showErrorDialog(
        AppLocalizations.of(context)!.errorTitle,
        AppLocalizations.of(context)!.errorWithDetails(e.toString()),
      );
       Navigator.pushNamed(context, '/test_con');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
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

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
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

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.enterEmail;
    }
    
    if (containsSqlInjection(value)) {
      return AppLocalizations.of(context)!.invalidCharactersError;
    }
    
    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return AppLocalizations.of(context)!.invalidEmailFormat;
    }
    
    return null;
  }

  String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.pleaseEnterField(fieldName);
    }
    
    if (containsSqlInjection(value)) {
      return AppLocalizations.of(context)!.invalidCharactersError;
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.registration),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: Card(
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(32.0),
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _loginController,
                      focusNode: _loginFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_emailFocusNode);
                      },
                      validator: validateLogin,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.login,
                        hintText: AppLocalizations.of(context)!.enterLogin,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: const OutlineInputBorder(),
                        helperText: AppLocalizations.of(context)!.usernameFormatRestriction,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final sanitized = sanitizeLogin(value);
                          if (sanitized != value) {
                            _loginController.value = TextEditingValue(
                              text: sanitized,
                              selection: TextSelection.collapsed(offset: sanitized.length),
                            );
                          }
                        }
                      },
                    ),
                    _gap(),
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_firstNameFocusNode);
                      },
                      validator: validateEmail,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.email,
                        hintText: AppLocalizations.of(context)!.enterEmail,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    _gap(),
                    TextFormField(
                      controller: _firstNameController,
                      focusNode: _firstNameFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_lastNameFocusNode);
                      },
                      validator: (value) => validateName(value, AppLocalizations.of(context)!.firstName),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.firstName,
                        hintText: AppLocalizations.of(context)!.enterFirstName,
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    _gap(),
                    TextFormField(
                      controller: _lastNameController,
                      focusNode: _lastNameFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                      validator: (value) => validateName(value, AppLocalizations.of(context)!.lastName),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.lastName,
                        hintText: AppLocalizations.of(context)!.enterLastName,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    _gap(),
                    _buildPasswordField(
                      _passwordController,
                      AppLocalizations.of(context)!.password,
                      AppLocalizations.of(context)!.enterPassword,
                      isVisible: _isPasswordVisible,
                      onToggle: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      focusNode: _passwordFocusNode,
                      nextFocusNode: _confirmPasswordFocusNode,
                    ),
                    _gap(),
                    _buildPasswordField(
                      _confirmPasswordController,
                      AppLocalizations.of(context)!.confirmPassword,
                      AppLocalizations.of(context)!.repeatPassword,
                      isVisible: _isConfirmPasswordVisible,
                      onToggle: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                      focusNode: _confirmPasswordFocusNode,
                      nextFocusNode: null,
                    ),
                    _gap(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _signUp();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            AppLocalizations.of(context)!.signUp,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    _gap(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      TextEditingController controller, String label, String hint,
      {required bool isVisible,
      required VoidCallback onToggle,
      FocusNode? focusNode,
      FocusNode? nextFocusNode}) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !isVisible,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseEnterField(label);
        }
        if (controller == _passwordController && value.length < 6) {
          return AppLocalizations.of(context)!.passwordTooShort;
        }
        if (controller == _confirmPasswordController &&
            value != _passwordController.text) {
          return AppLocalizations.of(context)!.passwordsDoNotMatch;
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 16);
}