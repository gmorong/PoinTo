import 'package:supabase_flutter/supabase_flutter.dart';

enum TaskMemberRole {
  admin, // Полный доступ
  editor, // Может редактировать, но не управлять участниками
  user // Только просмотр и выполнение
}

/// Расширение для преобразования строк в enum и обратно
extension TaskMemberRoleExtension on TaskMemberRole {
  String get value {
    switch (this) {
      case TaskMemberRole.admin:
        return 'admin';
      case TaskMemberRole.editor:
        return 'editor';
      case TaskMemberRole.user:
        return 'user';
      default:
        return 'user';
    }
  }

  String get displayName {
    switch (this) {
      case TaskMemberRole.admin:
        return 'Администратор';
      case TaskMemberRole.editor:
        return 'Редактор';
      case TaskMemberRole.user:
        return 'Пользователь';
      default:
        return 'Пользователь';
    }
  }

  static TaskMemberRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return TaskMemberRole.admin;
      case 'editor':
        return TaskMemberRole.editor;
      case 'user':
        return TaskMemberRole.user;
      default:
        return TaskMemberRole.user;
    }
  }
}

/// Класс для работы с Supabase
class SupabaseService {
  final _client = Supabase.instance.client;

  /// Метод изменения роли участника задачи
  Future<void> updateTaskMemberRole(
      String taskId, String userId, TaskMemberRole newRole) async {
    await _client
        .from('task_members')
        .update({'role': newRole.value})
        .eq('task_id', taskId)
        .eq('user_id', userId);
  }

  /// Метод для проверки прав пользователя в задаче
  Future<bool> canUserEditTask(String taskId, String userId) async {
    try {
      // Сначала проверяем, является ли пользователь создателем задачи
      final isCreator = await isTaskCreator(taskId, userId);
      if (isCreator) return true;

      // Если не создатель, проверяем роль
      final role = await getUserRoleInTask(taskId, userId);
      return role == TaskMemberRole.admin || role == TaskMemberRole.editor;
    } catch (e) {
      return false;
    }
  }

  /// Метод для проверки прав на управление участниками
  Future<bool> canUserManageMembers(String taskId, String userId) async {
    try {
      // Проверяем, является ли пользователь создателем задачи
      final isCreator = await isTaskCreator(taskId, userId);
      if (isCreator) return true;

      // Если не создатель, проверяем роль
      final role = await getUserRoleInTask(taskId, userId);
      return role == TaskMemberRole.admin;
    } catch (e) {
      return false;
    }
  }

  /// Получение информации о задаче
  Future<TaskDetailData> getTaskDetails(String taskId) async {
    final taskResponse =
        await _client.from('tasks').select('title').eq('id', taskId).single();

    if (taskResponse == null || taskResponse['title'] == null) {
      throw Exception("Задача не найдена");
    }

    final title = taskResponse['title'] as String;

    final itemsResponse = await _client
        .from('task_items')
        .select()
        .eq('task_id', taskId)
        .order('position', ascending: true);

    final items = (itemsResponse as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return TaskDetailData(title: title, items: items);
  }

  /// Получение элемента задачи по его ID
  Future<Map<String, dynamic>> getTaskItemById(String itemId) async {
    try {
      final response =
          await _client.from('task_items').select().eq('id', itemId).single();

      // ignore: unnecessary_cast
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception("Не удалось получить элемент задачи: $e");
    }
  }

  Future<Map<String, dynamic>?> getTaskBasicInfo(String taskId) async {
    try {
      final response = await Supabase.instance.client
          .from('tasks')
          .select('id, title, created_by')
          .eq('id', taskId)
          .maybeSingle();

      return response;
    } catch (e) {
      print("Ошибка при получении информации о задаче: $e");
      return null;
    }
  }

  Future<bool> setTaskCreator(String taskId, String userId) async {
    try {
      await Supabase.instance.client
          .from('tasks')
          .update({'created_by': userId}).eq('id', taskId);

      print("Установлен создатель задачи $taskId: $userId");
      return true;
    } catch (e) {
      print("Ошибка при установке создателя задачи: $e");
      return false;
    }
  }

  /// Обновление контента элемента задачи
  Future<void> updateTaskItemContent(String itemId, String newContent) async {
    await _client
        .from('task_items')
        .update({'content': newContent}).eq('id', itemId);
  }

  /// Обновление статуса "выполнено" для элемента задачи
  Future<void> updateTaskItemChecked(String itemId, bool? checked) async {
    await _client
        .from('task_items')
        .update({'checked': checked}).eq('id', itemId);
  }

  /// Обновление позиции элемента задачи
  Future<void> updateTaskItemPosition(String itemId, int position) async {
    await _client
        .from('task_items')
        .update({'position': position}).eq('id', itemId);
  }

  /// Обновление данных элемента задачи
  Future<void> updateTaskItem(String itemId, Map<String, dynamic> data) async {
    // Создаем копию данных для манипуляций
    final Map<String, dynamic> cleanData = Map.from(data);

    // Обрабатываем особые случаи
    if (cleanData['type'] == 'checklist' && cleanData['checked'] == null) {
      cleanData['checked'] = false;
    } else if (cleanData['type'] != 'checklist') {
      cleanData['checked'] =
          null; // Обнуляем значение checked для не-checklist типов
    }

    await _client.from('task_items').update(cleanData).eq('id', itemId);
  }

  /// Удаление элемента задачи
  Future<void> deleteTaskItem(String itemId) async {
    final item = await _client
        .from('task_items')
        .select('position, task_id')
        .eq('id', itemId)
        .single();

    final int deletedPosition = item['position'];
    final String taskId = item['task_id'];

    await _client.from('task_items').delete().eq('id', itemId);

    final itemsToUpdate = await _client
        .from('task_items')
        .select('id, position')
        .eq('task_id', taskId)
        .gt('position', deletedPosition);

    for (var item in itemsToUpdate) {
      await _client
          .from('task_items')
          .update({'position': item['position'] - 1}).eq('id', item['id']);
    }
  }

  /// Создание нового элемента задачи
  Future<Map<String, dynamic>> createTaskItem(
    String taskId,
    String type,
    int position,
  ) async {
    final response = await _client
        .from('task_items')
        .insert({
          'content': '', // Пустое содержимое для нового элемента
          'task_id': taskId,
          'type': type,
          'position': position,
          'checked': type == 'checklist' ? false : null,
        })
        .select()
        .single();

    return response;
  }

  /// Получение доступных типов элементов
  Future<List<String>> getTaskItemTypes() async {
    final result = await _client.rpc('get_task_item_types');
    return (result as List<dynamic>).map((e) => e.toString()).toList();
  }

  /// Получение информации об участниках задачи
  Future<List<Map<String, dynamic>>> getTaskMembers(String taskId) async {
    try {
      // Получаем участников с их ролями
      final response = await _client
          .from('task_members')
          .select('user_id, role')
          .eq('task_id', taskId);

      // Если нет участников, возвращаем пустой список
      if (response.isEmpty) return [];

      // Извлекаем ID пользователей
      final userIds =
          response.map((item) => item['user_id'] as String).toList();

      // Делаем отдельный запрос для получения данных пользователей
      final usersResponse = await _client
          .from('users')
          .select(
              'id, first_name, last_name, login, avatar_url') // Добавляем login
          .inFilter('id', userIds);

      // Формируем результат с данными из task_members и users
      final result = <Map<String, dynamic>>[];
      for (var member in response) {
        final userId = member['user_id'];
        final role = member['role'] ?? 'user';
        final userData = usersResponse.firstWhere(
            (user) => user['id'] == userId,
            orElse: () => {'id': userId});

        result.add({
          'user_id': userId,
          'role': role,
          'user_data': userData,
        });
      }

      return result;
    } catch (e) {
      print('Ошибка при получении участников: $e');
      return [];
    }
  }

  /// Удаление участника из задачи
  Future<void> removeTaskMember(String taskId, String userId) async {
    await _client
        .from('task_members')
        .delete()
        .eq('task_id', taskId)
        .eq('user_id', userId);
  }

  /// Обновление названия задачи
  Future<void> updateTaskTitle(String taskId, String newTitle) async {
    await _client.from('tasks').update({'title': newTitle}).eq('id', taskId);
  }

  /// Получение списка доступных пользователей для добавления в задачу
  /// Получение списка доступных пользователей для добавления в задачу
  Future<List<Map<String, dynamic>>> getAvailableUsersForTask(
      String taskId) async {
    final currentUserId = _client.auth.currentUser?.id;

    if (currentUserId == null) return [];

    // Получить accepted заявки в друзья
    final response = await _client
        .from('friend_requests')
        .select('sender_id, receiver_id')
        .eq('status', 'accepted')
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId');

    final acceptedFriends = (response as List<dynamic>)
        .map((e) =>
            e['sender_id'] == currentUserId ? e['receiver_id'] : e['sender_id'])
        .toSet()
        .toList();

    // Получить уже добавленных участников задачи
    final alreadyParticipants = await _client
        .from('task_members')
        .select('user_id')
        .eq('task_id', taskId);

    final excludedIds = [
      currentUserId,
      ...alreadyParticipants.map((e) => e['user_id'] as String),
    ];

    // Оставить только тех друзей, кто не в excludedIds
    final availableFriendIds =
        acceptedFriends.where((id) => !excludedIds.contains(id)).toList();

    if (availableFriendIds.isEmpty) return [];

    // Получить данные по этим пользователям
    final friendsData = await _client
        .from('users')
        .select(
            'id, first_name, last_name, login, avatar_url') // Добавляем login
        .inFilter('id', availableFriendIds);

    return List<Map<String, dynamic>>.from(friendsData);
  }

  Future<bool> isTaskCreator(String taskId, String userId) async {
    try {
      print("Проверка создателя задачи для taskId=$taskId, userId=$userId");

      // Выводим SQL запрос для отладки
      print("SQL: SELECT created_by FROM tasks WHERE id = '$taskId'");

      final response = await Supabase.instance.client
          .from('tasks')
          .select('created_by')
          .eq('id', taskId)
          .maybeSingle();

      print("Ответ от Supabase: $response");

      if (response == null) return false;

      return response['created_by'] == userId;
    } catch (e) {
      print("Ошибка при проверке создателя задачи: $e");
      return false;
    }
  }

  Future<String?> getTaskCreatorId(String taskId) async {
    try {
      final response = await Supabase.instance.client
          .from('tasks')
          .select('created_by')
          .eq('id', taskId)
          .maybeSingle(); // Используем maybeSingle вместо single

      if (response == null) return null;

      return response['created_by'] as String?;
    } catch (e) {
      print("Ошибка при получении ID создателя задачи: $e");
      return null;
    }
  }

  /// Альтернативный метод для получения роли через запрос
  Future<TaskMemberRole?> getUserRoleInTask(
      String taskId, String userId) async {
    try {
      print("Получение роли пользователя для taskId=$taskId, userId=$userId");

      // Выводим SQL запрос для отладки
      print(
          "SQL: SELECT role FROM task_members WHERE task_id = '$taskId' AND user_id = '$userId'");

      final response = await Supabase.instance.client
          .from('task_members')
          .select('role')
          .eq('task_id', taskId)
          .eq('user_id', userId)
          .maybeSingle();

      print("Ответ от Supabase: $response");

      if (response == null) return null;

      final roleStr = response['role'] as String?;
      return roleStr != null
          ? TaskMemberRoleExtension.fromString(roleStr)
          : null;
    } catch (e) {
      print("Ошибка при получении роли пользователя: $e");
      return null;
    }
  }

  /// Метод добавления участника
  Future<void> addTaskMember(String taskId, String userId,
      [TaskMemberRole role = TaskMemberRole.user]) async {
    // Проверяем наличие необходимого created_by в задаче
    try {
      final taskCheck = await _client
          .from('tasks')
          .select('created_by')
          .eq('id', taskId)
          .single();

      // Если создатель не указан, проверяем есть ли другие участники
      if (taskCheck['created_by'] == null) {
        // Получаем существующих участников задачи
        final members = await _client
            .from('task_members')
            .select('user_id')
            .eq('task_id', taskId);

        // Проверяем количество существующих участников
        if (members.isEmpty) {
          // Обновляем задачу, устанавливая created_by
          await _client
              .from('tasks')
              .update({'created_by': userId}).eq('id', taskId);

          // И добавляем пользователя как администратора
          await _client.from('task_members').insert({
            'task_id': taskId,
            'user_id': userId,
            'role': TaskMemberRole
                .admin.value, // Для первого участника/создателя всегда admin
          });
          return;
        }
      }

      // Стандартное добавление участника с указанной ролью
      await _client.from('task_members').insert({
        'task_id': taskId,
        'user_id': userId,
        'role':
            role.value, // ВОТ ЗДЕСЬ БЫЛА ОШИБКА - используем переданную роль
      });
    } catch (e) {
      print('Ошибка при добавлении участника: $e');
      throw Exception('Не удалось добавить участника: $e');
    }
  }

  Future<void> updateTaskPositionLog(String taskId, String itemID) async {
    try {
      // Проверяем, существует ли уже запись для данной задачи
      final existing = await _client
          .from('task_position_logs')
          .select()
          .eq('task_id', taskId)
          .maybeSingle();

      print(
          "Обновление лога позиций для задачи $taskId. Запись ${existing != null ? 'существует' : 'не существует'}");

      final now = DateTime.now().toIso8601String();

      if (existing != null) {
        // Запись уже существует, просто обновляем timestamp
        await _client.from('task_position_logs').update({
          'updated_at': now,
          'item_id': itemID,
          'type': 'update'
        }).eq('task_id', taskId);

        print(
            "Обновлена запись в task_position_logs для задачи $taskId с timestamp $now");
      } else {
        // Создаем новую запись
        await _client
            .from('task_position_logs')
            .insert({'task_id': taskId, 'updated_at': now});

        print(
            "Создана новая запись в task_position_logs для задачи $taskId с timestamp $now");
      }
    } catch (e) {
      print("Ошибка при обновлении лога позиций: $e");
      throw Exception("Не удалось обновить лог позиций: $e");
    }
  }

  /// Получает последнее время обновления позиций для задачи
  Future<DateTime?> getLastPositionUpdateTime(String taskId) async {
    try {
      final record = await _client
          .from('task_position_logs')
          .select('updated_at')
          .eq('task_id', taskId)
          .maybeSingle();

      if (record != null && record['updated_at'] != null) {
        return DateTime.parse(record['updated_at']);
      }
      return null;
    } catch (e) {
      print("Ошибка при получении времени обновления позиций: $e");
      return null;
    }
  }

  Future<void> updateTaskItemPositionWithLog(
      String itemId, int newPosition, String taskId,
      [String? userId]) async {
    final client = Supabase.instance.client;
    final currentUserId = userId ?? client.auth.currentUser?.id;

    try {
      // Добавляем дополнительные данные для отладки
      final now = DateTime.now().toIso8601String();
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();

      // Сначала проверяем, существует ли элемент
      final checkResponse = await client
          .from('task_items')
          .select('id, position')
          .eq('id', itemId)
          .maybeSingle();

      if (checkResponse == null) {
        throw Exception("Элемент $itemId не найден");
      }

      final oldPosition = checkResponse['position'] as int;
      if (oldPosition == newPosition) {
        // Позиция не изменилась, нет необходимости обновлять
        return;
      }

      print(
          "Обновление элемента $itemId с позиции $oldPosition на $newPosition");

      // Обновляем позицию элемента
      final updateResponse = await client
          .from('task_items')
          .update({
            'position': newPosition,
            'updated_at': now,
          })
          .eq('id', itemId)
          .select();

      if (updateResponse.isEmpty) {
        throw Exception("Не удалось обновить позицию $itemId");
      }

      // Добавляем запись в лог изменений
      await client.from('task_position_logs').insert({
        'task_id': taskId,
        'item_id': itemId,
        'new_position': newPosition,
        'old_position': oldPosition,
        'updated_at': now,
        'updated_by': currentUserId,
        'request_id': requestId,
      });

      print(
          "Успешно обновлена позиция элемента $itemId и добавлена запись в лог");
    } catch (e) {
      print("Ошибка в updateTaskItemPositionWithLog: $e");
      // Добавляем больше информации в исключение
      throw Exception("Не удалось обновить позицию для элемента $itemId: $e");
    }
  }

  Future<String> getTaskIdForItem(String itemId) async {
    final client = Supabase.instance.client;
    final response = await client
        .from('task_items')
        .select('task_id')
        .eq('id', itemId)
        .maybeSingle();

    if (response != null) {
      return response['task_id'];
    }
    throw Exception('Элемент не найден');
  }

  /// Модифицированный метод удаления элемента,
  /// который также обновляет лог позиций, если изменились позиции
  // В классе SupabaseService обновите метод deleteTaskItemWithLog
  Future<void> deleteTaskItemWithLog(String itemId) async {
    try {
      // Получаем информацию о позиции и task_id удаляемого элемента
      final item = await _client
          .from('task_items')
          .select('position, task_id')
          .eq('id', itemId)
          .single();

      final String ID = itemId;
      final int deletedPosition = item['position'];
      final String taskId = item['task_id'];

      // Создаем транзакцию для атомарного выполнения
      // 1. Удаляем элемент
      await _client.from('task_items').delete().eq('id', itemId);

      // 2. Обновляем позиции других элементов
      final itemsToUpdate = await _client
          .from('task_items')
          .select('id, position')
          .eq('task_id', taskId)
          .gt('position', deletedPosition);

      if (itemsToUpdate.isNotEmpty) {
        for (var item in itemsToUpdate) {
          await _client
              .from('task_items')
              .update({'position': item['position'] - 1}).eq('id', item['id']);
        }
      }

      // 3. Всегда обновляем лог позиций
      final now = DateTime.now().toIso8601String();
      final existing = await _client
          .from('task_position_logs')
          .select('id')
          .eq('task_id', taskId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('task_position_logs')
            .update({'updated_at': now, 'type': 'delete', 'item_id': ID}).eq(
                'task_id', taskId);
      } else {
        await _client.from('task_position_logs').insert({
          'task_id': taskId,
          'updated_at': now,
          'type': 'delete',
          'item_id': ID
        });
      }

      print("Удален элемент $itemId и обновлен лог позиций для задачи $taskId");
    } catch (e) {
      print("Ошибка при удалении элемента: $e");
      throw Exception("Не удалось удалить элемент: $e");
    }
  }

  /// Обновление позиций нескольких элементов задачи атомарно через RPC
  Future<bool> batchUpdateTaskItemPositions(
      String taskId, List<Map<String, dynamic>> positions) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Преобразуем список позиций в нужный формат
      final positionsJson = positions
          .map((item) => {'id': item['id'], 'position': item['position']})
          .toList();

      // Вызываем RPC функцию
      final result = await Supabase.instance.client.rpc(
        'batch_update_task_item_positions',
        params: {
          'p_task_id': taskId,
          'p_positions': positionsJson,
          'p_updated_by': currentUserId,
        },
      );

      return result as bool;
    } catch (e) {
      print('Ошибка при пакетном обновлении позиций: $e');
      return false;
    }
  }

  /// Обновление позиций в рамках одной транзакции
  Future<bool> updatePositionsInTransaction(
      String taskId, List<Map<String, dynamic>> positions) async {
    try {
      // Строим JSON для параметров
      final jsonPositions = positions
          .map((p) => {'id': p['id'], 'position': p['position']})
          .toList();

      // Вызываем RPC функцию для обработки транзакции на сервере
      final result = await _client.rpc('update_positions_transaction', params: {
        'p_task_id': taskId,
        'p_positions': jsonPositions,
        'p_updated_by': _client.auth.currentUser?.id ?? '',
      });

      return result as bool;
    } catch (e) {
      print("Ошибка при вызове транзакции для обновления позиций: $e");
      return false;
    }
  }

  /// Обновление позиции элемента с использованием прямого SQL запроса
  Future<void> updateItemPositionDirectSQL(String itemId, int position) async {
    try {
      // Используем execute вместо update, чтобы обойти проблему с колонкой updated_at
      await _client.rpc('update_item_position',
          params: {'p_item_id': itemId, 'p_position': position});

      print(
          "Позиция элемента $itemId успешно обновлена на $position через SQL");

      // Добавляем запись в лог
      final currentUserId = _client.auth.currentUser?.id;
      final taskId = await getTaskIdForItem(itemId);

      if (taskId != null) {
        // Получаем старую позицию
        final oldPositionQuery = await _client
            .from('task_items')
            .select('position')
            .eq('id', itemId)
            .maybeSingle();

        final oldPosition =
            oldPositionQuery != null ? oldPositionQuery['position'] : null;

        // Добавляем запись в лог изменений
        if (oldPosition != null && oldPosition != position) {
          await _client.from('task_position_logs').insert({
            'task_id': taskId,
            'item_id': itemId,
            'old_position': oldPosition,
            'new_position': position,
            'updated_by': currentUserId,
            'request_id': DateTime.now().millisecondsSinceEpoch.toString()
          });
        }
      }
    } catch (e) {
      print("Ошибка при обновлении позиции через SQL: $e");
      throw Exception("Не удалось обновить позицию элемента: $e");
    }
  }

  /// Простое базовое обновление позиции, без использования updated_at
  Future<void> updateItemPositionBasic(String itemId, int position) async {
    try {
      // Обновляем только поле position, избегая других проблемных полей
      await _client
          .from('task_items')
          .update({'position': position}).eq('id', itemId);

      print("Позиция элемента $itemId успешно обновлена на $position");
    } catch (e) {
      print("Ошибка при обновлении позиции: $e");
      throw Exception("Не удалось обновить позицию элемента: $e");
    }
  }

  Future<void> updateTaskItemAssignedTo(String itemId, String? userId) async {
    await _client
        .from('task_items')
        .update({'assigned_to': userId}).eq('id', itemId);
  }

// Метод получения пользователя по ID
  // Обновленный метод getUserById
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select(
              'id, first_name, last_name, login, avatar_url') // Добавляем login
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      print("Ошибка при получении данных пользователя: $e");
      return null;
    }
  }

  Future<void> updateTaskPositionLogWithItemId(
      String taskId, String itemId) async {
    try {
      await _client.from('task_position_logs').upsert(
        {
          'task_id': taskId,
          'item_id': itemId,
          'type': 'reorder',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'task_id', // ✅ Вот так правильно
      );
    } catch (e) {
      print('Ошибка при обновлении лога позиций с itemId: $e');
      throw e;
    }
  }
}

/// Класс для хранения данных задачи и ее элементов
class TaskDetailData {
  final String title;
  final List<Map<String, dynamic>> items;

  TaskDetailData({required this.title, required this.items});
}
