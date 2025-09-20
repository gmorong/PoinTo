import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';
import 'dart:async';
import 'deep_link_handler.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isLoading = false;
  String? _recoveryToken;
  String? _userEmail;

  final SupabaseClient supabase = Supabase.instance.client;
  late StreamSubscription _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _initParams();
  }

  void _initParams() {
    // Получаем текущие значения из обработчика
    final handler = DeepLinkHandler();
    _recoveryToken = handler.recoveryToken;
    _userEmail = handler.userEmail;

    print("Initial params from handler:");
    print(
        "Token: ${_recoveryToken != null ? (_recoveryToken!.length > 10 ? '${_recoveryToken!.substring(0, 10)}...' : _recoveryToken) : 'null'}");
    print("Email: $_userEmail");

    // Подписываемся на изменения
    _deepLinkSubscription = handler.paramsStream.listen((params) {
      setState(() {
        _recoveryToken = params['token'];
        _userEmail = params['email'];
      });

      print("Updated params from stream:");
      print(
          "Token: ${_recoveryToken != null ? (_recoveryToken!.length > 10 ? '${_recoveryToken!.substring(0, 10)}...' : _recoveryToken) : 'null'}");
      print("Email: $_userEmail");
    });
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final password = _newPasswordController.text;

      // Проверка наличия токена и email
      if (_recoveryToken == null || _userEmail == null) {
        _showErrorDialog(
          AppLocalizations.of(context)!.missingRecoveryParamsTitle,
          AppLocalizations.of(context)!.missingRecoveryParamsMessage,
        );
        return;
      }

      print("Attempting password update with:");
      print(
          "Token: ${_recoveryToken!.length > 10 ? '${_recoveryToken!.substring(0, 10)}...' : _recoveryToken}");
      print("Email: $_userEmail");

      // Метод 1: Используем verifyOTP и updateUser
      try {
        print("Method 1: Using verifyOTP and updateUser");

        final response = await supabase.auth.verifyOTP(
          type: OtpType.recovery,
          token: _recoveryToken!,
          email: _userEmail!,
        );

        if (response.session != null) {
          print("OTP verified, session created");

          final updateResult = await supabase.auth.updateUser(
            UserAttributes(password: password),
          );

          if (updateResult.user != null) {
            print("Password updated successfully");
            _showSuccessDialog(
              AppLocalizations.of(context)!.passwordResetSuccess,
              AppLocalizations.of(context)!.passwordHasBeenReset,
            );
            return;
          }
        }
      } catch (e) {
        print("Error in method 1: $e");
      }

      // Метод 2: Пробуем сначала запросить OTP
      try {
        print("Method 2: Using signInWithOtp and then verifyOTP");

        await supabase.auth.signInWithOtp(
          email: _userEmail!,
          shouldCreateUser: false,
        );

        final response = await supabase.auth.verifyOTP(
          type: OtpType.recovery,
          token: _recoveryToken!,
          email: _userEmail!,
        );

        if (response.session != null) {
          final updateResult = await supabase.auth.updateUser(
            UserAttributes(password: password),
          );

          if (updateResult.user != null) {
            print("Password updated successfully via method 2");
            _showSuccessDialog(
              AppLocalizations.of(context)!.passwordResetSuccess,
              AppLocalizations.of(context)!.passwordHasBeenReset,
            );
            return;
          }
        }
      } catch (e) {
        print("Error in method 2: $e");
      }

      // Метод 3: Пробуем напрямую обновить пароль
      try {
        print("Method 3: Direct password update");

        final updateResult = await supabase.auth.updateUser(
          UserAttributes(password: password),
        );

        if (updateResult.user != null) {
          print("Password updated successfully via method 3");
          _showSuccessDialog(
            AppLocalizations.of(context)!.passwordResetSuccess,
            AppLocalizations.of(context)!.passwordHasBeenReset,
          );
          return;
        }
      } catch (e) {
        print("Error in method 3: $e");
      }

      // Если все методы не сработали
      _showRetryDialog();
    } catch (e) {
      print("Error updating password: $e");
      _showErrorDialog(
        AppLocalizations.of(context)!.errorTitle,
        e.toString(),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _deepLinkSubscription.cancel();
    super.dispose();
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.sessionExpired),
        content: Text(AppLocalizations.of(context)!.sessionExpiredMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/signin');
            },
            child: Text(AppLocalizations.of(context)!.backToSignIn),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/forgot_password');
            },
            child: Text(AppLocalizations.of(context)!.tryAgain),
          ),
        ],
      ),
    );
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

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                
                Navigator.of(context).pop(); // Закрываем диалог
                // Переходим на экран входа
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/signin',
                  (route) => false,
                );
                
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.resetPassword),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
                        Icons.lock_reset,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Text(
                        AppLocalizations.of(context)!.createNewPassword,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      _gap(),
                      Text(
                        AppLocalizations.of(context)!
                            .createNewPasswordInstructions,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      _gap(),
                      _buildPasswordField(
                        _newPasswordController,
                        AppLocalizations.of(context)!.newPassword,
                        AppLocalizations.of(context)!.enterNewPassword,
                        isVisible: _isNewPasswordVisible,
                        onToggle: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        },
                        focusNode: _newPasswordFocusNode,
                        nextFocusNode: _confirmPasswordFocusNode,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .pleaseEnterField(
                              AppLocalizations.of(context)!.newPassword,
                            );
                          }
                          if (value.length < 6) {
                            return AppLocalizations.of(context)!
                                .passwordTooShort;
                          }
                          return null;
                        },
                      ),
                      _gap(),
                      _buildPasswordField(
                        _confirmPasswordController,
                        AppLocalizations.of(context)!.confirmNewPassword,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .pleaseEnterField(
                              AppLocalizations.of(context)!.confirmNewPassword,
                            );
                          }
                          if (value != _newPasswordController.text) {
                            return AppLocalizations.of(context)!
                                .passwordsDoNotMatch;
                          }
                          return null;
                        },
                      ),
                      _gap(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    _updatePassword();
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
                                  AppLocalizations.of(context)!.updatePassword,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
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

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    String hint, {
    required bool isVisible,
    required VoidCallback onToggle,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !isVisible,
      textInputAction:
          nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
      validator: validator,
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
