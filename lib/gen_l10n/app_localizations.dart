import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// Title for the general section
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get general;

  /// Label for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Title for settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Title for profile section
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profile;

  /// Exit button label
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Label for dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// Information about developer
  ///
  /// In en, this message translates to:
  /// **'About Developer'**
  String get about_developer;

  /// Button to change order of items
  ///
  /// In en, this message translates to:
  /// **'Change Order'**
  String get change_order;

  /// Button to add a new task
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get add_task;

  /// Options for a task
  ///
  /// In en, this message translates to:
  /// **'Task Options'**
  String get task_options;

  /// Edit an existing task
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get edit_task;

  /// Delete a task
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get delete_task;

  /// Cancel action button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save action button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Edit name field
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get edit_name;

  /// Add a member to task or group
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get add_member;

  /// Sort items button
  ///
  /// In en, this message translates to:
  /// **'Sort items'**
  String get sort_items;

  /// List of task members
  ///
  /// In en, this message translates to:
  /// **'Task members'**
  String get task_members;

  /// Close action
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Administrator role
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// Editor role
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// User role
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Select a user
  ///
  /// In en, this message translates to:
  /// **'Select user'**
  String get select_user;

  /// Select a role
  ///
  /// In en, this message translates to:
  /// **'Select role'**
  String get select_role;

  /// Information about roles
  ///
  /// In en, this message translates to:
  /// **'About role'**
  String get about_role;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Okay confirmation button
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// Name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Edit profile action
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get edit_profile;

  /// Friends list title
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// Surname field
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// Select avatar for profile
  ///
  /// In en, this message translates to:
  /// **'Select avatar'**
  String get select_avatar;

  /// List of incoming requests
  ///
  /// In en, this message translates to:
  /// **'Incoming requests'**
  String get incoming_requests;

  /// List of outgoing requests
  ///
  /// In en, this message translates to:
  /// **'Outgoing requests'**
  String get outgoing_requests;

  /// Email address of a friend
  ///
  /// In en, this message translates to:
  /// **'Friend\'s email'**
  String get friends_email;

  /// Task's name of project
  ///
  /// In en, this message translates to:
  /// **'Task Name'**
  String get task_name;

  /// Label with author's name
  ///
  /// In en, this message translates to:
  /// **'Author: {name}'**
  String authorLabel(Object name);

  /// Unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Text to indicate the item was created by the current user
  ///
  /// In en, this message translates to:
  /// **'Created by me'**
  String get createdByMe;

  /// Message shown when there are no tasks yet
  ///
  /// In en, this message translates to:
  /// **'Your tasks will appear here'**
  String get yourTasksWillAppearHere;

  /// Button or action for exiting from the task
  ///
  /// In en, this message translates to:
  /// **'Exit from Task'**
  String get exitFromTask;

  /// Button or action for deleting the task
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Confirmation prompt for deleting the task
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get confirmDeleteTask;

  /// Title of the deletion confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// Error message shown when the task name field is left empty
  ///
  /// In en, this message translates to:
  /// **'Task name cannot be empty'**
  String get taskNameCannotBeEmpty;

  /// Hint or title for entering a new task name
  ///
  /// In en, this message translates to:
  /// **'New Task Name'**
  String get newTaskName;

  /// Title or label for selecting a language
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Default text when user's last name is not provided
  ///
  /// In en, this message translates to:
  /// **'Last name not specified'**
  String get lastNameNotSpecified;

  /// Default text when user's first name is not provided
  ///
  /// In en, this message translates to:
  /// **'First name not specified'**
  String get firstNameNotSpecified;

  /// Error message when sending a friend request
  ///
  /// In en, this message translates to:
  /// **'Error sending friend request: {error}'**
  String errorSendingFriendRequest(String error);

  /// Error message with details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(String error);

  /// Message indicating that a friend request has been successfully sent
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get friendRequestSent;

  /// Message when the user has already sent a request or is already a friend
  ///
  /// In en, this message translates to:
  /// **'Friend request already sent or user is already your friend'**
  String get friendRequestAlreadySentOrFriend;

  /// Error message when the user with the specified email was not found
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// Message when user must log in before performing an action
  ///
  /// In en, this message translates to:
  /// **'You need to log in'**
  String get needToLogin;

  /// Error message when user did not enter email
  ///
  /// In en, this message translates to:
  /// **'Email cannot be empty'**
  String get emailCannotBeEmpty;

  /// Button to submit a form or request
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Hint text for email input field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmailHint;

  /// Title for add friend dialog
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriendTitle;

  /// Error message when the user tries to exit the task.
  ///
  /// In en, this message translates to:
  /// **'Error while exiting: {error}'**
  String errorWhileExiting(String error);

  /// Error message when updating a user profile fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String errorUpdatingProfile(Object error);

  /// Message shown when profile update is successful
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdateSuccess;

  /// Error occurred while uploading avatar
  ///
  /// In en, this message translates to:
  /// **'Error uploading avatar: {error}'**
  String avatarUploadError(String error);

  /// Hint text in a text field for entering text
  ///
  /// In en, this message translates to:
  /// **'Enter text...'**
  String get enterTextHint;

  /// Text displayed when there are no items in the task
  ///
  /// In en, this message translates to:
  /// **'There are no items in the task'**
  String get noTaskItems;

  /// Hint to the user to tap '+' to add the first item to the task
  ///
  /// In en, this message translates to:
  /// **'Tap \'+\' to add the first item'**
  String get tapToAddFirstItem;

  /// Message to the user indicating they don't have permission to add items
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to add items'**
  String get noPermissionToAddItems;

  /// Error message when saving content fails
  ///
  /// In en, this message translates to:
  /// **'Error saving content: {error}'**
  String saveError(String error);

  /// Message shown after the user's role is changed
  ///
  /// In en, this message translates to:
  /// **'Your role has been changed to: {role}'**
  String roleChanged(Object role);

  /// Message shown when the user is removed from the task
  ///
  /// In en, this message translates to:
  /// **'You have been removed from this task'**
  String get removedFromTask;

  /// Message shown when an empty note is deleted
  ///
  /// In en, this message translates to:
  /// **'Empty note deleted'**
  String get emptyNoteDeleted;

  /// Error message when saving content fails
  ///
  /// In en, this message translates to:
  /// **'Error saving content: {error}'**
  String errorSavingContent(String error);

  /// Generic error message with details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericError(String error);

  /// Title for the item options dialog
  ///
  /// In en, this message translates to:
  /// **'Item Options'**
  String get itemOptionsTitle;

  /// Label for selecting the item type in the item options dialog
  ///
  /// In en, this message translates to:
  /// **'Item Type:'**
  String get itemTypeLabel;

  /// Label for selecting the deadline of an item in the item options
  ///
  /// In en, this message translates to:
  /// **'Deadline:'**
  String get deadlineLabel;

  /// Text shown when deadline or another value is not set
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// Button to clear the set deadline from an item
  ///
  /// In en, this message translates to:
  /// **'Clear deadline'**
  String get clearDeadline;

  /// Title for a confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// Confirmation message for deleting an item
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get deleteItemConfirmation;

  /// Error that occurred during deletion with details
  ///
  /// In en, this message translates to:
  /// **'Deletion error: {error}'**
  String deleteError(String error);

  /// Displayed when a task item has no deadline assigned
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get noDeadline;

  /// Displayed when a task deadline is set for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Displayed when a task deadline is set for tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Displayed when a deadline has passed, showing the overdue date
  ///
  /// In en, this message translates to:
  /// **'Overdue ({date})'**
  String overdueWithDate(String date);

  /// Displayed when the date cannot be parsed or is incorrect
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get invalidDate;

  /// Displayed when there are no available item types to create in a task
  ///
  /// In en, this message translates to:
  /// **'No available item types'**
  String get noAvailableItemTypes;

  /// Title for dialog where user selects a type of task item to create
  ///
  /// In en, this message translates to:
  /// **'Select item type'**
  String get selectItemType;

  /// Generic error message with details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericErrorWithDetails(String error);

  /// Tooltip for the button to add a new note
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get addNoteTooltip;

  /// Title for the sort items dialog
  ///
  /// In en, this message translates to:
  /// **'Sort items'**
  String get sortItemsTitle;

  /// Tooltip for the members button
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTooltip;

  /// Fallback title when the task has no specific title
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetailsTitle;

  /// Error when failing to load task details
  ///
  /// In en, this message translates to:
  /// **'Failed to load task data: {error}'**
  String taskLoadingError(String error);

  /// Error message when updating the position of a task item fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update position for item {itemId}'**
  String updatePositionError(String itemId);

  /// Error message when an error occurs during item sorting
  ///
  /// In en, this message translates to:
  /// **'Error while sorting: {error}'**
  String sortError(String error);

  /// Message shown when items are successfully sorted
  ///
  /// In en, this message translates to:
  /// **'Items sorted successfully'**
  String get itemsSorted;

  /// Sorting option to display completed items first
  ///
  /// In en, this message translates to:
  /// **'Completed first'**
  String get completedFirst;

  /// Sorting option to display incomplete items first
  ///
  /// In en, this message translates to:
  /// **'Incomplete first'**
  String get incompleteFirst;

  /// Sorting option to display tasks by deadline with the latest ones first
  ///
  /// In en, this message translates to:
  /// **'By deadline (latest first)'**
  String get deadlineLateFirst;

  /// Sorting option to display tasks by deadline with the earliest ones first
  ///
  /// In en, this message translates to:
  /// **'By deadline (earliest first)'**
  String get deadlineEarlyFirst;

  /// Title for the user role 'User'
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userRoleUser;

  /// Title for the user role 'Editor'
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get userRoleEditor;

  /// Title for the user role 'Administrator'
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get userRoleAdmin;

  /// Description of the permissions for each user role
  ///
  /// In en, this message translates to:
  /// **'Administrator: full access\nEditor: can edit tasks\nUser: view only'**
  String get rolesInfoDescription;

  /// Title for dialog where user selects a new role for a task participant
  ///
  /// In en, this message translates to:
  /// **'Select a new member role'**
  String get selectNewMemberRole;

  /// Displayed when there is an error loading task members
  ///
  /// In en, this message translates to:
  /// **'Failed to load members: {error}'**
  String failedToLoadMembers(String error);

  /// Label for indicating the current user (e.g., in participants list)
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Message shown when a user's role has been successfully updated
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get roleUpdated;

  /// Label for the creator of a task or project
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// Message shown when there are no members in the task or project
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get noMembers;

  /// Error message when the task creator is not found
  ///
  /// In en, this message translates to:
  /// **'Task creator not found'**
  String get taskCreatorNotFound;

  /// Message shown when the user successfully leaves a task
  ///
  /// In en, this message translates to:
  /// **'You have left the task'**
  String get leftTask;

  /// Button text for leaving a task or group
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// Confirmation message shown when user tries to leave the task
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this task? You will lose access to it.'**
  String get leaveTaskConfirmation;

  /// Button text to confirm leaving the task
  ///
  /// In en, this message translates to:
  /// **'Leave Task'**
  String get leaveTask;

  /// Notification when a member is successfully removed from a task
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemoved;

  /// Title for the dialog to remove a task member
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMemberTitle;

  /// Confirmation text for removing a task member
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this member from the task?'**
  String get removeMemberConfirmation;

  /// Error message shown when trying to save an empty task name
  ///
  /// In en, this message translates to:
  /// **'Task name cannot be empty'**
  String get emptyTaskNameError;

  /// Title for the dialog to edit the task name
  ///
  /// In en, this message translates to:
  /// **'Edit Task Title'**
  String get editTaskTitle;

  /// Displayed when there is an error while adding a user or an item
  ///
  /// In en, this message translates to:
  /// **'Error while adding: {error}'**
  String errorWhileAdding(String error);

  /// Message when a user has been successfully added
  ///
  /// In en, this message translates to:
  /// **'User added'**
  String get userAdded;

  /// Button text to confirm understanding in dialogs
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get ok;

  /// Description of the 'User' role
  ///
  /// In en, this message translates to:
  /// **'Only view and mark items as completed'**
  String get userRoleUserDescription;

  /// Description of the 'Editor' role
  ///
  /// In en, this message translates to:
  /// **'Can add and edit items, but cannot manage members'**
  String get userRoleEditorDescription;

  /// Description of the 'Admin' role
  ///
  /// In en, this message translates to:
  /// **'Full access to task, including member management and editing items'**
  String get userRoleAdminDescription;

  /// Title for the dialog showing role information
  ///
  /// In en, this message translates to:
  /// **'Role Information'**
  String get rolesInfoTitle;

  /// Button text to open the roles information dialog
  ///
  /// In en, this message translates to:
  /// **'About roles'**
  String get rolesInfoButton;

  /// Prompt to select a user role in the app
  ///
  /// In en, this message translates to:
  /// **'Select role:'**
  String get selectRole;

  /// Prompt to select a user from the list
  ///
  /// In en, this message translates to:
  /// **'Select user:'**
  String get selectUser;

  /// Button text for adding a participant to a task
  ///
  /// In en, this message translates to:
  /// **'Add participant'**
  String get addParticipant;

  /// Message shown when there are no users available to add to the task
  ///
  /// In en, this message translates to:
  /// **'No available users to add.'**
  String get noAvailableUsers;

  /// Switch label for dark theme toggle
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkMode;

  /// Generic error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Label for login input field
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Hint for login input
  ///
  /// In en, this message translates to:
  /// **'Enter login'**
  String get enterLogin;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Hint for password input
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Checkbox label for keeping user signed in
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// Text for sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Shown when login attempted with unconfirmed email
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email to log in.'**
  String get confirmEmailPrompt;

  /// Generic login error message
  ///
  /// In en, this message translates to:
  /// **'Login error occurred'**
  String get loginError;

  /// Error shown when login credentials are wrong
  ///
  /// In en, this message translates to:
  /// **'Invalid login or password'**
  String get invalidCredentials;

  /// Error shown if email hasn't been verified
  ///
  /// In en, this message translates to:
  /// **'Email not confirmed. Please verify it first.'**
  String get emailNotConfirmed;

  /// Error shown when password is incorrect
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get invalidPassword;

  /// Shown when sign-in throws an exception
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {error}'**
  String errorWhileSigningIn(String error);

  /// An error occurred during sign in
  ///
  /// In en, this message translates to:
  /// **'An error occurred during sign in'**
  String get signInError;

  /// Password must be at least 6 characters
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Title for the registration page
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// Generic title for error dialogs
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// Label for email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Hint text for email input field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Label for first name input field
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// Hint text for first name input field
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get enterFirstName;

  /// Label for last name input field
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// Hint text for last name input field
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get enterLastName;

  /// Label for confirm password input field
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// Hint text for confirm password input field
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get repeatPassword;

  /// Displayed when the passwords entered do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Displayed when a required field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter {field}'**
  String pleaseEnterField(String field);

  /// Displayed when the login already exists
  ///
  /// In en, this message translates to:
  /// **'Login is already taken. Please choose another.'**
  String get loginAlreadyExists;

  /// Displayed when the email is already registered
  ///
  /// In en, this message translates to:
  /// **'Email is already in use.'**
  String get emailAlreadyExists;

  /// Displayed when registration completes successfully
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registrationSuccessful;

  /// Displayed after successful registration requiring email confirmation
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email to complete registration.'**
  String get pleaseConfirmEmail;

  /// Displayed in case of any error during registration
  ///
  /// In en, this message translates to:
  /// **'Registration error'**
  String get registrationError;

  /// Displayed when a registration error occurs with details
  ///
  /// In en, this message translates to:
  /// **'Registration error: {error}'**
  String registrationErrorWithDetails(String error);

  /// Displayed for unexpected errors
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again later.'**
  String get somethingWentWrong;

  /// Displayed when trying to register an already registered email
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailAlreadyRegistered;

  /// Displayed when an invalid email is entered
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get invalidEmailFormat;

  /// Displayed when the password does not meet security requirements
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get weakPassword;

  /// Button text for registration
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// aboutme
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMe;

  /// Organization
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// Phone number
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Social
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// Login
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get friends_login;

  /// Enter friend's login here
  ///
  /// In en, this message translates to:
  /// **'Enter friend\'s login here'**
  String get enterLoginHint;

  /// Generic message when adding fails
  ///
  /// In en, this message translates to:
  /// **'Error sending request'**
  String get errorSendingRequest;

  /// Dialog title for confirming addition
  ///
  /// In en, this message translates to:
  /// **'Add as friend?'**
  String get confirmAddFriendTitle;

  /// Dialog content with username
  ///
  /// In en, this message translates to:
  /// **'Add user @{login} as friend?'**
  String confirmAddFriendContent(String login);

  /// Notification after cancelling request
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get friendRequestCancelled;

  /// Error message with error detail
  ///
  /// In en, this message translates to:
  /// **'Error cancelling: {error}'**
  String friendRequestCancelError(String error);

  /// Message displayed when no users are found in search results
  ///
  /// In en, this message translates to:
  /// **'Users not found'**
  String get usersNotFound;

  /// Displayed when sending a friend request fails
  ///
  /// In en, this message translates to:
  /// **'Error sending request: {error}'**
  String friendRequestSendingError(String error);

  /// Сообщение, отображаемое при удалении друга
  ///
  /// In en, this message translates to:
  /// **'You\'r friend deleted'**
  String get usersWasDelete;

  /// Кнопка, отображаемое при удалении друга
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get removeFriend;

  /// Frind's profile
  ///
  /// In en, this message translates to:
  /// **'Frind\'s profile'**
  String get friendProfile;

  /// Friend's ID is missed
  ///
  /// In en, this message translates to:
  /// **'Friend\'s ID is missed'**
  String get userIdMissingError;

  /// You aren't have any friends yet
  ///
  /// In en, this message translates to:
  /// **'You aren\'t have any friends yet'**
  String get noFriendsYet;

  /// No incoming requests
  ///
  /// In en, this message translates to:
  /// **'No incoming requests'**
  String get noIncomingRequests;

  /// No outgoing requests
  ///
  /// In en, this message translates to:
  /// **'No outgoing requests'**
  String get noOutgoingRequests;

  /// sharedTasksTitle
  ///
  /// In en, this message translates to:
  /// **'Shared tasks title'**
  String get sharedTasksTitle;

  /// Error message shown when phone number is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhoneNumber;

  /// Error message shown when phone number format is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format'**
  String get invalidPhoneFormat;

  /// Username format restriction
  ///
  /// In en, this message translates to:
  /// **'Only English letters,\nnumbers and the \"_\" symbol'**
  String get usernameFormatRestriction;

  /// Hint for allowed username format
  ///
  /// In en, this message translates to:
  /// **'Username may only contain English letters, digits and the underscore character'**
  String get usernameFormatHint;

  /// Error message shown when user enters forbidden characters
  ///
  /// In en, this message translates to:
  /// **'Invalid characters detected in the input'**
  String get invalidCharactersDetected;

  /// Validation error — username is too short
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 4 characters long'**
  String get loginMinLength;

  /// Validation error — username is too long
  ///
  /// In en, this message translates to:
  /// **'Username must not exceed 15 characters'**
  String get loginMaxLength;

  /// Label for optional form field
  ///
  /// In en, this message translates to:
  /// **'Optional field'**
  String get optionalField;

  /// Error: field must contain only letters
  ///
  /// In en, this message translates to:
  /// **'Only letters allowed'**
  String get onlyLetters;

  /// Title of the profile editing screen
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// Notification that profile was updated successfully
  ///
  /// In en, this message translates to:
  /// **'Profile successfully updated'**
  String get profileUpdated;

  /// Error when updating profile
  ///
  /// In en, this message translates to:
  /// **'Profile update error: {error}'**
  String profileUpdateError(String error);

  /// Error when field contains only whitespace
  ///
  /// In en, this message translates to:
  /// **'Field cannot contain only spaces'**
  String get fieldCannotBeOnlySpaces;

  /// Field letter-only validation error
  ///
  /// In en, this message translates to:
  /// **'{fieldName} can contain only letters'**
  String fieldOnlyLetters(String fieldName);

  /// Field is required
  ///
  /// In en, this message translates to:
  /// **'{fieldName} cannot be empty'**
  String fieldRequired(String fieldName);

  /// Element type — note
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// Element type — header
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get header;

  /// Element type — checklist
  ///
  /// In en, this message translates to:
  /// **'Check list'**
  String get checklist;

  /// Сообщение пользователю, что у него нет прав добавлять элементы
  ///
  /// In en, this message translates to:
  /// **'Can\'t do this'**
  String get noPermission;

  /// Full name of the student
  ///
  /// In en, this message translates to:
  /// **'Dmitry Kamkov'**
  String get fullName;

  /// Short info about university and department
  ///
  /// In en, this message translates to:
  /// **'UrTISI SibGUTI, PE-12b\nDepartment of IST'**
  String get universityShort;

  /// Full academic background description
  ///
  /// In en, this message translates to:
  /// **'Student of UrTISI SibGUTI\nSpecialty: Software for Autonomous and Computing Systems\nGroup: PE-12b\nDepartment of IST'**
  String get universityFull;

  /// Title for the hobbies section
  ///
  /// In en, this message translates to:
  /// **'Hobby'**
  String get hobbyTitle;

  /// No description provided for @hobbyFigureSkating.
  ///
  /// In en, this message translates to:
  /// **'Figure\nskating'**
  String get hobbyFigureSkating;

  /// No description provided for @hobbySnowboard.
  ///
  /// In en, this message translates to:
  /// **'Snowboard'**
  String get hobbySnowboard;

  /// No description provided for @hobbyWakeboard.
  ///
  /// In en, this message translates to:
  /// **'Wakeboard'**
  String get hobbyWakeboard;

  /// No description provided for @hobbyFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get hobbyFootball;

  /// Title for the motivational quote section
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quoteTitle;

  /// Personal quote
  ///
  /// In en, this message translates to:
  /// **'Where others see a limit — I seek a path beyond.'**
  String get quoteText;

  /// Title for contacts section
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// Displayed when avatar is removed successfully
  ///
  /// In en, this message translates to:
  /// **'Avatar successfully removed'**
  String get avatarRemoveSuccess;

  /// Error message when avatar removal fails
  ///
  /// In en, this message translates to:
  /// **'Error removing avatar: {error}'**
  String avatarRemoveError(String error);

  /// Button or action label for removing avatar
  ///
  /// In en, this message translates to:
  /// **'Remove avatar'**
  String get removeAvatar;

  /// Confirmation message shown before avatar removal
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove your avatar?'**
  String get confirmRemoveAvatar;

  /// Title of dialog confirming avatar removal
  ///
  /// In en, this message translates to:
  /// **'Confirm Avatar Removal'**
  String get removeAvatarConfirmation;

  /// General remove button label
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Short message shown when the avatar has been removed
  ///
  /// In en, this message translates to:
  /// **'Avatar removed'**
  String get avatarRemoved;

  /// Label used to indicate an example input format, e.g. for phone or date
  ///
  /// In en, this message translates to:
  /// **'Example format'**
  String get exampleFormat;

  /// Placeholder or label showing a sample number format
  ///
  /// In en, this message translates to:
  /// **'Example number'**
  String get exampleNumber;

  /// Label used to show an example format with a dynamic phone or data number
  ///
  /// In en, this message translates to:
  /// **'Example format: {number}'**
  String exampleFormatWithNumber(String number);

  /// Error shown when a user role update fails
  ///
  /// In en, this message translates to:
  /// **'Error updating role: {error}'**
  String roleUpdateError(String error);

  /// Error message when trying to add task creator as member
  ///
  /// In en, this message translates to:
  /// **'Cannot add task creator as a member'**
  String get cannotAddCreatorAsMember;

  /// Info message after user role is downgraded
  ///
  /// In en, this message translates to:
  /// **'Your role has changed, some features are no longer available'**
  String get roleChangedLimitedAccess;

  /// Info message
  ///
  /// In en, this message translates to:
  /// **'Updating positions'**
  String get updatingPositions;

  /// Title or button text for changing the user's password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Label for current password input field
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// Label for new password input field
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Label for confirming the new password
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// Validation error when current password is missing
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get enterCurrentPassword;

  /// Validation error when new password is missing
  ///
  /// In en, this message translates to:
  /// **'Please enter your new password'**
  String get enterNewPassword;

  /// Validation error when confirm password is missing
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get confirmYourPassword;

  /// Success message when password is updated
  ///
  /// In en, this message translates to:
  /// **'Password successfully changed'**
  String get passwordChanged;

  /// Error message when the entered current password is wrong
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get incorrectCurrentPassword;

  /// Shown when there is an error while changing the password
  ///
  /// In en, this message translates to:
  /// **'Failed to update password: {error}'**
  String failedToUpdatePassword(String error);

  /// Shown when the user enters a new password identical to the current one
  ///
  /// In en, this message translates to:
  /// **'New password cannot be the same as the old one'**
  String get newPasswordSameAsOld;

  /// Shown when the password was changed successfully
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangeSuccess;

  /// Button to return to the sign-in screen
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// Title shown after sending a reset link
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// Button text to send a password reset email
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Instructional text for password reset
  ///
  /// In en, this message translates to:
  /// **'Enter your login and we\'ll send you a link to reset your password.'**
  String get resetPasswordInstructions;

  /// Title for the reset password screen
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Link to start the password reset process
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Error shown if password reset fails
  ///
  /// In en, this message translates to:
  /// **'An error occurred while resetting your password'**
  String get passwordResetError;

  /// Message shown after successful sending of reset link
  ///
  /// In en, this message translates to:
  /// **'A password reset link has been sent to your email.'**
  String get passwordResetEmailSent;

  /// Generic success message
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Button or title for updating the password
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// Instructional text when resetting password after email verification
  ///
  /// In en, this message translates to:
  /// **'Create a new password for your account.'**
  String get createNewPasswordInstructions;

  /// Title for creating a new password
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPassword;

  /// Message shown after successful password reset
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset.'**
  String get passwordHasBeenReset;

  /// Generic success message for password reset completion
  ///
  /// In en, this message translates to:
  /// **'Password reset successful'**
  String get passwordResetSuccess;

  /// Title shown when user session has expired
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionExpired;

  /// Message shown when the user's session has expired
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get sessionExpiredMessage;

  /// Button text prompting the user to retry an action
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Button or title for assigning a participant to a task
  ///
  /// In en, this message translates to:
  /// **'Assign Participant'**
  String get assignParticipant;

  /// Error message shown when the input value contains disallowed characters
  ///
  /// In en, this message translates to:
  /// **'The value contains invalid characters'**
  String get invalidCharactersError;

  /// Title for the error dialog when recovery token/email is missing
  ///
  /// In en, this message translates to:
  /// **'Missing Parameters'**
  String get missingRecoveryParamsTitle;

  /// Message explaining that the recovery parameters are missing and should be accessed via the reset email
  ///
  /// In en, this message translates to:
  /// **'Recovery token or email is missing. Please use the link from the reset password email.'**
  String get missingRecoveryParamsMessage;

  /// No description provided for @resetLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Request Limit Exceeded'**
  String get resetLimitExceeded;

  /// No description provided for @resetLimitExceededMessage.
  ///
  /// In en, this message translates to:
  /// **'You have exceeded the password reset request limit (5 requests per hour).'**
  String get resetLimitExceededMessage;

  /// Message informing the user to wait before retrying
  ///
  /// In en, this message translates to:
  /// **'Please wait {time} before trying again.'**
  String waitBeforeNextAttempt(String time);

  /// Message indicating the number of remaining attempts
  ///
  /// In en, this message translates to:
  /// **'Remaining attempts: {attempts} out of 5'**
  String remainingAttempts(int attempts);

  /// Message indicating when the next attempt is available
  ///
  /// In en, this message translates to:
  /// **'Next attempt available in: {time}'**
  String nextAttemptAvailable(String time);

  /// No description provided for @resetEmailLimitNotice.
  ///
  /// In en, this message translates to:
  /// **'Note: You can request a password reset email no more than 5 times per hour.'**
  String get resetEmailLimitNotice;

  /// Status of an item that has not yet been assigned
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssigned;

  /// Tooltip or button for hiding the password
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Tooltip or button for showing the password
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Tap to view profile'**
  String get tapToViewProfile;

  /// Button to accept a request or action
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Button to reject a request or action
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// Button to cancel a sent request
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// Status or message indicating an action is in progress
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// Статус или сообщение, обозначающее, что действие в процессе
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes1;

  /// Статус или сообщение, обозначающее, что действие в процессе
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Статус или сообщение, обозначающее, что действие в процессе
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minute;

  /// Статус или сообщение, обозначающее, что действие в процессе
  ///
  /// In en, this message translates to:
  /// **'neconds'**
  String get neconds1;

  /// Статус или сообщение, обозначающее, что действие в процессе
  ///
  /// In en, this message translates to:
  /// **'neconds'**
  String get seconds;

  /// Статус или сообщение, обозначающее, что действие в процессе
  ///
  /// In en, this message translates to:
  /// **'necond'**
  String get second;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
