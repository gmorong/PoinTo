// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get general => 'GENERAL';

  @override
  String get language => 'Language';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'PROFILE';

  @override
  String get exit => 'Exit';

  @override
  String get dark_mode => 'Dark Mode';

  @override
  String get about_developer => 'About Developer';

  @override
  String get change_order => 'Change Order';

  @override
  String get add_task => 'Add Task';

  @override
  String get task_options => 'Task Options';

  @override
  String get edit_task => 'Edit Task';

  @override
  String get delete_task => 'Delete Task';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get edit_name => 'Edit name';

  @override
  String get add_member => 'Add member';

  @override
  String get sort_items => 'Sort items';

  @override
  String get task_members => 'Task members';

  @override
  String get close => 'Close';

  @override
  String get admin => 'Admin';

  @override
  String get editor => 'Editor';

  @override
  String get user => 'User';

  @override
  String get select_user => 'Select user';

  @override
  String get select_role => 'Select role';

  @override
  String get about_role => 'About role';

  @override
  String get add => 'Add';

  @override
  String get okay => 'Okay';

  @override
  String get name => 'Name';

  @override
  String get edit_profile => 'Edit profile';

  @override
  String get friends => 'Friends';

  @override
  String get surname => 'Surname';

  @override
  String get select_avatar => 'Select avatar';

  @override
  String get incoming_requests => 'Incoming requests';

  @override
  String get outgoing_requests => 'Outgoing requests';

  @override
  String get friends_email => 'Friend\'s email';

  @override
  String get task_name => 'Task Name';

  @override
  String authorLabel(Object name) {
    return 'Author: $name';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get createdByMe => 'Created by me';

  @override
  String get yourTasksWillAppearHere => 'Your tasks will appear here';

  @override
  String get exitFromTask => 'Exit from Task';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDeleteTask => 'Are you sure you want to delete this task?';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get taskNameCannotBeEmpty => 'Task name cannot be empty';

  @override
  String get newTaskName => 'New Task Name';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get lastNameNotSpecified => 'Last name not specified';

  @override
  String get firstNameNotSpecified => 'First name not specified';

  @override
  String errorSendingFriendRequest(String error) {
    return 'Error sending friend request: $error';
  }

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get friendRequestSent => 'Friend request sent';

  @override
  String get friendRequestAlreadySentOrFriend =>
      'Friend request already sent or user is already your friend';

  @override
  String get userNotFound => 'User not found';

  @override
  String get needToLogin => 'You need to log in';

  @override
  String get emailCannotBeEmpty => 'Email cannot be empty';

  @override
  String get send => 'Send';

  @override
  String get enterEmailHint => 'Enter your email';

  @override
  String get addFriendTitle => 'Add Friend';

  @override
  String errorWhileExiting(String error) {
    return 'Error while exiting: $error';
  }

  @override
  String errorUpdatingProfile(Object error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get profileUpdateSuccess => 'Profile updated successfully';

  @override
  String avatarUploadError(String error) {
    return 'Error uploading avatar: $error';
  }

  @override
  String get enterTextHint => 'Enter text...';

  @override
  String get noTaskItems => 'There are no items in the task';

  @override
  String get tapToAddFirstItem => 'Tap \'+\' to add the first item';

  @override
  String get noPermissionToAddItems =>
      'You don\'t have permission to add items';

  @override
  String saveError(String error) {
    return 'Error saving content: $error';
  }

  @override
  String roleChanged(Object role) {
    return 'Your role has been changed to: $role';
  }

  @override
  String get removedFromTask => 'You have been removed from this task';

  @override
  String get emptyNoteDeleted => 'Empty note deleted';

  @override
  String errorSavingContent(String error) {
    return 'Error saving content: $error';
  }

  @override
  String genericError(String error) {
    return 'Error: $error';
  }

  @override
  String get itemOptionsTitle => 'Item Options';

  @override
  String get itemTypeLabel => 'Item Type:';

  @override
  String get deadlineLabel => 'Deadline:';

  @override
  String get notSet => 'Not set';

  @override
  String get clearDeadline => 'Clear deadline';

  @override
  String get confirmation => 'Confirmation';

  @override
  String get deleteItemConfirmation =>
      'Are you sure you want to delete this item?';

  @override
  String deleteError(String error) {
    return 'Deletion error: $error';
  }

  @override
  String get noDeadline => 'No deadline';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String overdueWithDate(String date) {
    return 'Overdue ($date)';
  }

  @override
  String get invalidDate => 'Invalid date';

  @override
  String get noAvailableItemTypes => 'No available item types';

  @override
  String get selectItemType => 'Select item type';

  @override
  String genericErrorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get addNoteTooltip => 'Add a note';

  @override
  String get sortItemsTitle => 'Sort items';

  @override
  String get membersTooltip => 'Members';

  @override
  String get taskDetailsTitle => 'Task Details';

  @override
  String taskLoadingError(String error) {
    return 'Failed to load task data: $error';
  }

  @override
  String updatePositionError(String itemId) {
    return 'Failed to update position for item $itemId';
  }

  @override
  String sortError(String error) {
    return 'Error while sorting: $error';
  }

  @override
  String get itemsSorted => 'Items sorted successfully';

  @override
  String get completedFirst => 'Completed first';

  @override
  String get incompleteFirst => 'Incomplete first';

  @override
  String get deadlineLateFirst => 'By deadline (latest first)';

  @override
  String get deadlineEarlyFirst => 'By deadline (earliest first)';

  @override
  String get userRoleUser => 'User';

  @override
  String get userRoleEditor => 'Editor';

  @override
  String get userRoleAdmin => 'Administrator';

  @override
  String get rolesInfoDescription =>
      'Administrator: full access\nEditor: can edit tasks\nUser: view only';

  @override
  String get selectNewMemberRole => 'Select a new member role';

  @override
  String failedToLoadMembers(String error) {
    return 'Failed to load members: $error';
  }

  @override
  String get you => 'You';

  @override
  String get roleUpdated => 'Role updated';

  @override
  String get creator => 'Creator';

  @override
  String get noMembers => 'No members';

  @override
  String get taskCreatorNotFound => 'Task creator not found';

  @override
  String get leftTask => 'You have left the task';

  @override
  String get leave => 'Leave';

  @override
  String get leaveTaskConfirmation =>
      'Are you sure you want to leave this task? You will lose access to it.';

  @override
  String get leaveTask => 'Leave Task';

  @override
  String get memberRemoved => 'Member removed';

  @override
  String get removeMemberTitle => 'Remove Member';

  @override
  String get removeMemberConfirmation =>
      'Are you sure you want to remove this member from the task?';

  @override
  String get emptyTaskNameError => 'Task name cannot be empty';

  @override
  String get editTaskTitle => 'Edit Task Title';

  @override
  String errorWhileAdding(String error) {
    return 'Error while adding: $error';
  }

  @override
  String get userAdded => 'User added';

  @override
  String get ok => 'Got it';

  @override
  String get userRoleUserDescription => 'Only view and mark items as completed';

  @override
  String get userRoleEditorDescription =>
      'Can add and edit items, but cannot manage members';

  @override
  String get userRoleAdminDescription =>
      'Full access to task, including member management and editing items';

  @override
  String get rolesInfoTitle => 'Role Information';

  @override
  String get rolesInfoButton => 'About roles';

  @override
  String get selectRole => 'Select role:';

  @override
  String get selectUser => 'Select user:';

  @override
  String get addParticipant => 'Add participant';

  @override
  String get noAvailableUsers => 'No available users to add.';

  @override
  String get darkMode => 'Dark theme';

  @override
  String get error => 'Error';

  @override
  String get login => 'Login';

  @override
  String get enterLogin => 'Enter login';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get signIn => 'Sign in';

  @override
  String get confirmEmailPrompt => 'Please confirm your email to log in.';

  @override
  String get loginError => 'Login error occurred';

  @override
  String get invalidCredentials => 'Invalid login or password';

  @override
  String get emailNotConfirmed =>
      'Email not confirmed. Please verify it first.';

  @override
  String get invalidPassword => 'Incorrect password';

  @override
  String errorWhileSigningIn(String error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get signInError => 'An error occurred during sign in';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get registration => 'Registration';

  @override
  String get errorTitle => 'Error';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get firstName => 'First name';

  @override
  String get enterFirstName => 'Enter your first name';

  @override
  String get lastName => 'Last name';

  @override
  String get enterLastName => 'Enter your last name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get repeatPassword => 'Repeat password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String pleaseEnterField(String field) {
    return 'Please enter $field';
  }

  @override
  String get loginAlreadyExists =>
      'Login is already taken. Please choose another.';

  @override
  String get emailAlreadyExists => 'Email is already in use.';

  @override
  String get registrationSuccessful => 'Registration successful!';

  @override
  String get pleaseConfirmEmail =>
      'Please confirm your email to complete registration.';

  @override
  String get registrationError => 'Registration error';

  @override
  String registrationErrorWithDetails(String error) {
    return 'Registration error: $error';
  }

  @override
  String get somethingWentWrong =>
      'Something went wrong. Please try again later.';

  @override
  String get emailAlreadyRegistered => 'This email is already registered.';

  @override
  String get invalidEmailFormat => 'Invalid email format.';

  @override
  String get weakPassword => 'Password is too weak.';

  @override
  String get signUp => 'Sign up';

  @override
  String get aboutMe => 'About me';

  @override
  String get organization => 'Organization';

  @override
  String get phone => 'Phone';

  @override
  String get social => 'Social';

  @override
  String get friends_login => 'Login';

  @override
  String get enterLoginHint => 'Enter friend\'s login here';

  @override
  String get errorSendingRequest => 'Error sending request';

  @override
  String get confirmAddFriendTitle => 'Add as friend?';

  @override
  String confirmAddFriendContent(String login) {
    return 'Add user @$login as friend?';
  }

  @override
  String get friendRequestCancelled => 'Request cancelled';

  @override
  String friendRequestCancelError(String error) {
    return 'Error cancelling: $error';
  }

  @override
  String get usersNotFound => 'Users not found';

  @override
  String friendRequestSendingError(String error) {
    return 'Error sending request: $error';
  }

  @override
  String get usersWasDelete => 'You\'r friend deleted';

  @override
  String get removeFriend => 'Remove friend';

  @override
  String get friendProfile => 'Frind\'s profile';

  @override
  String get userIdMissingError => 'Friend\'s ID is missed';

  @override
  String get noFriendsYet => 'You aren\'t have any friends yet';

  @override
  String get noIncomingRequests => 'No incoming requests';

  @override
  String get noOutgoingRequests => 'No outgoing requests';

  @override
  String get sharedTasksTitle => 'Shared tasks title';

  @override
  String get invalidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get invalidPhoneFormat => 'Invalid phone number format';

  @override
  String get usernameFormatRestriction =>
      'Only English letters,\nnumbers and the \"_\" symbol';

  @override
  String get usernameFormatHint =>
      'Username may only contain English letters, digits and the underscore character';

  @override
  String get invalidCharactersDetected =>
      'Invalid characters detected in the input';

  @override
  String get loginMinLength => 'Username must be at least 4 characters long';

  @override
  String get loginMaxLength => 'Username must not exceed 15 characters';

  @override
  String get optionalField => 'Optional field';

  @override
  String get onlyLetters => 'Only letters allowed';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileUpdated => 'Profile successfully updated';

  @override
  String profileUpdateError(String error) {
    return 'Profile update error: $error';
  }

  @override
  String get fieldCannotBeOnlySpaces => 'Field cannot contain only spaces';

  @override
  String fieldOnlyLetters(String fieldName) {
    return '$fieldName can contain only letters';
  }

  @override
  String fieldRequired(String fieldName) {
    return '$fieldName cannot be empty';
  }

  @override
  String get note => 'Note';

  @override
  String get header => 'Header';

  @override
  String get checklist => 'Check list';

  @override
  String get noPermission => 'Can\'t do this';

  @override
  String get fullName => 'Dmitry Kamkov';

  @override
  String get universityShort => 'UrTISI SibGUTI, PE-12b\nDepartment of IST';

  @override
  String get universityFull =>
      'Student of UrTISI SibGUTI\nSpecialty: Software for Autonomous and Computing Systems\nGroup: PE-12b\nDepartment of IST';

  @override
  String get hobbyTitle => 'Hobby';

  @override
  String get hobbyFigureSkating => 'Figure\nskating';

  @override
  String get hobbySnowboard => 'Snowboard';

  @override
  String get hobbyWakeboard => 'Wakeboard';

  @override
  String get hobbyFootball => 'Football';

  @override
  String get quoteTitle => 'Quote';

  @override
  String get quoteText => 'Where others see a limit — I seek a path beyond.';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get avatarRemoveSuccess => 'Avatar successfully removed';

  @override
  String avatarRemoveError(String error) {
    return 'Error removing avatar: $error';
  }

  @override
  String get removeAvatar => 'Remove avatar';

  @override
  String get confirmRemoveAvatar =>
      'Are you sure you want to remove your avatar?';

  @override
  String get removeAvatarConfirmation => 'Confirm Avatar Removal';

  @override
  String get remove => 'Remove';

  @override
  String get avatarRemoved => 'Avatar removed';

  @override
  String get exampleFormat => 'Example format';

  @override
  String get exampleNumber => 'Example number';

  @override
  String exampleFormatWithNumber(String number) {
    return 'Example format: $number';
  }

  @override
  String roleUpdateError(String error) {
    return 'Error updating role: $error';
  }

  @override
  String get cannotAddCreatorAsMember => 'Cannot add task creator as a member';

  @override
  String get roleChangedLimitedAccess =>
      'Your role has changed, some features are no longer available';

  @override
  String get updatingPositions => 'Updating positions';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get enterCurrentPassword => 'Please enter your current password';

  @override
  String get enterNewPassword => 'Please enter your new password';

  @override
  String get confirmYourPassword => 'Please confirm your new password';

  @override
  String get passwordChanged => 'Password successfully changed';

  @override
  String get incorrectCurrentPassword => 'Current password is incorrect';

  @override
  String failedToUpdatePassword(String error) {
    return 'Failed to update password: $error';
  }

  @override
  String get newPasswordSameAsOld =>
      'New password cannot be the same as the old one';

  @override
  String get passwordChangeSuccess => 'Password changed successfully';

  @override
  String get backToSignIn => 'Back to Sign In';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetPasswordInstructions =>
      'Enter your login and we\'ll send you a link to reset your password.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get passwordResetError =>
      'An error occurred while resetting your password';

  @override
  String get passwordResetEmailSent =>
      'A password reset link has been sent to your email.';

  @override
  String get success => 'Success';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get createNewPasswordInstructions =>
      'Create a new password for your account.';

  @override
  String get createNewPassword => 'Create New Password';

  @override
  String get passwordHasBeenReset => 'Your password has been reset.';

  @override
  String get passwordResetSuccess => 'Password reset successful';

  @override
  String get sessionExpired => 'Session Expired';

  @override
  String get sessionExpiredMessage =>
      'Your session has expired. Please sign in again.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get assignParticipant => 'Assign Participant';

  @override
  String get invalidCharactersError => 'The value contains invalid characters';

  @override
  String get missingRecoveryParamsTitle => 'Missing Parameters';

  @override
  String get missingRecoveryParamsMessage =>
      'Recovery token or email is missing. Please use the link from the reset password email.';

  @override
  String get resetLimitExceeded => 'Request Limit Exceeded';

  @override
  String get resetLimitExceededMessage =>
      'You have exceeded the password reset request limit (5 requests per hour).';

  @override
  String waitBeforeNextAttempt(String time) {
    return 'Please wait $time before trying again.';
  }

  @override
  String remainingAttempts(int attempts) {
    return 'Remaining attempts: $attempts out of 5';
  }

  @override
  String nextAttemptAvailable(String time) {
    return 'Next attempt available in: $time';
  }

  @override
  String get resetEmailLimitNotice =>
      'Note: You can request a password reset email no more than 5 times per hour.';

  @override
  String get notAssigned => 'Not assigned';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get showPassword => 'Show password';

  @override
  String get tapToViewProfile => 'Tap to view profile';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get processing => 'Processing';

  @override
  String get minutes1 => 'minutes';

  @override
  String get minutes => 'minutes';

  @override
  String get minute => 'minute';

  @override
  String get neconds1 => 'neconds';

  @override
  String get seconds => 'neconds';

  @override
  String get second => 'necond';
}
