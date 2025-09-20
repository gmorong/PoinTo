import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const EditProfilePage({Key? key, required this.profileData})
      : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _organizationController;
  late TextEditingController _aboutController;
  File? _newAvatar;

  // Переменные для хранения состояния полей
  String? _completePhoneNumber;
  bool _isPhoneValid = true;
  String? _firstNameError;
  String? _lastNameError;
  String? _aboutError;
  String? _organizationError;
  
  // Добавляем переменную для хранения начального кода страны
  late String _initialCountryCode;
  // Добавляем FocusNode для поля телефона
  final FocusNode _phoneFocusNode = FocusNode();
  
  // Переменная для хранения текущей выбранной страны
  // ignore: unused_field
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.profileData['first_name'] ?? '');
    _lastNameController =
        TextEditingController(text: widget.profileData['last_name'] ?? '');
        
    // Инициализируем полный номер телефона
    _completePhoneNumber = widget.profileData['phone'];
    
    // Определяем начальный код страны из сохраненного номера
    _initialCountryCode = _getCountryCodeFromFullNumber(_completePhoneNumber);
    
    // Здесь ключевое изменение: корректно извлекаем локальный номер, 
    // чтобы он не содержал код страны
    _phoneController = TextEditingController(
        text: _completePhoneNumber != null && _completePhoneNumber!.isNotEmpty
            ? _extractLocalNumberCorrectly(_completePhoneNumber!, _initialCountryCode)
            : '');
            
    _organizationController =
        TextEditingController(text: widget.profileData['organization'] ?? '');
    _aboutController =
        TextEditingController(text: widget.profileData['about'] ?? '');
        
    // Находим объект страны по коду
    _selectedCountry = countries.firstWhere(
      (c) => c.code == _initialCountryCode,
      orElse: () => countries.firstWhere((c) => c.code == 'RU'),
    );
    
    // Для отладки - показываем найденный код страны и локальный номер
    print('Полный номер: $_completePhoneNumber');
    print('Код страны: $_initialCountryCode');
    print('Локальный номер: ${_phoneController.text}');
  }

  // Более надежный метод для извлечения номера с учетом кода страны
  String _extractLocalNumberCorrectly(String fullNumber, String countryCode) {
    if (fullNumber.isEmpty) return '';
    
    // Получаем информацию о выбранной стране
    Country country = countries.firstWhere(
      (c) => c.code == countryCode,
      orElse: () => countries.firstWhere((c) => c.code == 'RU'),
    );
    
    String dialCode = '+${country.dialCode}';
    
    // Проверяем, начинается ли номер с кода страны
    if (fullNumber.startsWith(dialCode)) {
      // Удаляем код страны и любые начальные пробелы
      String localPart = fullNumber.substring(dialCode.length).trim();
      
      // Удаляем также любые скобки, дефисы или другие разделители, 
      // которые могли быть добавлены к номеру
      // (это нужно, чтобы IntlPhoneField мог правильно форматировать номер)
      localPart = localPart.replaceAll(RegExp(r'[\(\)\-\s]+'), '');
      
      return localPart;
    }
    
    // Если номер не начинается с кода страны, возвращаем его как есть
    return fullNumber;
  }

  // Метод для определения кода страны из полного номера
  String _getCountryCodeFromFullNumber(String? fullNumber) {
    if (fullNumber == null || fullNumber.isEmpty) {
      return 'RU'; // Значение по умолчанию
    }
    
    // Проверяем, что номер начинается с '+'
    if (!fullNumber.startsWith('+')) {
      return 'RU'; // Если не начинается с '+', считаем, что это российский номер
    }
    
    // Перебираем все страны и проверяем, есть ли соответствие по коду набора
    for (var country in countries) {
      String dialCode = '+${country.dialCode}';
      if (fullNumber.startsWith(dialCode)) {
        return country.code;
      }
    }
    
    // Если соответствие не найдено, используем простую логику определения страны по коду
    if (fullNumber.startsWith('+7')) return 'RU';
    if (fullNumber.startsWith('+1')) return 'US';
    if (fullNumber.startsWith('+49')) return 'DE';
    if (fullNumber.startsWith('+33')) return 'FR';
    if (fullNumber.startsWith('+39')) return 'IT';
    if (fullNumber.startsWith('+34')) return 'ES';
    if (fullNumber.startsWith('+44')) return 'GB';
    if (fullNumber.startsWith('+86')) return 'CN';
    if (fullNumber.startsWith('+81')) return 'JP';
    
    return 'RU'; // По умолчанию
  }

  // Проверка строки на пустоту или наличие только пробелов
  bool _isEmptyOrWhitespace(String? text) {
    return text == null || text.trim().isEmpty;
  }

  // Проверка на содержание только букв
  bool _containsOnlyLetters(String text) {
    // Используем обычную строку с правильным экранированием
    final RegExp onlyLetters = RegExp("^[a-zA-Zа-яА-ЯёЁ '.-]*\$");
    return onlyLetters.hasMatch(text);
  }

  // Валидация имени/фамилии
  String? _validateName(String? value, String fieldName) {
    if (_isEmptyOrWhitespace(value)) {
      return AppLocalizations.of(context)!.fieldRequired(fieldName);
    }

    if (!_containsOnlyLetters(value!.trim())) {
      return AppLocalizations.of(context)!.fieldOnlyLetters(fieldName);
    }

    return null;
  }

  // Валидация всех полей перед сохранением
  bool _validateForm() {
    bool isValid = true;

    // Проверка имени
    _firstNameError = _validateName(
        _firstNameController.text, AppLocalizations.of(context)!.name);
    if (_firstNameError != null) isValid = false;

    // Проверка фамилии
    _lastNameError = _validateName(
        _lastNameController.text, AppLocalizations.of(context)!.surname);
    if (_lastNameError != null) isValid = false;

    // Проверка организации - может быть пустой, но если заполнена,
    // не должна содержать только пробелы
    if (_organizationController.text.isNotEmpty &&
        _isEmptyOrWhitespace(_organizationController.text)) {
      _organizationError =
          AppLocalizations.of(context)!.fieldCannotBeOnlySpaces;
      isValid = false;
    } else {
      _organizationError = null;
    }

    // Проверка поля "О себе" - может быть пустым, но если заполнено,
    // не должно содержать только пробелы
    if (_aboutController.text.isNotEmpty &&
        _isEmptyOrWhitespace(_aboutController.text)) {
      _aboutError = AppLocalizations.of(context)!.fieldCannotBeOnlySpaces;
      isValid = false;
    } else {
      _aboutError = null;
    }

    // Проверка номера телефона
    if (_completePhoneNumber != null &&
        _completePhoneNumber!.isNotEmpty &&
        !_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.invalidPhoneFormat)),
      );
      isValid = false;
    }

    // Обновляем UI с ошибками
    setState(() {});

    return isValid;
  }

  Future<void> _saveProfile() async {
    // Перед сохранением проверяем валидность номера
    if (_completePhoneNumber != null && _completePhoneNumber!.isNotEmpty && !_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.invalidPhoneFormat),
        ),
      );
      return;
    }

    // Валидация формы
    if (!_validateForm()) {
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    String? avatarUrl;

    if (_newAvatar != null) {
      try {
        final avatarPath = '${user.id}/${DateTime.now().toIso8601String()}.jpg';
        await supabase.storage.from('avatars').upload(avatarPath, _newAvatar!);
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(avatarPath);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .avatarUploadError(e.toString()))),
          );
        }
        return;
      }
    }

    try {
      final updateData = {
        // Сохраняем триммированные значения, чтобы убрать лишние пробелы
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),

        // Для организации и about - если есть только пробелы, сохраняем пустую строку
        'organization': _isEmptyOrWhitespace(_organizationController.text)
            ? ''
            : _organizationController.text.trim(),

        'about': _isEmptyOrWhitespace(_aboutController.text)
            ? ''
            : _aboutController.text.trim(),

        'updated_at': DateTime.now().toIso8601String(),
      };

      // Добавляем новый аватар, если он был загружен
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      // Добавляем телефон в данные только если он не пустой
      if (_completePhoneNumber != null && _completePhoneNumber!.isNotEmpty) {
        updateData['phone'] = _completePhoneNumber!;
      } else {
        // Если телефон пустой, устанавливаем пустую строку
        updateData['phone'] = '';
      }

      await supabase.from('users').update(updateData).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.profileUpdateSuccess)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .profileUpdateError(e.toString()))),
        );
      }
    }
  }

  Future<void> _removeAvatar() async {
    // Создаем локальную переменную для хранения текущего аватара
    final String? oldAvatarUrl = widget.profileData['avatar_url'];

    // Сразу обновляем UI, показывая, что аватар удален
    setState(() {
      _newAvatar = null; // Сбрасываем новый аватар, если он был выбран

      // Временно устанавливаем avatar_url в null только для отображения
      // (не меняя исходные данные в widget.profileData)
      if (widget.profileData.containsKey('avatar_url')) {
        widget.profileData['avatar_url'] = null;
      }
    });

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Обновляем профиль пользователя, устанавливая avatar_url в null
      await supabase.from('users').update({
        'avatar_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.avatarRemoveSuccess)),
        );
      }
    } catch (e) {
      // Если произошла ошибка, восстанавливаем предыдущее состояние аватара
      if (mounted) {
        setState(() {
          if (widget.profileData.containsKey('avatar_url')) {
            widget.profileData['avatar_url'] = oldAvatarUrl;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .avatarRemoveError(e.toString()))),
        );
      }
    }
  }

  Future<void> _pickAvatar() async {
    // Проверяем, есть ли аватар для возможности его удаления
    final bool hasAvatar =
        _newAvatar != null || widget.profileData['avatar_url'] != null;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(AppLocalizations.of(context)!.takePhoto),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _newAvatar = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)!.chooseFromGallery),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _newAvatar = File(pickedFile.path);
                    });
                  }
                },
              ),
              // Добавляем опцию удаления, если есть аватар
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    AppLocalizations.of(context)!.removeAvatar,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Показываем диалог подтверждения
                    _showRemoveAvatarConfirmation();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showRemoveAvatarConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmRemoveAvatar),
          content: Text(AppLocalizations.of(context)!.removeAvatarConfirmation),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.remove,
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () {
                // Сначала закрываем диалог
                Navigator.of(dialogContext).pop();
                // Затем вызываем функцию удаления аватара
                _removeAvatar();
              },
            ),
          ],
        );
      },
    );
  }

  // Функция для показа формата телефона выбранной страны
  void _showPhoneFormat(Country country) {
    // Получаем примерный формат телефона в зависимости от страны
    String format = '';
    
    // Соответствие кодов стран и примеров форматов
    // Добавьте больше стран по необходимости
    switch (country.code) {
      case 'RU': 
        format = '+7 (XXX) XXX-XX-XX';
        break;
      case 'US': 
        format = '+1 (XXX) XXX-XXXX';
        break;
      case 'DE': 
        format = '+49 XXXX XXXXXXX';
        break;
      case 'GB': 
        format = '+44 XXXX XXXXXX';
        break;
      case 'FR': 
        format = '+33 X XX XX XX XX';
        break;
      default:
        // Создаем примерный формат из длины номера
        format = '+${country.dialCode} ';
        for (int i = 0; i < country.maxLength; i++) {
          format += 'X';
          // Добавляем пробел каждые 3-4 символа для наглядности
          if (i > 0 && i % 3 == 0 && i < country.maxLength - 1) {
            format += ' ';
          }
        }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppLocalizations.of(context)!.exampleFormat}: $format'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.edit_profile ??
            AppLocalizations.of(context)!.edit_profile),
      ),
      body: GestureDetector(
        // Скрываем клавиатуру при тапе за пределами полей ввода
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _newAvatar != null
                          ? Image.file(
                              _newAvatar!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 150,
                                  height: 150,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: const Icon(Icons.error, size: 60),
                                );
                              },
                            )
                          : widget.profileData['avatar_url'] != null
                              ? Image.network(
                                  widget.profileData['avatar_url'],
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 150,
                                      height: 150,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Icon(Icons.error, size: 60),
                                    );
                                  },
                                )
                              : Container(
                                  width: 150,
                                  height: 150,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: const Icon(Icons.person, size: 100),
                                ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Поле имени с валидацией
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.name ??
                      AppLocalizations.of(context)!.name,
                  errorText: _firstNameError,
                  border: const OutlineInputBorder(),
                  helperText: AppLocalizations.of(context)!.onlyLetters,
                ),
                // Фильтр на ввод - разрешаем только буквы и некоторые символы
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp("[a-zA-Zа-яА-ЯёЁ '.-]")),
                ],
                onChanged: (value) {
                  // Очищаем ошибку при вводе
                  if (_firstNameError != null) {
                    setState(() {
                      _firstNameError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Поле фамилии с валидацией
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.surname ??
                      AppLocalizations.of(context)!.surname,
                  errorText: _lastNameError,
                  border: const OutlineInputBorder(),
                  helperText: AppLocalizations.of(context)!.onlyLetters,
                ),
                // Фильтр на ввод - разрешаем только буквы и некоторые символы
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp("[a-zA-Zа-яА-ЯёЁ '.-]")),
                ],
                onChanged: (value) {
                  // Очищаем ошибку при вводе
                  if (_lastNameError != null) {
                    setState(() {
                      _lastNameError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Поле телефона с определением кода страны
              IntlPhoneField(
                focusNode: _phoneFocusNode,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.phone ??
                      AppLocalizations.of(context)!.phone,
                  border: const OutlineInputBorder(),
                  helperText: AppLocalizations.of(context)!.optionalField,
                ),
                controller: _phoneController,
                initialCountryCode: _initialCountryCode, // Используем определенный код страны
                disableLengthCheck: false, // Включаем проверку длины номера
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (phoneNumber) {
                  // Если поле пустое - считаем валидным (необязательное поле)
                  if (phoneNumber == null || phoneNumber.number.isEmpty) {
                    setState(() {
                      _isPhoneValid = true;
                      _completePhoneNumber = null;
                    });
                    return null;
                  }

                  // Проверяем на валидность через внутренний API библиотеки
                  if (!phoneNumber.isValidNumber()) {
                    setState(() {
                      _isPhoneValid = false;
                    });
                    return AppLocalizations.of(context)!.invalidPhoneFormat;
                  }

                  setState(() {
                    _isPhoneValid = true;
                  });
                  return null;
                },
                onChanged: (phone) {
                  // Если поле пустое - сохраняем null, иначе полный номер
                  setState(() {
                    if (phone.number.isEmpty) {
                      _completePhoneNumber = null;
                    } else {
                      _completePhoneNumber = phone.completeNumber;
                    }

                    // Проверяем валидность при изменении
                    _isPhoneValid = phone.number.isEmpty || phone.isValidNumber();
                  });
                },
                onCountryChanged: (country) {
                  // При смене страны показываем пример формата
                  _phoneController.clear();
                  setState(() {
                    _completePhoneNumber = null;
                    _selectedCountry = country;
                  });
                  
                  // Показываем пример формата
                  _showPhoneFormat(country);
                },
              ),
              const SizedBox(height: 16),

              // Поле организации
              TextField(
                controller: _organizationController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.organization ??
                      AppLocalizations.of(context)!.organization,
                  errorText: _organizationError,
                  border: const OutlineInputBorder(),
                  helperText: AppLocalizations.of(context)!.optionalField,
                ),
                onChanged: (value) {
                  // Очищаем ошибку при вводе
                  if (_organizationError != null) {
                    setState(() {
                      _organizationError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Поле о себе
              TextField(
                controller: _aboutController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.aboutMe ??
                      AppLocalizations.of(context)!.aboutMe,
                  errorText: _aboutError,
                  border: const OutlineInputBorder(),
                  helperText: AppLocalizations.of(context)!.optionalField,
                ),
                maxLines: 3,
                onChanged: (value) {
                  // Очищаем ошибку при вводе
                  if (_aboutError != null) {
                    setState(() {
                      _aboutError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.save ??
                        AppLocalizations.of(context)!.save,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _aboutController.dispose();
    _phoneFocusNode.dispose(); // Освобождаем ресурсы FocusNode
    super.dispose();
  }
}