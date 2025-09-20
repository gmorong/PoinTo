// ignore_for_file: unnecessary_cast, unused_field
import 'package:pointo/screens/main/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main/friends_screen.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';
import 'dart:async';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? profileData;
  
  // Добавляем переменную для хранения подписки
  StreamSubscription? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _setupProfileSubscription();
  }
  
  void _setupProfileSubscription() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    _profileSubscription = supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((snapshot) {
          if (snapshot.isNotEmpty && mounted) {
            setState(() {
              profileData = snapshot.first as Map<String, dynamic>;
            });
          }
        });
  }

  Future<void> _fetchProfileData() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
      return;
    }

    try {
      final response =
          await supabase.from('users').select().eq('id', user.id).maybeSingle();

      if (mounted) {
        setState(() {
          profileData = response as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profileData: profileData ?? {}),
      ),
    ).then((_) {
      // Обновляем данные при возврате с экрана редактирования
      if (mounted) {
        _fetchProfileData();
      }
    });
  }
  
  @override
  void dispose() {
    // Отменяем подписку при удалении виджета
    _profileSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (profileData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _navigateToEditProfile,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Аватар
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: profileData!['avatar_url'] != null
                    ? Image.network(
                        profileData!['avatar_url'],
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.error, size: 100),
                          );
                        },
                      )
                    : Container(
                        width: 200,
                        height: 200,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.person, size: 100),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Имя и фамилия
            Text(
              '${profileData!['first_name'] ?? ''} ${profileData!['last_name'] ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // SOCIAL SECTION
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.social,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(),

            _buildStaticInfo(AppLocalizations.of(context)!.login,
                profileData!['login'] ?? ''),
            _buildStaticInfo(AppLocalizations.of(context)!.email,
                profileData!['email'] ?? ''),
            _buildOptionalInfo(
                AppLocalizations.of(context)!.phone, profileData!['phone']),
            _buildOptionalInfo(AppLocalizations.of(context)!.organization,
                profileData!['organization']),

            const SizedBox(height: 24),

            // ABOUT ME SECTION
            if ((profileData!['about'] ?? '').isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.aboutMe,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(),
              _buildOptionalInfo(null, profileData!['about']),
            ],
          ],
        ),
      ),
    );
  }

// Статичные элементы
  Widget _buildStaticInfo(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

// Опциональные элементы (если value не пуст)
  Widget _buildOptionalInfo(String? title, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        title: title != null
            ? Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
              )
            : null,
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}