import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для полей
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Фокус-ноды для управления фокусом
  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  // Состояния видимости паролей
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Флаг загрузки
  bool _isLoading = false;

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception(AppLocalizations.of(context)!.userNotFound);
      }

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      if (response.session == null || response.user == null) {
        throw Exception(AppLocalizations.of(context)!.incorrectCurrentPassword);
      }

      final updateResponse = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text,
        ),
      );

      if (updateResponse.user == null) {
        throw Exception(AppLocalizations.of(context)!.failedToUpdatePassword);
      }

      _showInfoDialog(
        AppLocalizations.of(context)!.passwordChangeSuccess,
        AppLocalizations.of(context)!.passwordChanged,
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pop();
      });
    } on AuthException catch (e) {
      String errorMessage =
          AppLocalizations.of(context)!.errorWithDetails(e.message);
      if (e.message.contains('weak password')) {
        errorMessage = AppLocalizations.of(context)!.weakPassword;
      }
      _showErrorDialog(
        AppLocalizations.of(context)!.errorTitle,
        errorMessage,
      );
    } catch (e) {
      _showErrorDialog(
        AppLocalizations.of(context)!.errorTitle,
        AppLocalizations.of(context)!.errorWithDetails(e.toString()),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.changePassword),
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
                    // Текущий пароль
                    _buildPasswordField(
                      _currentPasswordController,
                      AppLocalizations.of(context)!.currentPassword,
                      AppLocalizations.of(context)!.enterCurrentPassword,
                      isVisible: _isCurrentPasswordVisible,
                      onToggle: () {
                        setState(() {
                          _isCurrentPasswordVisible =
                              !_isCurrentPasswordVisible;
                        });
                      },
                      focusNode: _currentPasswordFocusNode,
                      nextFocusNode: _newPasswordFocusNode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pleaseEnterField(
                            AppLocalizations.of(context)!.currentPassword,
                          );
                        }
                        return null;
                      },
                    ),
                    _gap(),

                    // Новый пароль
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
                          return AppLocalizations.of(context)!.pleaseEnterField(
                            AppLocalizations.of(context)!.newPassword,
                          );
                        }
                        if (value.length < 6) {
                          return AppLocalizations.of(context)!.passwordTooShort;
                        }
                        if (value == _currentPasswordController.text) {
                          return AppLocalizations.of(context)!
                              .newPasswordSameAsOld;
                        }
                        return null;
                      },
                    ),
                    _gap(),

                    // Подтверждение нового пароля
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
                          return AppLocalizations.of(context)!.pleaseEnterField(
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

                    // Кнопка смены пароля
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  _changePassword();
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  AppLocalizations.of(context)!.changePassword,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
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
