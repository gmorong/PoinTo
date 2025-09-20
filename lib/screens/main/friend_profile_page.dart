import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  List<Map<String, dynamic>> sharedTasks = [];

  // Состояния дружбы
  Map<String, dynamic>? friendRequest;
  FriendshipStatus friendshipStatus = FriendshipStatus.none;
  bool isProcessingFriendship = false;

  RealtimeChannel? _profileSubscription;
  RealtimeChannel? _tasksSubscription;
  RealtimeChannel? _taskMembersSubscription;
  RealtimeChannel? _friendRequestsSubscription;

  bool _profileUpdated = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchSharedTasks();
    _fetchFriendshipStatus();

    _setupProfileSubscription();
    _setupTasksSubscriptions();
    _setupFriendRequestsSubscription();
  }

  @override
  void dispose() {
    // Отписываемся от каналов
    _profileSubscription?.unsubscribe();
    _tasksSubscription?.unsubscribe();
    _taskMembersSubscription?.unsubscribe();
    _friendRequestsSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupProfileSubscription() {
    print('Настраиваем подписку на изменения профиля пользователя...');

    _profileSubscription = supabase
        .channel('user_profile_changes_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.userId,
          ),
          callback: (payload) {
            print('Получено событие обновления профиля пользователя!');

            if (mounted) {
              setState(() {
                profileData = Map<String, dynamic>.from(payload.newRecord);
                _profileUpdated = true;

                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _profileUpdated = false;
                    });
                  }
                });
              });
            }
          },
        )
        .subscribe();
  }

  void _setupTasksSubscriptions() {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    print('Настраиваем подписки на изменения в задачах...');

    _tasksSubscription = supabase
        .channel('tasks_changes_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          callback: (payload) {
            print('Получено событие изменения задачи!');
            _fetchSharedTasks();
          },
        )
        .subscribe();

    _taskMembersSubscription = supabase
        .channel('task_members_changes_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'task_members',
          callback: (payload) {
            print('Получено событие изменения участников задачи!');

            final record = payload.newRecord;
            if (record != null) {
              final userId = record['user_id'];
              if (userId == currentUserId || userId == widget.userId) {
                _fetchSharedTasks();
              }
            } else {
              _fetchSharedTasks();
            }
          },
        )
        .subscribe();
  }

  void _setupFriendRequestsSubscription() {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    print('Настраиваем подписку на изменения заявок в друзья...');

    _friendRequestsSubscription = supabase
        .channel('friend_requests_changes_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friend_requests',
          callback: (payload) {
            print('Получено событие изменения заявки в друзья!');

            final record = payload.newRecord;
            if (record != null) {
              final senderId = record['sender_id'];
              final receiverId = record['receiver_id'];

              // Проверяем, касается ли это нас
              if ((senderId == currentUserId && receiverId == widget.userId) ||
                  (senderId == widget.userId && receiverId == currentUserId)) {
                _fetchFriendshipStatus();
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          // ignore: unnecessary_cast
          profileData = response as Map<String, dynamic>?;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки профиля пользователя: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSharedTasks() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // Получаем все task_id, где участвует текущий пользователь или просматриваемый пользователь
      final memberTasksResponse = await supabase
          .from('task_members')
          .select('task_id, user_id')
          .filter('user_id', 'in', [currentUserId, widget.userId]);

      final grouped = <String, Set<String>>{};
      for (final row in memberTasksResponse) {
        final taskId = row['task_id'];
        final userId = row['user_id'];
        grouped.putIfAbsent(taskId, () => {}).add(userId);
      }

      // Добавляем задачи, где один из них является создателем
      final creatorTasksResponse = await supabase
          .from('tasks')
          .select('id, created_by')
          .or('created_by.eq.$currentUserId,created_by.eq.${widget.userId}');

      for (final row in creatorTasksResponse) {
        final taskId = row['id'];
        final userId = row['created_by'];
        grouped.putIfAbsent(taskId, () => {}).add(userId);
      }

      // Оставляем только задачи, где участвуют оба
      final commonTaskIds = grouped.entries
          .where((e) =>
              e.value.contains(currentUserId) &&
              e.value.contains(widget.userId))
          .map((e) => e.key)
          .toList();

      if (commonTaskIds.isEmpty) {
        setState(() {
          sharedTasks = [];
        });
        return;
      }

      // Загружаем сами задачи + информацию о создателе
      final tasks = await supabase
          .from('tasks')
          .select('id, title, users:created_by(id, login, avatar_url)')
          .filter('id', 'in', commonTaskIds);

      setState(() {
        sharedTasks = List<Map<String, dynamic>>.from(tasks);
      });
    } catch (e) {
      print('Ошибка при загрузке совместных задач: $e');
    }
  }

  Future<void> _fetchFriendshipStatus() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // Ищем заявку в друзья между текущим пользователем и просматриваемым
      final response = await supabase
          .from('friend_requests')
          .select('*')
          .or(
            'and(sender_id.eq.$currentUserId,receiver_id.eq.${widget.userId}),and(sender_id.eq.${widget.userId},receiver_id.eq.$currentUserId)',
          )
          .maybeSingle();

      if (mounted) {
        setState(() {
          friendRequest = response;
          friendshipStatus =
              _determineFriendshipStatus(response, currentUserId);
        });
      }
    } catch (e) {
      print('Ошибка при получении статуса дружбы: $e');
    }
  }

  FriendshipStatus _determineFriendshipStatus(
      Map<String, dynamic>? request, String currentUserId) {
    if (request == null) {
      return FriendshipStatus.none;
    }

    final status = request['status'];
    final senderId = request['sender_id'];
    final receiverId = request['receiver_id'];

    switch (status) {
      case 'accepted':
        return FriendshipStatus.friends;
      case 'pending':
        if (senderId == currentUserId) {
          // Текущий пользователь отправил заявку
          return FriendshipStatus.requestSent;
        } else if (receiverId == currentUserId) {
          // Текущий пользователь получил заявку
          return FriendshipStatus.requestReceived;
        } else {
          // Не должно происходить, но на всякий случай
          return FriendshipStatus.none;
        }
      case 'deleted':
      default:
        return FriendshipStatus.none;
    }
  }

  Widget _buildFriendshipButton() {
    if (isProcessingFriendship) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text(AppLocalizations.of(context)!.processing), // Изменил текст
      );
    }

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return SizedBox.shrink();
    }

    switch (friendshipStatus) {
      case FriendshipStatus.none:
        // Нет заявки - можно отправить
        return ElevatedButton.icon(
          onPressed: _sendFriendRequest,
          icon: Icon(Icons.person_add),
          label: Text(AppLocalizations.of(context)!.addFriendTitle),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        );

      case FriendshipStatus.requestSent:
        // Мы отправили заявку - можем отменить
        return ElevatedButton.icon(
          onPressed: _cancelFriendRequest,
          icon: Icon(Icons.cancel),
          label: Text(AppLocalizations.of(context)!
              .cancelRequest), // Более точный текст
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.white,
          ),
        );

      case FriendshipStatus.requestReceived:
        // Нам прислали заявку - можем принять или отклонить
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _acceptFriendRequest,
                icon: Icon(Icons.check),
                label: Text(AppLocalizations.of(context)!.accept),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _rejectFriendRequest, // Новый метод для отклонения
                icon: Icon(Icons.close),
                label: Text(AppLocalizations.of(context)!.reject),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case FriendshipStatus.friends:
        return ElevatedButton.icon(
          onPressed: _removeFriend,
          icon: Icon(Icons.person_remove),
          label: Text(AppLocalizations.of(context)!.removeFriend),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
        );
    }
  }

  Future<void> _rejectFriendRequest() async {
    if (friendRequest == null || isProcessingFriendship) return;

    setState(() {
      isProcessingFriendship = true;
    });

    try {
      await supabase.from('friend_requests').update({
        'status': 'deleted',
      }).eq('id', friendRequest!['id']);
    } catch (e) {
      print('Ошибка при отклонении заявки в друзья: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .friendRequestCancelError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isProcessingFriendship = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null || isProcessingFriendship) return;

    setState(() {
      isProcessingFriendship = true;
    });

    try {
      if (friendRequest != null) {
        // Обновляем существующую заявку
        await supabase.from('friend_requests').update({
          'status': 'pending',
          'sender_id': currentUserId,
          'receiver_id': widget.userId,
        }).eq('id', friendRequest!['id']);
      } else {
        // Создаем новую заявку
        await supabase.from('friend_requests').insert({
          'sender_id': currentUserId,
          'receiver_id': widget.userId,
          'status': 'pending',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.friendRequestSent),
          ),
        );
      }
    } catch (e) {
      print('Ошибка при отправке заявки в друзья: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .friendRequestCancelError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isProcessingFriendship = false;
      });
    }
  }

  Future<void> _cancelFriendRequest() async {
    if (friendRequest == null || isProcessingFriendship) return;

    setState(() {
      isProcessingFriendship = true;
    });

    try {
      await supabase.from('friend_requests').update({
        'status': 'deleted',
      }).eq('id', friendRequest!['id']);
    } catch (e) {
      print('Ошибка при отмене заявки в друзья: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .friendRequestCancelError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isProcessingFriendship = false;
      });
    }
  }

  Future<void> _acceptFriendRequest() async {
    if (friendRequest == null || isProcessingFriendship) return;

    setState(() {
      isProcessingFriendship = true;
    });

    try {
      await supabase.from('friend_requests').update({
        'status': 'accepted',
      }).eq('id', friendRequest!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.success),
          ),
        );
      }
    } catch (e) {
      print('Ошибка при принятии заявки в друзья: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .friendRequestCancelError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isProcessingFriendship = false;
      });
    }
  }

  Future<void> _removeFriend() async {
    if (friendRequest == null || isProcessingFriendship) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.removeFriend),
            content:
                Text(AppLocalizations.of(context)!.removeMemberConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.remove),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      isProcessingFriendship = true;
    });

    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final senderId = friendRequest!['sender_id'];
      final receiverId = friendRequest!['receiver_id'];

      // КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: Меняем роли так, чтобы удаливший стал receiver (для повторной заявки)
      // При этом статус меняется на 'pending', НЕ на 'deleted'
      final updatedSender = (senderId == currentUserId) ? receiverId : senderId;
      final updatedReceiver = currentUserId;

      await supabase.from('friend_requests').update({
        'status': 'pending', // ВАЖНО: ставим pending, а не deleted
        'sender_id': updatedSender,
        'receiver_id': updatedReceiver,
      }).eq('id', friendRequest!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.removeFriend),
          ),
        );
      }
    } catch (e) {
      print('Ошибка при удалении друга: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .friendRequestCancelError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isProcessingFriendship = false;
      });
    }
  }

  Color _getAvatarColor(String userId) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.pink,
    ];
    final int colorIndex = userId.hashCode % colors.length;
    return colors[colorIndex.abs()];
  }

  Widget _buildStaticInfo(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
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
          value.toString(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем, не пытается ли пользователь посмотреть свой собственный профиль
    final currentUserId = supabase.auth.currentUser?.id;
    final isSelfProfile = currentUserId == widget.userId;

    if (isLoading || profileData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.friendProfile),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final firstName = profileData!['first_name'] ?? '';
    final lastName = profileData!['last_name'] ?? '';
    final login = profileData!['login'] ?? '';
    final email = profileData!['email'] ?? '';
    final phone = profileData!['phone'];
    final organization = profileData!['organization'];
    final about = profileData!['about'] ?? '';
    final avatarUrl = profileData!['avatar_url'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _profileUpdated
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            login.isNotEmpty
                ? '@$login'
                : AppLocalizations.of(context)!.friendProfile,
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                  child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 200,
                          height: 200,
                          color: _getAvatarColor(widget.userId),
                          child: firstName.isNotEmpty || lastName.isNotEmpty
                              ? Center(
                                  child: Text(
                                    '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.person,
                                  size: 100, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Имя и фамилия
              if (firstName.isNotEmpty || lastName.isNotEmpty)
                Text(
                  '$firstName $lastName',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 24),

              // Социальная информация
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.social,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(),

              _buildStaticInfo(AppLocalizations.of(context)!.login, login),
              _buildStaticInfo(AppLocalizations.of(context)!.email, email),
              _buildOptionalInfo(
                  AppLocalizations.of(context)!.phone, phone?.toString()),
              _buildOptionalInfo(AppLocalizations.of(context)!.organization,
                  organization?.toString()),

              const SizedBox(height: 24),

              if (about.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context)!.aboutMe,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Divider(),
                _buildOptionalInfo(null, about),
                const SizedBox(height: 24),
              ],

              if (sharedTasks.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context)!.sharedTasksTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Divider(),
                ...sharedTasks.map((task) {
                  final user = task['users'] ?? {};
                  final creatorLogin = user['login'] ?? 'unknown';
                  final creatorAvatarUrl = user['avatar_url'];
                  final creatorId = user['id'];
                  final isMe = creatorId == currentUserId;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: creatorAvatarUrl != null &&
                                creatorAvatarUrl.toString().isNotEmpty
                            ? NetworkImage(creatorAvatarUrl)
                            : null,
                        backgroundColor: _getAvatarColor(creatorId ?? ''),
                        child: creatorAvatarUrl == null ||
                                creatorAvatarUrl.toString().isEmpty
                            ? Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(task['title'] ?? ''),
                      subtitle: Text(
                        isMe
                            ? AppLocalizations.of(context)!.createdByMe
                            : '@$creatorLogin',
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
              ],

              // Кнопка управления дружбой (только если это не свой профиль)
              if (!isSelfProfile) _buildFriendshipButton(),
            ],
          ),
        ),
      ),
    );
  }
}

enum FriendshipStatus {
  none, // Нет заявки или она была удалена
  requestSent, // Текущий пользователь отправил заявку
  requestReceived, // Текущий пользователь получил заявку
  friends, // Они друзья
}
