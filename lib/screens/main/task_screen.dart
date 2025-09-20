import 'dart:async';

import 'package:pointo/screens/main/task_detail/task_detail_screen.dart';
import 'package:pointo/utils/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Импорт для HapticFeedback
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:rxdart/rxdart.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with TickerProviderStateMixin {
  bool isAscending = true;
  RealtimeChannel? _realtimeChannel;

  final Set<String> _removingTasks = {};
  List<Map<String, dynamic>> _removedTasks = [];
  final Set<String> _permanentlyRemovedTaskIds = {};

  StreamSubscription<List<Map<String, dynamic>>>? _taskSubscription;
  List<Map<String, dynamic>> _currentTasks = [];

  final Map<String, AnimationController> _taskAnimControllers = {};
  final Map<String, AnimationController> _removeAnimControllers = {};
  final Map<String, Animation<double>> _fadeAnimations = {};
  final Map<String, Animation<Offset>> _slideAnimations = {};

  // Контроллер для анимации при долгом нажатии
  late AnimationController _longPressAnimController;

  // Карта для хранения версий аватаров
  final Map<String, int> _avatarVersions = {};

  @override
  void initState() {
    super.initState();
    _longPressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    setupRealtimeSubscription();
    _subscribeToTasks();
  }

  void _subscribeToTasks() {
    _taskSubscription?.cancel();
    _taskSubscription = getTaskStream().listen(_onTaskData);
  }

  void _onTaskData(List<Map<String, dynamic>> newData) {
    final previousTasks = List<Map<String, dynamic>>.from(_currentTasks);
    final oldIds = previousTasks.map((e) => e['id'] as String).toSet();
    final newIds = newData.map((e) => e['id'] as String).toSet();

    final addedIds = newIds.difference(oldIds);
    final removedIds = oldIds.difference(newIds);

    // Анимация появления новых задач
    for (final id in addedIds) {
      // Пропускаем задачи, которые были удалены ранее
      if (_removingTasks.contains(id) ||
          _removedTasks.any((t) => t['id'] == id) ||
          _permanentlyRemovedTaskIds.contains(id)) {
        continue; // Пропускаем эту задачу и не добавляем её анимацию
      }

      // ignore: unused_local_variable
      final newTask = newData.firstWhere((e) => e['id'] == id);
      _removeAnimControllers.putIfAbsent(id, () {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        );
        _fadeAnimations[id] =
            Tween<double>(begin: 0, end: 1).animate(controller);
        _slideAnimations[id] = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(controller);
        controller.forward();
        return controller;
      });
    }

    // Анимация удаления
    for (final id in removedIds) {
      final task =
          previousTasks.firstWhere((t) => t['id'] == id, orElse: () => {});
      if (task.isNotEmpty) {
        _removedTasks.add(task);
      }

      final controller = _removeAnimControllers[id];
      if (controller != null) {
        controller.reverse().then((_) {
          setState(() {
            _removeAnimControllers.remove(id);
            _fadeAnimations.remove(id);
            _slideAnimations.remove(id);
            _removedTasks.removeWhere((t) => t['id'] == id);
            _currentTasks.removeWhere((t) => t['id'] == id);
          });
        });
      } else {
        setState(() {
          _removedTasks.removeWhere((t) => t['id'] == id);
          _currentTasks.removeWhere((t) => t['id'] == id);
        });
      }
    }

    // Фильтруем задачи с учетом _permanentlyRemovedTaskIds
    final filtered = newData.where((task) {
      final id = task['id'];
      return !_removingTasks.contains(id) &&
          !_removedTasks.any((t) => t['id'] == id) &&
          !_permanentlyRemovedTaskIds.contains(id);
    }).toList();

    setState(() {
      _currentTasks = filtered;
    });
  }

  // Метод для увеличения версии аватара пользователя
  void _incrementAvatarVersion(String userId) {
    _avatarVersions[userId] = (_avatarVersions[userId] ?? 0) + 1;
  }

// Получение текущей версии аватара
  int _getAvatarVersion(String userId) {
    return _avatarVersions[userId] ?? 0;
  }

  void setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;

    if (_realtimeChannel != null) return;

    _realtimeChannel = supabase.channel('realtime:tasks_and_members');

    // Изменения в таблице tasks
    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tasks',
          callback: (payload) {
            print('New task added');
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tasks',
          callback: (payload) {
            final newData = payload.newRecord;
            final oldData = payload.oldRecord;
            if (newData == null || oldData == null) return;

            if (newData['title'] != oldData['title']) {
              print('Task title updated');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'tasks',
          callback: (payload) {
            final taskId = payload.oldRecord['id'];
            if (taskId == null) return;

            if (_currentTasks.any((t) => t['id'] == taskId)) {
              final task = _currentTasks.firstWhere((t) => t['id'] == taskId);
              _removedTasks.add(task);

              final controller = _removeAnimControllers[taskId];
              if (controller != null) {
                controller.reverse().then((_) {
                  setState(() {
                    _removeAnimControllers.remove(taskId);
                    _taskAnimControllers.remove(taskId)?.dispose();
                    _fadeAnimations.remove(taskId);
                    _slideAnimations.remove(taskId);
                    _removedTasks.removeWhere((t) => t['id'] == taskId);
                    _currentTasks.removeWhere((t) => t['id'] == taskId);
                  });
                });
              } else {
                setState(() {
                  _currentTasks.removeWhere((t) => t['id'] == taskId);
                });
              }
            }
          },
        );

    // Изменения в таблице task_members
    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'task_members',
          callback: (payload) {
            final currentUserId = Supabase.instance.client.auth.currentUser?.id;
            final newUserId = payload.newRecord['user_id'];
            final taskId = payload.newRecord['task_id'];

            if (currentUserId == newUserId) {
              // Если пользователя добавили обратно в задачу, удаляем её из списка удаленных
              if (taskId != null) {
                _permanentlyRemovedTaskIds.remove(taskId);
              }

              // Добавляем небольшую задержку перед переподпиской на стрим
              // чтобы дать время на обновление данных в базе
              Future.delayed(Duration(milliseconds: 300), () {
                _subscribeToTasks(); // переподписка на стрим
              });
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'task_members',
          callback: (payload) {
            final currentUserId = Supabase.instance.client.auth.currentUser?.id;
            final removedUserId = payload.oldRecord['user_id'];
            final taskId = payload.oldRecord['task_id'];

            if (removedUserId == currentUserId && taskId != null) {
              _permanentlyRemovedTaskIds
                  .add(taskId); // Добавляем в постоянный сет

              final task = _currentTasks.firstWhere(
                (t) => t['id'] == taskId,
                orElse: () => {},
              );

              if (task.isNotEmpty) {
                _removingTasks.add(taskId);
                _removedTasks.add(task);

                final controller = _removeAnimControllers[taskId];
                if (controller != null) {
                  controller.reverse().then((_) {
                    setState(() {
                      _removeAnimControllers.remove(taskId);
                      _taskAnimControllers.remove(taskId)?.dispose();
                      _fadeAnimations.remove(taskId);
                      _slideAnimations.remove(taskId);
                      _removedTasks.removeWhere((t) => t['id'] == taskId);
                      _currentTasks.removeWhere((t) => t['id'] == taskId);
                      _removingTasks.remove(taskId);
                    });
                  });
                } else {
                  setState(() {
                    _currentTasks.removeWhere((t) => t['id'] == taskId);
                    _removedTasks.removeWhere((t) => t['id'] == taskId);
                    _removingTasks.remove(taskId);
                  });
                }
              }
            }
          },
        );

    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'users',
      callback: (payload) {
        final userId = payload.newRecord['id'];
        final newAvatarUrl = payload.newRecord['avatar_url'];
        final oldAvatarUrl = payload.oldRecord['avatar_url'];

        if (userId == null) return;

        // Проверяем, изменился ли аватар пользователя
        if (newAvatarUrl != oldAvatarUrl) {
          print('User avatar updated for user $userId');

          // Проверяем, есть ли этот пользователь в наших задачах
          final hasUserTasks = _currentTasks.any((task) =>
              task['user_id'] == userId ||
              (task['users'] != null && task['users']['id'] == userId));

          if (hasUserTasks) {
            // Увеличиваем версию аватара
            _incrementAvatarVersion(userId);

            // Обновляем UI
            setState(() {
              for (var task in _currentTasks) {
                if (task['user_id'] == userId && task['users'] != null) {
                  // Обновляем аватарку в объекте пользователя
                  task['users']['avatar_url'] = newAvatarUrl;
                }
              }
            });
          }
        }
      },
    );

    _realtimeChannel!.subscribe();
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    for (final controller in _taskAnimControllers.values) {
      controller.dispose();
    }
    for (final controller in _removeAnimControllers.values) {
      controller.dispose();
    }
    if (_realtimeChannel != null) {
      _realtimeChannel!.unsubscribe();
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    _longPressAnimController.dispose();
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    _avatarVersions.clear();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> getTaskStream() {
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;

    if (currentUserId == null) return const Stream.empty();

    // Создаем поток для членства в задачах
    final membershipStream = client.from('task_members').stream(
        primaryKey: ['user_id', 'task_id']).eq('user_id', currentUserId);

    // Создаем поток для задач, созданных пользователем
    final createdTasksStream = client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('created_at', ascending: isAscending);

    // Объединяем потоки и фильтруем задачи
    return membershipStream.asyncExpand((memberRows) {
      // Извлекаем ID задач, в которых пользователь является участником
      final taskIds = memberRows.map((e) => e['task_id'] as String).toList();

      // Если у пользователя нет задач, в которых он участвует, просто возвращаем его собственные задачи
      if (taskIds.isEmpty) {
        return createdTasksStream;
      }

      // Получаем задачи, в которых пользователь участвует
      final sharedTasksStream = client
          .from('tasks')
          .stream(primaryKey: ['id'])
          .inFilter('id', taskIds)
          .order('created_at', ascending: isAscending);

      // Объединяем созданные и общие задачи
      return Rx.combineLatest2(
        createdTasksStream,
        sharedTasksStream,
        (List<Map<String, dynamic>> created,
            List<Map<String, dynamic>> shared) {
          // Объединяем списки, удаляя дубликаты
          final allTasks = [...created];

          // Добавляем только те задачи из shared, которых нет в created
          for (final task in shared) {
            if (!allTasks.any((t) => t['id'] == task['id'])) {
              allTasks.add(task);
            }
          }

          return allTasks;
        },
      ).asyncMap(_addUsersToTasks);
    });
  }

  Future<List<Map<String, dynamic>>> _addUsersToTasks(
      List<Map<String, dynamic>> tasks) async {
    final client = Supabase.instance.client;
    final userIds = tasks.map((t) => t['user_id'] as String).toSet().toList();

    if (userIds.isEmpty) {
      return tasks; // Предотвращаем запрос с пустым списком ID
    }

    try {
      final users = await client
          .from('users')
          .select('id, login, avatar_url')
          .inFilter('id', userIds);

      final userMap = {
        for (var user in users) user['id']: user,
      };

      for (var task in tasks) {
        final userId = task['user_id'];
        if (userId != null && userMap.containsKey(userId)) {
          task['users'] = userMap[userId];
        } else {
          // Создаем заглушку для отсутствующего пользователя
          task['users'] = {
            'id': userId,
            'login': 'Unknown User', // Можно локализовать это значение
            'avatar_url': null
          };
        }
      }
    } catch (e) {
      print('Error loading users: $e');
      // Обеспечиваем, что у каждой задачи есть информация о пользователе
      for (var task in tasks) {
        if (task['users'] == null) {
          task['users'] = {
            'id': task['user_id'],
            'login': 'Unknown User',
            'avatar_url': null
          };
        }
      }
    }

    return tasks;
  }

  void _startLongPressAnimation(String taskId) {
    final controller = _taskAnimControllers[taskId];
    if (controller != null) {
      controller.repeat(reverse: true);
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 400), () {
        controller.stop();
        controller.reset();
      });
    }
  }

  Future<void> addTask(BuildContext context) async {
    final TextEditingController textController = TextEditingController();

    // ignore: duplicate_ignore
    // ignore: unused_local_variable
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.add_task),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.task_name),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final taskName = textController.text.trim();
              if (taskName.isNotEmpty) {
                try {
                  await Supabase.instance.client.from('tasks').insert({
                    'title': taskName,
                    'user_id': Supabase.instance.client.auth.currentUser?.id,
                  });
                  Navigator.pop(dialogContext, true);
                  // Принудительно вызываем обновление
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .errorWithDetails(e.toString())),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.taskNameCannotBeEmpty)),
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)!.add,
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> editTask(BuildContext context, Map<String, dynamic> task) async {
    final TextEditingController textController =
        TextEditingController(text: task['title']);

    // ignore: duplicate_ignore
    // ignore: unused_local_variable
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.edit_task),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.newTaskName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = textController.text.trim();
              if (newTitle.isNotEmpty) {
                try {
                  await Supabase.instance.client
                      .from('tasks')
                      .update({'title': newTitle}).eq('id', task['id']);
                  Navigator.pop(dialogContext, true);
                  // Принудительно вызываем обновление
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .errorWithDetails(e.toString())),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.taskNameCannotBeEmpty)),
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)!.save,
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteTask(BuildContext context, String taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeletion),
        content: Text(AppLocalizations.of(context)!.confirmDeleteTask),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _removingTasks.add(taskId);
      _permanentlyRemovedTaskIds.add(taskId); // Добавляем в постоянный сет

      final task =
          _currentTasks.firstWhere((t) => t['id'] == taskId, orElse: () => {});
      if (task.isNotEmpty) {
        _removedTasks.add(task);
      }

      final controller = _removeAnimControllers[taskId];
      if (controller != null) {
        await controller.reverse();
      }

      setState(() {
        _currentTasks.removeWhere((t) => t['id'] == taskId);
      });

      await Supabase.instance.client.from('tasks').delete().eq('id', taskId);

      _removingTasks.remove(taskId);
    }
  }

  Future<void> leaveTask(
      BuildContext context, String taskId, String userId) async {
    _removingTasks.add(taskId);
    _permanentlyRemovedTaskIds.add(taskId); // Добавляем в постоянный сет

    final controller = _removeAnimControllers[taskId];

    if (controller != null) {
      await controller.reverse();
    }

    // Удаляем локально из текущего списка
    setState(() {
      _currentTasks.removeWhere((t) => t['id'] == taskId);
    });

    // Удаляем с сервера
    await Supabase.instance.client.from('task_members').delete().match({
      'user_id': userId,
      'task_id': taskId,
    });

    _removingTasks.remove(taskId);
  }

  void changeOrder() {
    setState(() {
      isAscending = !isAscending;
    });

    _subscribeToTasks(); // переподписываемся с новым порядком
  }

  // Показать опции задачи с анимацией
  void _showTaskOptions(BuildContext context, Map<String, dynamic> task,
      bool isMine, String? currentUserId) {
    // Сбрасываем и запускаем анимацию
    _longPressAnimController.reset();
    _longPressAnimController.forward();

    // Вибрация для обратной связи
    HapticFeedback.mediumImpact();

    // Показываем диалог с небольшой задержкой для анимации
    Future.delayed(const Duration(milliseconds: 150), () {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.task_options),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMine) ...[
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    editTask(context, task);
                  },
                  child: Text(AppLocalizations.of(context)!.edit_task),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await deleteTask(context, task['id']);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.deleteTask,
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ] else ...[
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await leaveTask(context, task['id'], currentUserId!);
                    await Supabase.instance.client
                        .from('task_members')
                        .delete()
                        .match({
                      'user_id': currentUserId,
                      'task_id': task['id'],
                    });
                    // Принудительно вызываем обновление
                  },
                  child: Text(
                    AppLocalizations.of(context)!.exitFromTask,
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final allTasks = [..._currentTasks, ..._removedTasks];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 1,
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: ResponsiveWrapper(
        maxWidth: 600,
        child: allTasks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.yourTasksWillAppearHere,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 10.0),
                itemCount: allTasks.length,
                itemBuilder: (context, index) {
                  final task = allTasks[index];
                  final taskId = task['id'];
                  final creator = task['users'];
                  final isMine = creator?['id'] == currentUserId ||
                      task['user_id'] == currentUserId;

                  // Анимации
                  _taskAnimControllers.putIfAbsent(taskId, () {
                    return AnimationController(
                      vsync: this,
                      duration: const Duration(milliseconds: 100),
                      lowerBound: 0.0,
                      upperBound: 0.03,
                    );
                  });

                  _removeAnimControllers.putIfAbsent(taskId, () {
                    final controller = AnimationController(
                      vsync: this,
                      duration: const Duration(milliseconds: 300),
                    );

                    _fadeAnimations[taskId] =
                        Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                          parent: controller, curve: Curves.easeOut),
                    );
                    _slideAnimations[taskId] = Tween<Offset>(
                      begin: const Offset(1.0, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                          parent: controller, curve: Curves.easeOut),
                    );

                    controller.forward();
                    return controller;
                  });

                  final shakeController = _taskAnimControllers[taskId]!;
                  final fadeAnim = _fadeAnimations[taskId]!;
                  final slideAnim = _slideAnimations[taskId]!;

                  return FadeTransition(
                    opacity: fadeAnim,
                    child: SlideTransition(
                      position: slideAnim,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TaskDetailScreen(taskId: taskId),
                            ),
                          );
                        },
                        onLongPress: () => _showTaskOptions(
                            context, task, isMine, currentUserId),
                        onLongPressStart: (_) =>
                            _startLongPressAnimation(taskId),
                        child: AnimatedBuilder(
                          animation: shakeController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + shakeController.value,
                              child: child,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.shadow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.surface,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (creator?['avatar_url'] != null)
                                  Hero(
                                    tag: "avatar-${task['id']}",
                                    child: CircleAvatar(
                                      // Используем ключ с версией аватара для принудительного обновления
                                      key: ValueKey(
                                          "avatar-${creator!['id']}-${_getAvatarVersion(creator['id'])}"),
                                      radius: 20,
                                      backgroundImage:
                                          NetworkImage(creator!['avatar_url']),
                                    ),
                                  )
                                else
                                  const CircleAvatar(
                                    radius: 20,
                                    child: Icon(Icons.person),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Hero(
                                        tag: "title-${task['id']}",
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Text(
                                            task['title'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isMine
                                            ? AppLocalizations.of(context)!
                                                .createdByMe
                                            : AppLocalizations.of(context)!
                                                .authorLabel(
                                                creator != null &&
                                                        creator['login'] != null
                                                    ? creator['login']
                                                    : AppLocalizations.of(
                                                            context)!
                                                        .unknown,
                                              ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.adjust_sharp,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        children: [
          SpeedDialChild(
            label: AppLocalizations.of(context)!.add_task,
            child: const Icon(Icons.add),
            onTap: () => addTask(context),
          ),
          SpeedDialChild(
            label: AppLocalizations.of(context)!.change_order,
            child: const Icon(Icons.sort),
            onTap: changeOrder,
          ),
        ],
      ),
    );
  }
}
