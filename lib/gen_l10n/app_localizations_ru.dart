// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get general => 'Общее';

  @override
  String get language => 'Язык';

  @override
  String get settings => 'Настройки';

  @override
  String get profile => 'Профиль';

  @override
  String get exit => 'Выход';

  @override
  String get dark_mode => 'Тёмная тема';

  @override
  String get about_developer => 'О разработчике';

  @override
  String get change_order => 'Изменить порядок';

  @override
  String get add_task => 'Добавить задачу';

  @override
  String get task_options => 'Настройки задачи';

  @override
  String get edit_task => 'Редактировать задачу';

  @override
  String get delete_task => 'Удалить задачу';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get edit_name => 'Изменить имя';

  @override
  String get add_member => 'Добавить участника';

  @override
  String get sort_items => 'Сортировать элементы';

  @override
  String get task_members => 'Участники задачи';

  @override
  String get close => 'Закрыть';

  @override
  String get admin => 'Администратор';

  @override
  String get editor => 'Редактор';

  @override
  String get user => 'Пользователь';

  @override
  String get select_user => 'Выбрать пользователя';

  @override
  String get select_role => 'Выбрать роль';

  @override
  String get about_role => 'О роли';

  @override
  String get add => 'Добавить';

  @override
  String get okay => 'Окей';

  @override
  String get name => 'Имя';

  @override
  String get edit_profile => 'Редактировать профиль';

  @override
  String get friends => 'Друзья';

  @override
  String get surname => 'Фамилия';

  @override
  String get select_avatar => 'Выбрать аватар';

  @override
  String get incoming_requests => 'Входящие запросы';

  @override
  String get outgoing_requests => 'Исходящие запросы';

  @override
  String get friends_email => 'Email друга';

  @override
  String get task_name => 'Название';

  @override
  String authorLabel(Object name) {
    return 'Автор: $name';
  }

  @override
  String get unknown => 'Неизвестно';

  @override
  String get createdByMe => 'Создано мной';

  @override
  String get yourTasksWillAppearHere => 'Здесь будут ваши задачи';

  @override
  String get exitFromTask => 'Выйти из задачи';

  @override
  String get deleteTask => 'Удалить задачу';

  @override
  String get delete => 'Удалить';

  @override
  String get confirmDeleteTask => 'Вы уверены, что хотите удалить эту задачу?';

  @override
  String get confirmDeletion => 'Подтвердите удаление';

  @override
  String get taskNameCannotBeEmpty => 'Название задачи не может быть пустым';

  @override
  String get newTaskName => 'Новое название задачи';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get lastNameNotSpecified => 'Фамилия не указана';

  @override
  String get firstNameNotSpecified => 'Имя не указано';

  @override
  String errorSendingFriendRequest(String error) {
    return 'Ошибка отправки запроса в друзья: $error';
  }

  @override
  String errorWithDetails(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get friendRequestSent => 'Заявка отправлена';

  @override
  String get friendRequestAlreadySentOrFriend =>
      'Заявка уже отправлена или пользователь уже ваш друг';

  @override
  String get userNotFound => 'Пользователь не найден';

  @override
  String get needToLogin => 'Необходимо войти в систему';

  @override
  String get emailCannotBeEmpty => 'Email не может быть пустым';

  @override
  String get send => 'Отправить';

  @override
  String get enterEmailHint => 'Введите email';

  @override
  String get addFriendTitle => 'Добавить друга';

  @override
  String errorWhileExiting(String error) {
    return 'Ошибка при выходе: $error';
  }

  @override
  String errorUpdatingProfile(Object error) {
    return 'Ошибка обновления профиля: $error';
  }

  @override
  String get profileUpdateSuccess => 'Профиль успешно обновлен';

  @override
  String avatarUploadError(String error) {
    return 'Ошибка загрузки аватара: $error';
  }

  @override
  String get enterTextHint => 'Введите текст...';

  @override
  String get noTaskItems => 'В задаче нет элементов';

  @override
  String get tapToAddFirstItem =>
      'Нажмите \'+\', чтобы добавить первый элемент';

  @override
  String get noPermissionToAddItems =>
      'У вас нет прав для добавления элементов';

  @override
  String saveError(String error) {
    return 'Ошибка сохранения: $error';
  }

  @override
  String roleChanged(Object role) {
    return 'Ваша роль изменена на: $role';
  }

  @override
  String get removedFromTask => 'Вы были удалены из этой задачи';

  @override
  String get emptyNoteDeleted => 'Пустая заметка удалена';

  @override
  String errorSavingContent(String error) {
    return 'Ошибка сохранения содержимого: $error';
  }

  @override
  String genericError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get itemOptionsTitle => 'Параметры элемента';

  @override
  String get itemTypeLabel => 'Тип элемента:';

  @override
  String get deadlineLabel => 'Срок выполнения:';

  @override
  String get notSet => 'Не задан';

  @override
  String get clearDeadline => 'Очистить срок';

  @override
  String get confirmation => 'Подтверждение';

  @override
  String get deleteItemConfirmation =>
      'Вы действительно хотите удалить этот элемент?';

  @override
  String deleteError(String error) {
    return 'Ошибка удаления: $error';
  }

  @override
  String get noDeadline => 'Нет срока';

  @override
  String get today => 'Сегодня';

  @override
  String get tomorrow => 'Завтра';

  @override
  String overdueWithDate(String date) {
    return 'Просрочено ($date)';
  }

  @override
  String get invalidDate => 'Некорректная дата';

  @override
  String get noAvailableItemTypes => 'Нет доступных типов элементов';

  @override
  String get selectItemType => 'Выберите тип элемента';

  @override
  String genericErrorWithDetails(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get addNoteTooltip => 'Добавить заметку';

  @override
  String get sortItemsTitle => 'Сортировать элементы';

  @override
  String get membersTooltip => 'Участники';

  @override
  String get taskDetailsTitle => 'Детали задачи';

  @override
  String taskLoadingError(String error) {
    return 'Не удалось загрузить данные задачи: $error';
  }

  @override
  String updatePositionError(String itemId) {
    return 'Не удалось обновить позицию для элемента $itemId';
  }

  @override
  String sortError(String error) {
    return 'Ошибка при сортировке: $error';
  }

  @override
  String get itemsSorted => 'Элементы отсортированы';

  @override
  String get completedFirst => 'Сначала выполненные';

  @override
  String get incompleteFirst => 'Сначала невыполненные';

  @override
  String get deadlineLateFirst => 'По дедлайну (сначала поздние)';

  @override
  String get deadlineEarlyFirst => 'По дедлайну (сначала ранние)';

  @override
  String get userRoleUser => 'Пользователь';

  @override
  String get userRoleEditor => 'Редактор';

  @override
  String get userRoleAdmin => 'Администратор';

  @override
  String get rolesInfoDescription =>
      'Администратор: полный доступ\nРедактор: может редактировать задачи\nПользователь: только просмотр';

  @override
  String get selectNewMemberRole => 'Выберите новую роль участника';

  @override
  String failedToLoadMembers(String error) {
    return 'Не удалось загрузить участников: $error';
  }

  @override
  String get you => 'Вы';

  @override
  String get roleUpdated => 'Роль обновлена';

  @override
  String get creator => 'Создатель';

  @override
  String get noMembers => 'Нет участников';

  @override
  String get taskCreatorNotFound => 'Создатель задачи не найден';

  @override
  String get leftTask => 'Вы покинули задачу';

  @override
  String get leave => 'Покинуть';

  @override
  String get leaveTaskConfirmation =>
      'Вы уверены, что хотите покинуть эту задачу? Вы потеряете доступ к ней.';

  @override
  String get leaveTask => 'Покинуть задачу';

  @override
  String get memberRemoved => 'Участник удален';

  @override
  String get removeMemberTitle => 'Удалить участника';

  @override
  String get removeMemberConfirmation =>
      'Вы уверены, что хотите удалить этого участника из задачи?';

  @override
  String get emptyTaskNameError => 'Название не может быть пустым';

  @override
  String get editTaskTitle => 'Редактировать название задачи';

  @override
  String errorWhileAdding(String error) {
    return 'Ошибка при добавлении: $error';
  }

  @override
  String get userAdded => 'Пользователь добавлен';

  @override
  String get ok => 'Понятно';

  @override
  String get userRoleUserDescription =>
      'Только просмотр и отметка о выполнении пунктов';

  @override
  String get userRoleEditorDescription =>
      'Может добавлять и редактировать элементы, но не может управлять составом участников';

  @override
  String get userRoleAdminDescription =>
      'Доступ к задаче, включая добавление и редактирование элементов';

  @override
  String get rolesInfoTitle => 'Информация о ролях';

  @override
  String get rolesInfoButton => 'О ролях';

  @override
  String get selectRole => 'Выберите роль:';

  @override
  String get selectUser => 'Выберите пользователя:';

  @override
  String get addParticipant => 'Добавить участника';

  @override
  String get noAvailableUsers => 'Нет доступных пользователей для добавления.';

  @override
  String get darkMode => 'Темная тема';

  @override
  String get error => 'Ошибка';

  @override
  String get login => 'Логин';

  @override
  String get enterLogin => 'Введите логин';

  @override
  String get password => 'Пароль';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get rememberMe => 'Запомнить меня';

  @override
  String get signIn => 'Войти';

  @override
  String get confirmEmailPrompt => 'Пожалуйста, подтвердите почту для входа.';

  @override
  String get loginError => 'Произошла ошибка входа';

  @override
  String get invalidCredentials => 'Неправильный логин или пароль';

  @override
  String get emailNotConfirmed => 'Подтвердите свою почту, чтобы войти';

  @override
  String get invalidPassword => 'Неверный пароль';

  @override
  String errorWhileSigningIn(String error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get signInError => 'Произошла ошибка входа';

  @override
  String get passwordTooShort => 'Пароль должен быть не менее 6 символов';

  @override
  String get registration => 'Регистрация';

  @override
  String get errorTitle => 'Ошибка';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Введите ваш email';

  @override
  String get firstName => 'Имя';

  @override
  String get enterFirstName => 'Введите ваше имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get enterLastName => 'Введите вашу фамилию';

  @override
  String get confirmPassword => 'Подтверждение пароля';

  @override
  String get repeatPassword => 'Повторите пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String pleaseEnterField(String field) {
    return 'Пожалуйста, введите $field';
  }

  @override
  String get loginAlreadyExists => 'Логин уже занят. Выберите другой.';

  @override
  String get emailAlreadyExists => 'Email уже используется.';

  @override
  String get registrationSuccessful => 'Регистрация успешна!';

  @override
  String get pleaseConfirmEmail =>
      'Пожалуйста, подтвердите вашу почту для завершения регистрации.';

  @override
  String get registrationError => 'Ошибка регистрации';

  @override
  String registrationErrorWithDetails(String error) {
    return 'Ошибка регистрации: $error';
  }

  @override
  String get somethingWentWrong => 'Что-то пошло не так. Попробуйте позже.';

  @override
  String get emailAlreadyRegistered => 'Этот email уже зарегистрирован.';

  @override
  String get invalidEmailFormat => 'Неверный формат email.';

  @override
  String get weakPassword => 'Пароль слишком слабый.';

  @override
  String get signUp => 'Зарегистрироваться';

  @override
  String get aboutMe => 'Обо мне';

  @override
  String get organization => 'Организация';

  @override
  String get phone => 'Моб.номер';

  @override
  String get social => 'Соц. информаця';

  @override
  String get friends_login => 'Логин';

  @override
  String get enterLoginHint => 'Введите логин друга';

  @override
  String get errorSendingRequest => 'Ошибка при отправке заявки';

  @override
  String get confirmAddFriendTitle => 'Добавить в друзья?';

  @override
  String confirmAddFriendContent(String login) {
    return 'Добавить пользователя @$login в друзья?';
  }

  @override
  String get friendRequestCancelled => 'Заявка удалена';

  @override
  String friendRequestCancelError(String error) {
    return 'Ошибка при удалении: $error';
  }

  @override
  String get usersNotFound => 'Пользователи не найдены';

  @override
  String friendRequestSendingError(String error) {
    return 'Ошибка при отправке: $error';
  }

  @override
  String get usersWasDelete => 'Ваш друг был удален';

  @override
  String get removeFriend => 'Удалить друга';

  @override
  String get friendProfile => 'Профиль друга';

  @override
  String get userIdMissingError => 'ID друга потерян';

  @override
  String get noFriendsYet => 'У вас пока нет друзей';

  @override
  String get noIncomingRequests => 'Нет входящих заявок';

  @override
  String get noOutgoingRequests => 'Нет исходящих заявок';

  @override
  String get sharedTasksTitle => 'Совместные задачи';

  @override
  String get invalidPhoneNumber =>
      'Пожалуйста, введите корректный номер телефона';

  @override
  String get invalidPhoneFormat => 'Неверный формат номера телефона';

  @override
  String get usernameFormatRestriction =>
      'Только английские буквы,\nцифры и символ \"_\"';

  @override
  String get usernameFormatHint =>
      'Логин может содержать только английские буквы, цифры и символ подчёркивания';

  @override
  String get invalidCharactersDetected =>
      'Обнаружены недопустимые символы в вводимых данных';

  @override
  String get loginMinLength => 'Логин должен содержать не менее 4 символов';

  @override
  String get loginMaxLength => 'Логин должен содержать не более 15 символов';

  @override
  String get optionalField => 'Необязательное поле';

  @override
  String get onlyLetters => 'Только буквы';

  @override
  String get profileEditTitle => 'Редактирование профиля';

  @override
  String get profileUpdated => 'Профиль успешно обновлен';

  @override
  String profileUpdateError(String error) {
    return 'Ошибка обновления профиля: $error';
  }

  @override
  String get fieldCannotBeOnlySpaces =>
      'Поле не может содержать только пробелы';

  @override
  String fieldOnlyLetters(String fieldName) {
    return 'Поле $fieldName может содержать только буквы';
  }

  @override
  String fieldRequired(String fieldName) {
    return 'Поле $fieldName не может быть пустым';
  }

  @override
  String get note => 'Заметка';

  @override
  String get header => 'Заголовок';

  @override
  String get checklist => 'Чек-лист';

  @override
  String get noPermission => 'У вас нет прав для изменений';

  @override
  String get fullName => 'Дмитрий Камков';

  @override
  String get universityShort => 'УрТИСИ СибГУТИ, ПЕ-12б\nКафедра ИСТ';

  @override
  String get universityFull =>
      'Студент УрТИСИ СибГУТИ\nСпециальность: ПО Автономной и Вычислительной Техники\nГруппа: ПЕ-12б\nКафедра ИСТ';

  @override
  String get hobbyTitle => 'Хобби';

  @override
  String get hobbyFigureSkating => 'Фигурное\n катание';

  @override
  String get hobbySnowboard => 'Сноуборд';

  @override
  String get hobbyWakeboard => 'Вейкборд';

  @override
  String get hobbyFootball => 'Футбол';

  @override
  String get quoteTitle => 'Цитата';

  @override
  String get quoteText => '«Там, где другие видят предел — я ищу путь дальше.»';

  @override
  String get contactsTitle => 'Контакты';

  @override
  String get takePhoto => 'Сделать снимок';

  @override
  String get chooseFromGallery => 'Выбрать из галереи';

  @override
  String get avatarRemoveSuccess => 'Аватар успешно удалён';

  @override
  String avatarRemoveError(String error) {
    return 'Ошибка удаления аватара: $error';
  }

  @override
  String get removeAvatar => 'Удалить аватар';

  @override
  String get confirmRemoveAvatar => 'Вы уверены, что хотите удалить аватар?';

  @override
  String get removeAvatarConfirmation => 'Подтверждение удаления аватара';

  @override
  String get remove => 'Удалить';

  @override
  String get avatarRemoved => 'Аватар удалён';

  @override
  String get exampleFormat => 'Пример формата';

  @override
  String get exampleNumber => 'Пример номера';

  @override
  String exampleFormatWithNumber(String number) {
    return 'Пример формата: $number';
  }

  @override
  String roleUpdateError(String error) {
    return 'Ошибка при обновлении роли: $error';
  }

  @override
  String get cannotAddCreatorAsMember =>
      'Невозможно добавить создателя задачи как участника';

  @override
  String get roleChangedLimitedAccess =>
      'Ваша роль была изменена, некоторые функции недоступны';

  @override
  String get updatingPositions => 'Обновление позиций';

  @override
  String get changePassword => 'Сменить пароль';

  @override
  String get currentPassword => 'Текущий пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmNewPassword => 'Подтвердите новый пароль';

  @override
  String get enterCurrentPassword => 'Введите текущий пароль';

  @override
  String get enterNewPassword => 'Введите новый пароль';

  @override
  String get confirmYourPassword => 'Подтвердите новый пароль';

  @override
  String get passwordChanged => 'Пароль успешно изменён';

  @override
  String get incorrectCurrentPassword => 'Неверный текущий пароль';

  @override
  String failedToUpdatePassword(String error) {
    return 'Не удалось изменить пароль: $error';
  }

  @override
  String get newPasswordSameAsOld =>
      'Новый пароль не может совпадать со старым';

  @override
  String get passwordChangeSuccess => 'Пароль успешно изменён';

  @override
  String get backToSignIn => 'Вернуться ко входу';

  @override
  String get checkYourEmail => 'Проверьте вашу почту';

  @override
  String get sendResetLink => 'Отправить ссылку сброса';

  @override
  String get resetPasswordInstructions =>
      'Введите ваш login, и мы отправим ссылку для сброса пароля.';

  @override
  String get resetPassword => 'Сброс пароля';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get passwordResetError => 'Ошибка при сбросе пароля';

  @override
  String get passwordResetEmailSent =>
      'Ссылка для сброса пароля отправлена на вашу почту.';

  @override
  String get success => 'Успешно';

  @override
  String get updatePassword => 'Обновить пароль';

  @override
  String get createNewPasswordInstructions =>
      'Создайте новый пароль для вашего аккаунта.';

  @override
  String get createNewPassword => 'Создание нового пароля';

  @override
  String get passwordHasBeenReset => 'Ваш пароль был успешно сброшен.';

  @override
  String get passwordResetSuccess => 'Сброс пароля выполнен успешно';

  @override
  String get sessionExpired => 'Сессия истекла';

  @override
  String get sessionExpiredMessage =>
      'Ваша сессия истекла. Пожалуйста, войдите снова.';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get assignParticipant => 'Назначить участника';

  @override
  String get invalidCharactersError => 'Значение содержит недопустимые символы';

  @override
  String get missingRecoveryParamsTitle => 'Отсутствуют параметры';

  @override
  String get missingRecoveryParamsMessage =>
      'Токен восстановления или email отсутствует. Пожалуйста, используйте ссылку из письма для сброса пароля.';

  @override
  String get resetLimitExceeded => 'Превышен лимит запросов';

  @override
  String get resetLimitExceededMessage =>
      'Вы превысили лимит запросов на восстановление пароля (5 запросов в час).';

  @override
  String waitBeforeNextAttempt(String time) {
    return 'Пожалуйста, подождите $time перед следующей попыткой.';
  }

  @override
  String remainingAttempts(int attempts) {
    return 'Осталось попыток: $attempts из 5';
  }

  @override
  String nextAttemptAvailable(String time) {
    return 'Следующая попытка будет доступна через: $time';
  }

  @override
  String get resetEmailLimitNotice =>
      'Обратите внимание: вы можете запросить не более 5 писем для сброса пароля в течение часа.';

  @override
  String get notAssigned => 'Не назначено';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get tapToViewProfile => 'Просмотр профиля';

  @override
  String get accept => 'Принять';

  @override
  String get reject => 'Отклонить';

  @override
  String get cancelRequest => 'Отменить заявку';

  @override
  String get processing => 'Обработка';

  @override
  String get minutes1 => 'минут';

  @override
  String get minutes => 'минуты';

  @override
  String get minute => 'минута';

  @override
  String get neconds1 => 'секунд';

  @override
  String get seconds => 'секунды';

  @override
  String get second => 'секунда';
}
