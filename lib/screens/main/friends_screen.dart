// ignore_for_file: unused_local_variable

import 'dart:async';
import 'package:pointo/screens/main/friend_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> friendsTo = [];
  List<Map<String, dynamic>> friendsFrom = [];
  List<Map<String, dynamic>> sentRequests = [];
  List<Map<String, dynamic>> receivedRequests = [];
  String selectedCategory = 'Друзья';
  bool _isSubscribedToFriendRequests = false;
  bool _isSubscribedToUserChanges = false;

  // Animation controllers
  late AnimationController _listAnimationController;
  late AnimationController _itemUpdateController;
  RealtimeChannel? _requestsSubscription;
  RealtimeChannel? _usersSubscription;
  bool _isLoading = true;

  // Map для отслеживания анимаций обновления отдельных пользователей
  final Map<String, bool> _updatingUsers = {};
  // Простое отслеживание обновляемых пользователей
  Set<String> _updatedUserIds = {};

 @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Контроллер для анимации обновления элементов
    _itemUpdateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fetchFriendsData().then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _listAnimationController.forward();
      }
    });

    // Setup real-time subscription
    _setupRealtimeSubscription();
    _setupUserProfileSubscription();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _itemUpdateController.dispose();
    _requestsSubscription?.unsubscribe();
    _usersSubscription?.unsubscribe();
    _isSubscribedToFriendRequests = false;
    
    if (_requestsSubscription != null) {
      Supabase.instance.client.removeChannel(_requestsSubscription!);
    }
    
    if (_usersSubscription != null) {
      Supabase.instance.client.removeChannel(_usersSubscription!);
    }
    
    super.dispose();
  }

  // Новый метод - подписка на изменения в таблице пользователей
  void _setupUserProfileSubscription() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    print('Настраиваем подписку на изменения профилей пользователей...');
    
    _usersSubscription = supabase
        .channel('users_profile_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            print('Получено событие обновления пользователя!');
            print('Данные: ${payload.newRecord}');
            
            // Получаем ID обновленного пользователя
            final updatedUserId = payload.newRecord['id'] as String;
            
            // Проверяем, присутствует ли этот пользователь в наших списках
            bool isRelevantUser = false;
            
            // Проверка в списке друзей
            for (var friend in friends) {
              if (friend['users'] != null && friend['users']['id'] == updatedUserId) {
                isRelevantUser = true;
                break;
              }
            }
            
            // Проверка в списке исходящих заявок
            if (!isRelevantUser) {
              for (var request in sentRequests) {
                if (request['users'] != null && request['users']['id'] == updatedUserId) {
                  isRelevantUser = true;
                  break;
                }
              }
            }
            
            // Проверка в списке входящих заявок
            if (!isRelevantUser) {
              for (var request in receivedRequests) {
                if (request['users'] != null && request['users']['id'] == updatedUserId) {
                  isRelevantUser = true;
                  break;
                }
              }
            }
            
            if (isRelevantUser) {
              print('Обнаружено обновление профиля друга или пользователя в заявке: $updatedUserId');
              
              // Добавляем ID пользователя в список обновленных
              setState(() {
                _updatedUserIds.add(updatedUserId);
              });
              
              // Обновляем данные пользователя во всех списках
              _updateUserData(updatedUserId, payload.newRecord);
            }
          },
        )
        .subscribe((status, error) {
          if (error != null) {
            print('Ошибка подписки на изменения профилей: $error');
          } else {
            print('Подписка на изменения профилей активирована успешно: $status');
          }
        });
  }

  // Метод для обновления данных пользователя во всех списках
  void _updateUserData(String userId, Map<String, dynamic> newUserData) {
    print('Обновляем данные пользователя $userId в списках...');
    
    bool needsUpdate = false;
    
    // Обновление в списке друзей
    for (var i = 0; i < friends.length; i++) {
      if (friends[i]['users'] != null && friends[i]['users']['id'] == userId) {
        friends[i]['users']['first_name'] = newUserData['first_name'];
        friends[i]['users']['last_name'] = newUserData['last_name'];
        friends[i]['users']['avatar_url'] = newUserData['avatar_url'];
        needsUpdate = true;
      }
    }
    
    // Обновление в списке исходящих заявок
    for (var i = 0; i < sentRequests.length; i++) {
      if (sentRequests[i]['users'] != null && sentRequests[i]['users']['id'] == userId) {
        sentRequests[i]['users']['first_name'] = newUserData['first_name'];
        sentRequests[i]['users']['last_name'] = newUserData['last_name'];
        sentRequests[i]['users']['avatar_url'] = newUserData['avatar_url'];
        needsUpdate = true;
      }
    }
    
    // Обновление в списке входящих заявок
    for (var i = 0; i < receivedRequests.length; i++) {
      if (receivedRequests[i]['users'] != null && receivedRequests[i]['users']['id'] == userId) {
        receivedRequests[i]['users']['first_name'] = newUserData['first_name'];
        receivedRequests[i]['users']['last_name'] = newUserData['last_name'];
        receivedRequests[i]['users']['avatar_url'] = newUserData['avatar_url'];
        needsUpdate = true;
      }
    }
    
    if (needsUpdate && mounted) {
      setState(() {
        // Обновляем UI
      });
      
      // Устанавливаем таймер для сброса подсветки элемента
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _updatedUserIds.remove(userId);
          });
        }
      });
    }
  }

  Set<String> _getUserIds() {
    Set<String> userIds = {};

    // Добавляем ID друзей
    for (var friend in friends) {
      if (friend['users'] != null && friend['users']['id'] != null) {
        userIds.add(friend['users']['id']);
      }
    }

    // Добавляем ID из исходящих заявок
    for (var request in sentRequests) {
      if (request['users'] != null && request['users']['id'] != null) {
        userIds.add(request['users']['id']);
      }
    }

    // Добавляем ID из входящих заявок
    for (var request in receivedRequests) {
      if (request['users'] != null && request['users']['id'] != null) {
        userIds.add(request['users']['id']);
      }
    }

    return userIds;
  }

  Future<void> _setupUsersRealtimeSubscription() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    if (_isSubscribedToUserChanges) return;

    // Отписываемся от существующих подписок
    await _usersSubscription?.unsubscribe();
    if (_usersSubscription != null) {
      Supabase.instance.client.removeChannel(_usersSubscription!);
    }

    // Получаем ID всех друзей и пользователей в заявках
    Set<String> userIds = _getUserIds();

    // Если нет пользователей для отслеживания, выходим
    if (userIds.isEmpty) {
      return;
    }

    // Создаем подписку на изменения в таблице users
    _usersSubscription = supabase
        .channel('user_profile_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          callback: (payload) async {
            print(
                'Получено обновление профиля пользователя: ${payload.eventType}');

            // Получаем ID обновленного пользователя
            final String updatedUserId = payload.newRecord['id'];

            // Проверяем, что это пользователь, который нас интересует (друг или участник заявки)
            if (!userIds.contains(updatedUserId)) {
              return;
            }

            print(
                'Обнаружено изменение профиля пользователя с ID: $updatedUserId');

            // Обновляем данные о пользователе в наших списках
            await _updateUserProfile(updatedUserId, payload.newRecord);
          },
        )
        .subscribe((status, error) {
      if (error != null) {
        print('Ошибка подписки на изменения профилей: $error');
      } else {
        print('Подписка на изменения профилей успешна: $status');
        _isSubscribedToUserChanges = true;
      }
    });

    print(
        'Подписка на изменения профилей настроена для друзей пользователя ID: $userId');
  }

  Future<void> _updateUserProfile(
      String userId, Map<String, dynamic> userData) async {
    bool updatedAny = false;

    // Устанавливаем флаг обновления для этого пользователя
    setState(() {
      _updatingUsers[userId] = true;
    });

    // Функция для обновления данных пользователя в списке
    void updateUserInList(List<Map<String, dynamic>> list) {
      for (int i = 0; i < list.length; i++) {
        if (list[i]['users'] != null && list[i]['users']['id'] == userId) {
          // Получаем старые данные для проверки изменений
          final oldUserData = list[i]['users'];

          // Проверяем, были ли изменения
          bool hasChanges =
              oldUserData['first_name'] != userData['first_name'] ||
                  oldUserData['last_name'] != userData['last_name'] ||
                  oldUserData['avatar_url'] != userData['avatar_url'];

          if (hasChanges) {
            // Обновляем только нужные поля, сохраняя остальные данные
            list[i]['users'] = {
              ...list[i]['users'],
              'first_name': userData['first_name'],
              'last_name': userData['last_name'],
              'avatar_url': userData['avatar_url'],
            };
            updatedAny = true;
          }
        }
      }
    }

    // Обновляем каждый список
    updateUserInList(friends);
    updateUserInList(sentRequests);
    updateUserInList(receivedRequests);

    // Если были изменения, обновляем UI и запускаем анимацию
    if (updatedAny && mounted) {
      setState(() {});

      // Запускаем анимацию обновления
      _itemUpdateController.reset();
      _itemUpdateController.forward();

      // Сбрасываем флаг обновления через некоторое время
      Future.delayed(Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _updatingUsers.remove(userId);
          });
        }
      });
    } else {
      // Если изменений не было, сразу убираем флаг
      setState(() {
        _updatingUsers.remove(userId);
      });
    }
  }

  // Метод для периодического обновления списка ID для отслеживания изменений
  Future<void> _refreshUserSubscriptions() async {
    // Получаем актуальный список ID пользователей
    Set<String> userIds = _getUserIds();

    // Обновляем подписки только если список изменился
    if (userIds.isNotEmpty && _usersSubscription != null) {
      // Для полного обновления подписки нужно пересоздать канал
      // Это более надежно, чем пытаться модифицировать существующую подписку
      await _setupUsersRealtimeSubscription();
    }
  }

  Future<void> _setupRealtimeSubscription() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    if (_isSubscribedToFriendRequests) return;

    // Отписываемся от существующих подписок
    await _requestsSubscription?.unsubscribe();
    if (_requestsSubscription != null) {
      Supabase.instance.client.removeChannel(_requestsSubscription!);
    }

    // Создаем подписку на все изменения в таблице friend_requests
    _requestsSubscription = supabase
        .channel('friend_requests_changes')
        // Слушаем изменения, где пользователь является отправителем
        .onPostgresChanges(
          event:
              PostgresChangeEvent.all, // Все события (INSERT, UPDATE, DELETE)
          schema: 'public',
          table: 'friend_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sender_id',
            value: userId,
          ),
          callback: (payload) {
            print('Получено событие для отправителя: ${payload.eventType}');
            if (payload.eventType == 'DELETE') {
              print(
                  'Обнаружено удаление записи, где пользователь - отправитель');
            }
            _fetchFriendsData(animateChanges: true);
          },
        )
        // Слушаем изменения, где пользователь является получателем
        .onPostgresChanges(
          event:
              PostgresChangeEvent.all, // Все события (INSERT, UPDATE, DELETE)
          schema: 'public',
          table: 'friend_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            print('Получено событие для получателя: ${payload.eventType}');
            if (payload.eventType == 'DELETE') {
              print(
                  'Обнаружено удаление записи, где пользователь - получатель');
            }
            _fetchFriendsData(animateChanges: true);
          },
        )
        .subscribe((status, error) {
      if (error != null) {
        print('Ошибка подписки на изменения: $error');
      } else {
        print('Подписка на изменения успешна: $status');
        _isSubscribedToFriendRequests = true;
      }
    });

    print('Подписка на реальное время настроена для пользователя ID: $userId');
  }

  Future<void> _fetchFriendsData({bool animateChanges = false}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      print('Запрос данных о друзьях...');

      // Сохраняем текущие списки для сравнения
      final oldFriends = Map<String, Map<String, dynamic>>.fromIterable(friends,
          key: (item) => item['id'] as String,
          value: (item) => item as Map<String, dynamic>);

      final oldSentRequests = Map<String, Map<String, dynamic>>.fromIterable(
          sentRequests,
          key: (item) => item['id'] as String,
          value: (item) => item as Map<String, dynamic>);

      final oldReceivedRequests =
          Map<String, Map<String, dynamic>>.fromIterable(receivedRequests,
              key: (item) => item['id'] as String,
              value: (item) => item as Map<String, dynamic>);

      final friendsResponseTo = await supabase
          .from('friend_requests')
          .select(
            'id, receiver_id, sender_id, status, users:sender_id(id, first_name, last_name, avatar_url)',
          )
          .eq('receiver_id', user.id)
          .eq('status', 'accepted');

      final friendsResponseFrom = await supabase
          .from('friend_requests')
          .select(
              'id, receiver_id, sender_id, status, users:receiver_id(id, first_name, last_name, avatar_url)')
          .eq('sender_id', user.id)
          .eq('status', 'accepted');

      final sentResponse = await supabase
          .from('friend_requests')
          .select(
              'id, receiver_id, users:receiver_id(id, first_name, last_name, avatar_url)')
          .eq('sender_id', user.id)
          .eq('status', 'pending');

      final receivedResponse = await supabase
          .from('friend_requests')
          .select(
              'id, sender_id, users:sender_id(id, first_name, last_name, avatar_url)')
          .eq('receiver_id', user.id)
          .eq('status', 'pending');

      if (mounted) {
        // Получаем новые данные
        final newFriendsTo = List<Map<String, dynamic>>.from(friendsResponseTo);
        final newFriendsFrom =
            List<Map<String, dynamic>>.from(friendsResponseFrom);
        final newSentRequests = List<Map<String, dynamic>>.from(sentResponse);
        final newReceivedRequests =
            List<Map<String, dynamic>>.from(receivedResponse);
        final newFriends = [...newFriendsTo, ...newFriendsFrom];

        // Создаем Map для новых данных
        final newFriendsMap = Map<String, Map<String, dynamic>>.fromIterable(
            newFriends,
            key: (item) => item['id'] as String,
            value: (item) => item as Map<String, dynamic>);

        final newSentRequestsMap =
            Map<String, Map<String, dynamic>>.fromIterable(newSentRequests,
                key: (item) => item['id'] as String,
                value: (item) => item as Map<String, dynamic>);

        final newReceivedRequestsMap =
            Map<String, Map<String, dynamic>>.fromIterable(newReceivedRequests,
                key: (item) => item['id'] as String,
                value: (item) => item as Map<String, dynamic>);

        // Проверяем, есть ли изменения (добавления, удаления или изменения)
        bool hasChanges = false;

        setState(() {
          friendsTo = newFriendsTo;
          friendsFrom = newFriendsFrom;
          sentRequests = newSentRequests;
          receivedRequests = newReceivedRequests;
          friends = newFriends;
        });

        _refreshUserSubscriptions();

        // Проверяем удаление или добавление друзей
        if (oldFriends.length != newFriendsMap.length) {
          hasChanges = true;
          print(
              'Изменилось количество друзей: ${oldFriends.length} -> ${newFriendsMap.length}');
        } else {
          // Проверяем изменения в существующих друзьях
          for (final id in oldFriends.keys) {
            if (!newFriendsMap.containsKey(id)) {
              hasChanges = true;
              print('Удален друг с ID: $id');
              break;
            }
          }
        }

        // Проверяем изменения в исходящих заявках
        if (!hasChanges &&
            oldSentRequests.length != newSentRequestsMap.length) {
          hasChanges = true;
          print('Изменилось количество исходящих заявок');
        } else if (!hasChanges) {
          // Проверяем изменения в существующих исходящих заявках
          for (final id in oldSentRequests.keys) {
            if (!newSentRequestsMap.containsKey(id)) {
              hasChanges = true;
              print('Удалена исходящая заявка с ID: $id');
              break;
            }
          }
        }

        // Проверяем изменения во входящих заявках
        if (!hasChanges &&
            oldReceivedRequests.length != newReceivedRequestsMap.length) {
          hasChanges = true;
          print('Изменилось количество входящих заявок');
        } else if (!hasChanges) {
          // Проверяем изменения в существующих входящих заявках
          for (final id in oldReceivedRequests.keys) {
            if (!newReceivedRequestsMap.containsKey(id)) {
              hasChanges = true;
              print('Удалена входящая заявка с ID: $id');
              break;
            }
          }
        }

        setState(() {
          friendsTo = newFriendsTo;
          friendsFrom = newFriendsFrom;
          sentRequests = newSentRequests;
          receivedRequests = newReceivedRequests;
          friends = newFriends;
        });

        // Запускаем анимацию только при изменениях или если она специально запрошена
        if (hasChanges || animateChanges) {
          print('Запуск анимации обновления списка');
          _listAnimationController.reset();
          _listAnimationController.forward();
        }
      }
    } catch (e) {
      print('Ошибка при получении данных о друзьях: $e');
    }
  }

  // Удаляем эту функцию, так как используем более точное сравнение с Map
  // bool _areListsEqual(List<String> list1, List<String> list2) {
  //   if (list1.length != list2.length) return false;
  //
  //   // Сортируем оба списка для точного сравнения
  //   final sorted1 = List<String>.from(list1)..sort();
  //   final sorted2 = List<String>.from(list2)..sort();
  //
  //   for (int i = 0; i < sorted1.length; i++) {
  //     if (sorted1[i] != sorted2[i]) return false;
  //   }
  //
  //   return true;
  // }

  Future<void> _sendFriendRequestByLogin(
      BuildContext context, String friendId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final existingRequest = await supabase
          .from('friend_requests')
          .select('id, status, sender_id, receiver_id')
          .or(
            'and(sender_id.eq.${user.id},receiver_id.eq.$friendId),and(sender_id.eq.$friendId,receiver_id.eq.${user.id})',
          )
          .maybeSingle();

      if (existingRequest != null) {
        final status = existingRequest['status'];
        final requestId = existingRequest['id'];
        final senderId = existingRequest['sender_id'];
        final receiverId = existingRequest['receiver_id'];

        if (status == 'deleted') {
          // Восстанавливаем заявку с новыми ролями
          await supabase.from('friend_requests').update({
            'status': 'pending',
            'sender_id': user.id,
            'receiver_id': friendId,
          }).eq('id', requestId);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.friendRequestSent),
          ));
          return;
        }

        // Иначе — уже есть активная заявка или дружба
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.friendRequestAlreadySentOrFriend),
        ));
        return;
      }

      // Если не существует — создаём новую
      await supabase.from('friend_requests').insert({
        'sender_id': user.id,
        'receiver_id': friendId,
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.friendRequestSent),
      ));
    } catch (e) {
      print('Ошибка при отправке заявки: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Ошибка при отправке: ${e.toString()}"),
      ));
    }
  }

  Future<void> _showAddFriendDialog() async {
    final loginController = TextEditingController();
    Timer? _debounce;
    final user = supabase.auth.currentUser;

    List<Map<String, dynamic>> searchResults = [];
    String lastQuery = '';
    bool dialogOpen = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void _onSearchChanged(String value) {
              if (_debounce?.isActive ?? false) _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () async {
                if (!dialogOpen) return;

                try {
                  if (value.trim().isEmpty) {
                    if (dialogOpen) {
                      setState(() {
                        searchResults = [];
                        lastQuery = '';
                      });
                    }
                    return;
                  }

                  final usersResponse = await supabase
                      .from('users')
                      .select('id, login, first_name, last_name, avatar_url')
                      .ilike('login', '%$value%')
                      .not('id', 'eq', user!.id)
                      .limit(100);

                  final foundUsers =
                      List<Map<String, dynamic>>.from(usersResponse);
                  final foundIds =
                      foundUsers.map((u) => u['id'] as String).toList();

                  if (foundIds.isEmpty) {
                    if (dialogOpen) {
                      setState(() {
                        searchResults = [];
                        lastQuery = value;
                      });
                    }
                    return;
                  }

                  final requestsResponse = await supabase
                      .from('friend_requests')
                      .select('sender_id, receiver_id, status')
                      .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
                      .neq('status', 'deleted');

                  final List<Map<String, dynamic>> requests =
                      List<Map<String, dynamic>>.from(requestsResponse);

                  final blockedUserIds = <String>{};
                  for (var req in requests) {
                    final sender = req['sender_id'];
                    final receiver = req['receiver_id'];
                    final otherId = sender == user.id ? receiver : sender;
                    blockedUserIds.add(otherId);
                  }

                  final filtered = foundUsers
                      .where((u) => !blockedUserIds.contains(u['id']))
                      .toList();

                  if (dialogOpen) {
                    setState(() {
                      searchResults = filtered;
                      lastQuery = value;
                    });
                  }
                } catch (e) {
                  print('Ошибка в поиске друга: $e');
                }
              });
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: SizedBox(
                width: 300,
                height: 500,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.addFriendTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: loginController,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.friends_login,
                          hintText:
                              AppLocalizations.of(context)!.enterLoginHint,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: searchResults.isNotEmpty
                              ? ListView.builder(
                                  key: const ValueKey('results'),
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    final foundUser = searchResults[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage:
                                            foundUser['avatar_url'] != null
                                                ? NetworkImage(
                                                    foundUser['avatar_url'])
                                                : null,
                                        child: foundUser['avatar_url'] == null
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      title: Text(
                                        '${foundUser['first_name'] ?? ''} ${foundUser['last_name'] ?? ''} (@${foundUser['login']})',
                                      ),
                                      onTap: () async {
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text(
                                                AppLocalizations.of(context)!
                                                    .confirmAddFriendTitle),
                                            content: Text(
                                                AppLocalizations.of(context)!
                                                    .confirmAddFriendContent(
                                                        foundUser['login'])),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: Text(AppLocalizations.of(
                                                        context)!
                                                    .cancel),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: Text(AppLocalizations.of(
                                                        context)!
                                                    .add),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          try {
                                            await _sendFriendRequestByLogin(
                                                context, foundUser['id']);
                                            dialogOpen = false;
                                            Navigator.of(context)
                                                .pop(); // Закрыть окно
                                          } catch (e) {
                                            print('Ошибка при отправке: $e');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(AppLocalizations
                                                          .of(context)!
                                                      .genericErrorWithDetails(
                                                          e.toString()))),
                                            );
                                          }
                                        }
                                      },
                                    );
                                  },
                                )
                              : (lastQuery.isNotEmpty
                                  ? Center(
                                      key: ValueKey('no_results'),
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .usersNotFound,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            dialogOpen = false;
                            Navigator.of(context).pop();
                          },
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    _debounce?.cancel();
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await supabase
          .from('friend_requests')
          .update({'status': 'accepted'}).eq('id', requestId);
      // Обновление данных произойдет автоматически через подписку
    } catch (e) {
      print('Ошибка при принятии заявки: $e');
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await supabase
          .from('friend_requests')
          .update({'status': 'deleted'}).eq('id', requestId);
      // Обновление данных произойдет автоматически через подписку
    } catch (e) {
      print('Ошибка при отклонении заявки: $e');
    }
  }

  Future<void> _cancelSentRequest(String requestId) async {
    try {
      await supabase
          .from('friend_requests')
          .update({'status': 'deleted'}).eq('id', requestId);

      // Обновление данных произойдет автоматически через подписку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.friendRequestCancelled)),
      );
    } catch (e) {
      print('Ошибка при удалении заявки: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .friendRequestCancelError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentList;
    if (selectedCategory == 'Друзья') {
      currentList = friends;
    } else if (selectedCategory == 'Исходящие заявки') {
      currentList = sentRequests;
    } else {
      currentList = receivedRequests;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.friends,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddFriendDialog,
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    DropdownMenuItem(
                        value: 'Друзья',
                        child: Text(AppLocalizations.of(context)!.friends)),
                    DropdownMenuItem(
                        value: 'Входящие заявки',
                        child: Text(
                            AppLocalizations.of(context)!.incoming_requests)),
                    DropdownMenuItem(
                        value: 'Исходящие заявки',
                        child: Text(
                            AppLocalizations.of(context)!.outgoing_requests)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                      // Анимация списка при переключении категорий
                      _listAnimationController.reset();
                      _listAnimationController.forward();
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : currentList.isEmpty
                      ? Center(
                          key: ValueKey<String>('empty-${selectedCategory}'),
                          child: Text(
                            selectedCategory == 'Друзья'
                                ? AppLocalizations.of(context)?.noFriendsYet ??
                                    'У вас пока нет друзей.'
                                : selectedCategory == 'Входящие заявки'
                                    ? AppLocalizations.of(context)
                                            ?.noIncomingRequests ??
                                        'Нет входящих заявок.'
                                    : AppLocalizations.of(context)
                                            ?.noOutgoingRequests ??
                                        'Нет исходящих заявок.',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                        )
                      : AnimatedBuilder(
                          animation: _listAnimationController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _listAnimationController,
                                curve: Curves.easeIn,
                              ),
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _listAnimationController,
                                  curve: Curves.easeOut,
                                )),
                                child: ListView.builder(
                                  key: ValueKey<String>(selectedCategory),
                                  padding: const EdgeInsets.all(8),
                                  itemCount: currentList.length,
                                  itemBuilder: (context, index) {
                                    final item = currentList[index];
                                    final userId = item['users']['id'];
                                    // Проверяем, обновляется ли элемент
                                    final isUpdating =
                                        _updatingUsers[userId] ?? false;

                                    // Поэтапная анимация для элементов списка
                                    return AnimatedBuilder(
                                      animation: _listAnimationController,
                                      builder: (context, child) {
                                        final itemAnimation =
                                            _listAnimationController.drive(
                                          CurveTween(
                                            curve: Interval(
                                              index * 0.05,
                                              0.6 + index * 0.05,
                                              curve: Curves.easeOut,
                                            ),
                                          ),
                                        );

                                        return FadeTransition(
                                          opacity: itemAnimation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.05, 0),
                                              end: Offset.zero,
                                            ).animate(itemAnimation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: AnimatedBuilder(
                                        animation: _itemUpdateController,
                                        builder: (context, child) {
                                          // Применяем анимацию только к обновляемым элементам
                                          if (isUpdating) {
                                            return TweenAnimationBuilder<
                                                double>(
                                              tween: Tween<double>(
                                                  begin: 0.0, end: 1.0),
                                              duration:
                                                  Duration(milliseconds: 700),
                                              builder: (context, value, child) {
                                                return DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.2 *
                                                                (1.0 - value)),
                                                        Colors.transparent,
                                                      ],
                                                      radius: 1.8 - value * 0.8,
                                                      center: Alignment.center,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: child,
                                                );
                                              },
                                              child: child,
                                            );
                                          }
                                          return child!;
                                        },
                                        child: Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: ListTile(
                                            onTap: () {
                                              final user = item['users'];
                                              final userId = user != null
                                                  ? user['id']
                                                  : null;

                                              if (userId is String &&
                                                  userId.isNotEmpty) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        UserProfilePage(
                                                            userId: userId),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .userIdMissingError),
                                                  ),
                                                );
                                              }
                                            },
                                            leading: Hero(
                                              tag:
                                                  'avatar-${item['users']['id']}',
                                              child: CircleAvatar(
                                                backgroundImage: item['users']
                                                            ['avatar_url'] !=
                                                        null
                                                    ? NetworkImage(item['users']
                                                        ['avatar_url'])
                                                    : null,
                                                child: item['users']
                                                            ['avatar_url'] ==
                                                        null
                                                    ? const Icon(Icons.person)
                                                    : null,
                                              ),
                                            ),
                                            title: Text(
                                              '${item['users']['first_name']} ${item['users']['last_name']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            trailing: selectedCategory ==
                                                    'Исходящие заявки'
                                                ? IconButton(
                                                    icon: const Icon(
                                                        Icons.cancel,
                                                        color: Colors.red),
                                                    onPressed: () =>
                                                        _cancelSentRequest(
                                                            item['id']),
                                                  )
                                                : selectedCategory ==
                                                        'Входящие заявки'
                                                    ? Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons.check,
                                                                color: Colors
                                                                    .green),
                                                            onPressed: () =>
                                                                _acceptRequest(
                                                                    item['id']),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons.close,
                                                                color:
                                                                    Colors.red),
                                                            onPressed: () =>
                                                                _declineRequest(
                                                                    item['id']),
                                                          ),
                                                        ],
                                                      )
                                                    : null,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
