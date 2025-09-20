import 'dart:async';

import 'package:pointo/screens/main/friend_profile_page.dart';
import 'package:pointo/utils/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'services/supabase_service.dart';

import 'package:pointo/gen_l10n/app_localizations.dart';

import './widgets/task_items_reorderable_list.dart';

import './widgets/animation_manager.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with TickerProviderStateMixin {
  bool isLoading = true;
  String? errorMessage;
  String taskTitle = '';
  List<Map<String, dynamic>> items = [];
  bool _isProcessingSave = false;
  // ignore: unused_field
  late Animation<double> _dummyAnimation;
  RealtimeChannel? _positionLogChannel;
  bool _isUpdatingPositions = false;
  bool _isRefreshingFromLog = false;
  // ignore: unused_field
  DateTime? _lastPositionSync;
  Set<String> _processingDeleteIds =
      {}; // Для отслеживания элементов в процессе удаления

  // ignore: unused_field
  TaskMemberRole? _currentUserRole;
  bool _isCreator = false;
  bool _canEdit = false;
  bool _canManageMembers = false;

  DateTime? _lastAddItemTime;
  static const _addItemDebounceMs = 500;

  // ignore: unused_field
  bool _isEditing = false;

  String? _currentEditingItemId; // Отслеживаем текущий редактируемый элемент
  FocusNode _backgroundFocusNode =
      FocusNode(); // Фокус для фона (обнаружение нажатия вне элемента)

  // Переменные для управления редактированием элементов
  Map<String, bool> editingItems = {}; // Отслеживание редактируемых элементов
  Map<String, TextEditingController> itemControllers =
      {}; // Контроллеры для каждого элемента
  Map<String, FocusNode> itemFocusNodes = {}; // Фокусы для каждого элемента

  // Переменные для определения перетаскивания vs. долгого нажатия
  bool _longPressIsMove = false;
  // ignore: unused_field
  bool _showingDialog = false;

  // Переменные для анимаций
  final Map<String, AnimationController> _animationControllers = {};

  // Переменные для Supabase Realtime
  RealtimeChannel? _taskItemsChannel;
  RealtimeChannel? _taskChannel;
  RealtimeChannel? _taskMembersChannel;

  Map<String, Animation<double>> _scaleAnimations = {};
  Map<String, Animation<double>> _fadeAnimations = {};
  Map<String, Animation<Offset>> _slideAnimations = {};

  // Контроллер для скролла
  final ScrollController _scrollController = ScrollController();
  late AnimationController controller;

  // Сервис для работы с Supabase
  late SupabaseService _supabaseService;

  bool _ignoreRealtimeEvents = false;
  bool _isSavingItem = false;

  Timer? _longPressTimer;

  late TaskItemAnimationManager _animationManager;

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();

// Сначала загружаем данные
    fetchTaskDetailData().then((_) {
      // После загрузки данных настраиваем подписки
      _setupRealtimeSubscriptions();
      _setupPositionLogSubscription(); // Отдельный метод для подписки на логи позиций
    });

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _dummyAnimation = AlwaysStoppedAnimation(1.0);
    _checkUserPermissions();
    _animationManager = TaskItemAnimationManager();

    // Слушатель для фонового фокуса
    _backgroundFocusNode.addListener(_onBackgroundFocusChange);
  }

  @override
  void dispose() {
    // Освобождаем ресурсы при уничтожении виджета
    _taskItemsChannel?.unsubscribe();
    _taskChannel?.unsubscribe();
    _taskMembersChannel?.unsubscribe();
    _positionLogChannel?.unsubscribe();

    _backgroundFocusNode.removeListener(_onBackgroundFocusChange);
    _backgroundFocusNode.dispose();

    // Освобождаем контроллеры и фокусы
    for (var controller in itemControllers.values) {
      controller.dispose();
    }
    for (var focusNode in itemFocusNodes.values) {
      focusNode.dispose();
    }

    // Освобождаем анимационные контроллеры
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }

    _scaleAnimations.clear();
    _fadeAnimations.clear();
    _slideAnimations.clear();

    _animationManager.disposeAll();
    _longPressTimer?.cancel();
    _animationControllers.clear();
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  // Метод для проверки, равны ли записи, за исключением поля position
  bool _areRecordsEqualExceptPosition(
      Map<String, dynamic> oldRecord, Map<String, dynamic> newRecord) {
    // Создаем копии записей
    final oldCopy = Map<String, dynamic>.from(oldRecord);
    final newCopy = Map<String, dynamic>.from(newRecord);

    // Удаляем поле position и любые служебные поля, которые могут отличаться
    oldCopy.remove('position');
    newCopy.remove('position');
    oldCopy.remove('updated_at');
    newCopy.remove('updated_at');

    // Если изменился только assigned_to, отдельно обработаем это событие
    final oldAssignedTo = oldCopy['assigned_to'];
    final newAssignedTo = newCopy['assigned_to'];

    // Проверяем, изменился ли assigned_to
    bool assignedToChanged = oldAssignedTo != newAssignedTo;

    if (assignedToChanged) {
      // Удаляем assigned_to из копий для проверки остальных полей
      oldCopy.remove('assigned_to');
      newCopy.remove('assigned_to');
    }

    // Сравниваем оставшиеся поля
    for (final key in oldCopy.keys) {
      if (oldCopy[key] != newCopy[key]) {
        return false;
      }
    }

    if (assignedToChanged) {
      return false;
    }

    return true;
  }

  Future<void> _navigateToUserProfile(String userId) async {
    // Проверяем, что это не текущий пользователь
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == userId) {
      return;
    }

    // Сохраняем текущий элемент если редактируется
    if (_currentEditingItemId != null) {
      await saveItemContent(_currentEditingItemId!);
    }

    // Переходим к профилю пользователя
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: userId,
        ),
      ),
    );
  }

  // Обновите настройку подписки на task_position_logs
  void _setupPositionLogSubscription() {
    final client = Supabase.instance.client;
    // ignore: unused_local_variable
    final currentUserId = client.auth.currentUser?.id;

    _positionLogChannel =
        client.channel('position-logs-updates').onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'task_position_logs',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'task_id',
                value: widget.taskId,
              ),
              callback: (payload) async {
                print(
                    "Получено событие ${payload.eventType} для task_position_logs");

                // Игнорируем события, если мы сами их вызвали
                if (_isUpdatingPositions) {
                  print("Пропускаем обновление, т.к. сами обновляем позиции");
                  return;
                }

                if (_isRefreshingFromLog) {
                  print("Пропускаем обновление, т.к. уже обновляем из лога");
                  return;
                }

                // ПОЛУЧАЕМ ИНФОРМАЦИЮ О КОНКРЕТНОМ ПЕРЕМЕЩЕННОМ ЭЛЕМЕНТЕ
                final String operationType =
                    payload.newRecord['type'] as String? ?? 'update';
                final String affectedItemId =
                    payload.newRecord['item_id'] as String? ?? '';

                if (mounted) {
                  print(
                      "Запускаем обновление позиций с анимацией для операции $operationType элемента $affectedItemId");

                  // Добавляем небольшую задержку
                  if (mounted) {
                    // ПЕРЕДАЕМ ID КОНКРЕТНОГО ЭЛЕМЕНТА
                    _refreshTaskItemPositionsWithAnimation(
                      operationType: operationType,
                      affectedItemId: affectedItemId,
                    );
                  }
                }
              },
            );

    // Подписываемся на канал
    _positionLogChannel?.subscribe();
  }

  // Замените этот метод в task_detail_screen.dart
  // ИСПРАВЛЕННАЯ ВЕРСИЯ - замените метод в task_detail_screen.dart
  Future<void> _refreshTaskItemPositionsWithAnimation({
    String operationType = 'update',
    String affectedItemId = '',
  }) async {
    if (!mounted || _isRefreshingFromLog) return;

    print(
        "🔄 _refreshTaskItemPositionsWithAnimation начат: operationType=$operationType, affectedItemId=$affectedItemId");

    _isRefreshingFromLog = true;

    try {
      final response = await Supabase.instance.client
          .from('task_items')
          .select('*')
          .eq('task_id', widget.taskId)
          .order('position', ascending: true);

      final List<Map<String, dynamic>> serverItems =
          List<Map<String, dynamic>>.from(response);

      print("📡 Получено ${serverItems.length} элементов с сервера");

      final serverMap = {
        for (var item in serverItems) item['id']: item,
      };

      final serverIds = serverMap.keys.toSet();
      final localIds = items.map((e) => e['id'] as String).toSet();

      final addedIds = serverIds.difference(localIds);
      final removedIds = localIds.difference(serverIds);

      print("➕ Новые элементы: ${addedIds.length}");
      print("➖ Удаленные элементы: ${removedIds.length}");

      // Анимированное удаление исчезнувших элементов
      for (final id in removedIds) {
        final index = items.indexWhere((e) => e['id'] == id);
        if (index != -1) {
          print("🗑️ Помечаем элемент $id для удаления");
          setState(() {
            items[index]['isDisappearing'] = true;
          });

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                items.removeWhere((item) => item['id'] == id);
                itemControllers.remove(id);
                itemFocusNodes[id]?.dispose();
                itemFocusNodes.remove(id);
                editingItems.remove(id);
                _animationControllers[id]?.dispose();
                _animationControllers.remove(id);
              });
              print("🗑️ Элемент $id удален");
            }
          });
        }
      }

      // Анимированное добавление новых элементов
      for (final id in addedIds) {
        final newItem = serverMap[id];
        if (newItem != null && !items.any((e) => e['id'] == id)) {
          print("➕ Добавляем новый элемент $id");
          newItem['isAppearing'] = true;

          setState(() {
            items.add(newItem);
            itemControllers[id] =
                TextEditingController(text: newItem['content'] ?? '');
            itemFocusNodes[id] = FocusNode();
          });

          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              setState(() {
                final index = items.indexWhere((item) => item['id'] == id);
                if (index != -1) {
                  items[index].remove('isAppearing');
                }
              });
            }
          });
        }
      }

      // НОВАЯ ЛОГИКА: Ищем элемент с наибольшим изменением позиции
      String? movedItemId;
      int maxPositionChange = 0;

      print("🔍 Ищем элемент с наибольшим изменением позиции...");

      for (final serverItem in serverItems) {
        final id = serverItem['id'];
        final localItem =
            items.firstWhere((e) => e['id'] == id, orElse: () => {});

        if (localItem.isNotEmpty) {
          final oldPosition = localItem['position'] as int;
          final newPosition = serverItem['position'] as int;
          final positionChange = (oldPosition - newPosition).abs();

          print(
              "📍 Элемент $id: $oldPosition -> $newPosition (изменение: $positionChange)");

          if (positionChange > maxPositionChange) {
            maxPositionChange = positionChange;
            movedItemId = id;
          }
        }
      }

      // Если есть affectedItemId из параметров - используем его приоритетно
      if (affectedItemId.isNotEmpty && serverMap.containsKey(affectedItemId)) {
        final localItem = items.firstWhere((e) => e['id'] == affectedItemId,
            orElse: () => {});
        if (localItem.isNotEmpty) {
          final oldPos = localItem['position'] as int;
          final newPos = serverMap[affectedItemId]!['position'] as int;
          if (oldPos != newPos) {
            print("🎯 Используем указанный affectedItemId: $affectedItemId");
            movedItemId = affectedItemId;
            maxPositionChange = (oldPos - newPos).abs();
          }
        }
      }

      if (movedItemId != null && maxPositionChange > 0) {
        print(
            "🎬 АНИМИРУЕМ ТОЛЬКО ПЕРЕМЕЩЕННЫЙ ЭЛЕМЕНТ: $movedItemId (изменение позиции: $maxPositionChange)");

        // Устанавливаем флаг анимации только для перемещенного элемента
        setState(() {
          final index = items.indexWhere((item) => item['id'] == movedItemId);
          if (index != -1) {
            print(
                "🏁 Устанавливаем флаг isReordering=true для элемента $movedItemId");
            items[index]['isReordering'] = true;
          }
        });

        // Обновляем все позиции и пересортируем
        setState(() {
          for (final serverItem in serverItems) {
            final id = serverItem['id'];
            final localItem =
                items.firstWhere((e) => e['id'] == id, orElse: () => {});

            if (localItem.isNotEmpty) {
              localItem['position'] = serverItem['position'];

              if (localItem['assigned_to'] != serverItem['assigned_to']) {
                localItem['assigned_to'] = serverItem['assigned_to'];

                if (serverItem['assigned_to'] != null &&
                    !_usersCache.containsKey(serverItem['assigned_to'])) {
                  _getCachedUserById(serverItem['assigned_to']);
                }
              }
            }
          }

          items.sort(
              (a, b) => (a['position'] as int).compareTo(b['position'] as int));
          print("📊 Список пересортирован по позициям");
        });

        // Убираем флаг анимации через время
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            print("🏁 Убираем флаг reorder для $movedItemId");
            setState(() {
              final index =
                  items.indexWhere((item) => item['id'] == movedItemId);
              if (index != -1) {
                items[index].remove('isReordering');
                print("❌ Убран флаг isReordering для элемента $movedItemId");
              }
            });
          }
        });
      } else {
        print(
            "📊 Значительных изменений позиций не обнаружено, обновляем данные без анимации");
        // Обычное обновление без анимации
        setState(() {
          for (final serverItem in serverItems) {
            final id = serverItem['id'];
            final localItem =
                items.firstWhere((e) => e['id'] == id, orElse: () => {});

            if (localItem.isNotEmpty) {
              localItem['position'] = serverItem['position'];

              if (localItem['assigned_to'] != serverItem['assigned_to']) {
                localItem['assigned_to'] = serverItem['assigned_to'];

                if (serverItem['assigned_to'] != null &&
                    !_usersCache.containsKey(serverItem['assigned_to'])) {
                  _getCachedUserById(serverItem['assigned_to']);
                }
              }
            }
          }

          items.sort(
              (a, b) => (a['position'] as int).compareTo(b['position'] as int));
        });
      }
    } catch (e) {
      print("❌ Ошибка при обновлении: $e");
    } finally {
      _isRefreshingFromLog = false;
      print("✅ _refreshTaskItemPositionsWithAnimation завершен");
    }
  }

  // Обновление позиций элементов при изменении в таблице task_position_logs
  Future<void> _refreshTaskItemPositions() async {
    if (_isUpdatingPositions || !mounted || _isRefreshingFromLog) return;

    _isRefreshingFromLog = true;
    print("Начало обновления позиций элементов из task_position_logs");

    try {
      // Получаем полные данные о всех элементах
      final response = await Supabase.instance.client
          .from('task_items')
          .select('*')
          .eq('task_id', widget.taskId)
          .order('position', ascending: true);

      if (!mounted) {
        _isRefreshingFromLog = false;
        return;
      }

      // Преобразуем ответ в список Map<String, dynamic>
      final List<Map<String, dynamic>> serverItems =
          List<Map<String, dynamic>>.from(response);

      print("Получены данные о ${serverItems.length} элементах с сервера");

      // Находим актуальный список ID элементов
      final Set<String> serverItemIds =
          serverItems.map((item) => item['id'] as String).toSet();

      // Создаем список локальных ID для сравнения
      final Set<String> localItemIds =
          items.map((item) => item['id'] as String).toSet();

      // Находим элементы, которые нужно удалить (есть локально, но нет на сервере)
      final Set<String> itemsToRemove = localItemIds.difference(serverItemIds);

      if (itemsToRemove.isNotEmpty) {
        print("Найдено ${itemsToRemove.length} элементов для удаления");
      }

      // Обновляем состояние
      setState(() {
        // 1. Удаляем элементы, которых больше нет на сервере
        if (itemsToRemove.isNotEmpty) {
          items.removeWhere((item) => itemsToRemove.contains(item['id']));

          // Также удаляем ресурсы для удаленных элементов
          for (final itemId in itemsToRemove) {
            itemControllers.remove(itemId);
            itemFocusNodes.remove(itemId);
            _animationControllers.remove(itemId);
            editingItems.remove(itemId);
          }
        }

        // 2. Обновляем существующие элементы и добавляем новые
        for (final serverItem in serverItems) {
          final String itemId = serverItem['id'];
          final int index = items.indexWhere((item) => item['id'] == itemId);

          if (index != -1) {
            // Обновляем существующий элемент
            items[index] = serverItem;

            // Обновляем текст в контроллере, если он есть
            if (itemControllers.containsKey(itemId) &&
                !editingItems.containsKey(itemId)) {
              itemControllers[itemId]!.text = serverItem['content'] ?? '';
            }
          } else {
            // Добавляем новый элемент
            items.add(serverItem);

            // Создаем ресурсы для нового элемента
            itemControllers[itemId] =
                TextEditingController(text: serverItem['content'] ?? '');
            itemFocusNodes[itemId] = FocusNode();
            _animationControllers[itemId] = AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 100),
            );
            _animationControllers[itemId]!.value = 1.0;
          }
        }

        // 3. Сортируем список по позиции
        items.sort(
            (a, b) => (a['position'] as int).compareTo(b['position'] as int));

        // 4. Обновляем время синхронизации
        _lastPositionSync = DateTime.now();
      });

      print("Обновление позиций завершено успешно");
    } catch (e) {
      print("Ошибка при обновлении позиций: $e");
    } finally {
      _isRefreshingFromLog = false;
    }
  }

  // Обновленный метод для отключения Realtime подписок
  Future<void> _disconnectRealtimeExtended() async {
    // Отключаем канал task_items
    await _taskItemsChannel?.unsubscribe();
    _taskItemsChannel = null;

    // Отключаем канал task_position_logs
    await _positionLogChannel?.unsubscribe();
    _positionLogChannel = null;
  }

  // Обновленный метод для восстановления Realtime подписок
  void _reconnectRealtimeWithDelayExtended() {
    Future.delayed(Duration(milliseconds: 20), () {
      if (mounted) {
        if (_taskItemsChannel == null || _positionLogChannel == null) {
          _setupRealtimeSubscriptions();
        }
      }
    });
  }

  // Обновленный метод для обновления позиций после перетаскивания
  Future<void> _updatePositionsExtended(String itemID) async {
    if (_isUpdatingPositions) return;

    // Сохраняем текущие позиции для отката в случае ошибки
    final List<Map<String, dynamic>> originalItems = items
        .map((item) => {'id': item['id'], 'position': item['position']})
        .toList();

    _isUpdatingPositions = true;

    // Временно отключаем подписку
    await _positionLogChannel?.unsubscribe();
    _positionLogChannel = null;

    // Блокировка полной перерисовки UI при массовом обновлении
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Применяем новые позиции оптимистично
          for (int i = 0; i < items.length; i++) {
            if (items[i]['position'] != i) {
              items[i]['position'] = i;
            }
          }

          // Сортируем список по новым позициям
          items.sort(
              (a, b) => (a['position'] as int).compareTo(b['position'] as int));
        });
      }
    });

    try {
      // Фильтруем и подготавливаем только валидные элементы
      final List<Map<String, dynamic>> updatedPositions = [];

      for (int i = 0; i < items.length; i++) {
        final item = items[i];

        // Проверяем валидность ID элемента
        if (item['id'] == null ||
            !(item['id'] is String) ||
            (item['id'] as String).isEmpty ||
            (item['id'] as String).startsWith('temp_')) {
          // Пропускаем временные элементы и элементы с невалидными ID
          continue;
        }

        // Находим оригинальную позицию
        final originalItemIndex =
            originalItems.indexWhere((e) => e['id'] == item['id']);
        if (originalItemIndex == -1) continue; // Пропускаем новые элементы

        final oldPosition = originalItems[originalItemIndex]['position'] as int;

        // Проверяем, изменилась ли позиция
        if (oldPosition != i) {
          updatedPositions.add({'id': item['id'], 'position': i});
        }
      }

      if (updatedPositions.isEmpty) {
        print("Нет позиций для обновления");
        return;
      }

      print("Обновление ${updatedPositions.length} позиций...");

      // Обрабатываем каждый элемент отдельно
      bool anyFailure = false;

      for (final update in updatedPositions) {
        try {
          // Используем прямой SQL запрос вместо метода с проблемной колонкой
          await _supabaseService.updateItemPositionBasic(
              update['id'], update['position']);

          // Небольшая задержка между запросами для предотвращения конфликтов
          await Future.delayed(Duration(milliseconds: 2));
        } catch (e) {
          print("Ошибка для элемента ${update['id']}: $e");
          anyFailure = true;
        }
      }

      // Только после всех операций обновляем лог позиций
      try {
        // ВАЖНО: Передаем конкретный ID перемещенного элемента
        await _supabaseService.updateTaskPositionLogWithItemId(
            widget.taskId, itemID);

        if (anyFailure) {
          // Если были ошибки, перезагружаем свои данные чтобы синхронизироваться
          await fetchTaskDetailData();
        }
      } catch (e) {
        print("Не удалось обновить общий лог позиций: $e");
      }
    } catch (e) {
      print("Критическая ошибка при обновлении позиций: $e");

      // Не показываем Toast с ошибкой для рядовых проблем с обновлением
      if (mounted) {
        // Откатываем локальное состояние к исходным позициям
        setState(() {
          for (final item in originalItems) {
            final index = items.indexWhere((e) => e['id'] == item['id']);
            if (index != -1) {
              items[index]['position'] = item['position'];
            }
          }

          // Сортируем список по восстановленным позициям
          items.sort(
              (a, b) => (a['position'] as int).compareTo(b['position'] as int));
        });
      }
    } finally {
      _isUpdatingPositions = false;

      // Восстанавливаем подписку на изменения позиций с небольшой задержкой
      if (mounted && _positionLogChannel == null) {
        Future.delayed(Duration(milliseconds: 20), () {
          _setupPositionLogSubscription();
        });
      }
    }
  }

  // Обновленный метод для удаления элемента с учетом обновления позиций
  Future<void> deleteTaskItemExtended(String itemId) async {
    try {
      // Отключаем подписки перед операцией удаления
      await _disconnectRealtimeExtended();

      // Удаляем элемент с логированием позиций
      await _supabaseService.deleteTaskItemWithLog(itemId);

      // Обновляем время последней синхронизации
      _lastPositionSync = DateTime.now();

      // Вызываем обратно подписки
      _reconnectRealtimeWithDelayExtended();
    } catch (e) {
      print("Ошибка при удалении элемента: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.deleteError(e.toString()),
            ),
          ),
        );
      }

      // Восстанавливаем подписки в случае ошибки
      _reconnectRealtimeWithDelayExtended();
    }
  }

  Future<void> _checkUserPermissions() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // Получаем базовую информацию о задаче
      final taskInfo = await _supabaseService.getTaskBasicInfo(widget.taskId);

      // Если задача существует
      if (taskInfo != null) {
        // Проверяем, является ли пользователь создателем
        _isCreator = taskInfo['created_by'] == currentUserId;

        // Получаем роль пользователя (может быть null)
        _currentUserRole = await _supabaseService.getUserRoleInTask(
            widget.taskId, currentUserId);

        // По умолчанию - базовые права
        _canEdit = _isCreator;
        _canManageMembers = _isCreator;

        // Если роль определена, обновляем права в соответствии с ней
        if (_currentUserRole != null) {
          switch (_currentUserRole) {
            case TaskMemberRole.admin:
              _canEdit = true;
              _canManageMembers = true;
              break;
            case TaskMemberRole.editor:
              _canEdit = true;
              _canManageMembers = false;
              break;
            case TaskMemberRole.user:
              _canEdit = false;
              _canManageMembers = false;
              break;
            default:
              break;
          }
        }

        // Для нового сценария: если создатель не задан, но пользователь открыл задачу
        if (taskInfo['created_by'] == null) {
          print(
              "Задача не имеет указанного создателя. Предоставляем базовые права для открывшего пользователя.");
          // Вариант 1: Предоставить права создателя первому пользователю, открывшему задачу
          _isCreator = true;
          _canEdit = true;
          _canManageMembers = true;

          // Опционально: установить пользователя как создателя
          await _supabaseService.setTaskCreator(widget.taskId, currentUserId);
        }

        if (mounted) {
          setState(() {}); // Обновляем UI с новыми правами
        }
      } else {
        print("Задача с ID ${widget.taskId} не найдена!");
      }
    } catch (e) {
      print("Ошибка при проверке прав пользователя: $e");
    }
  }

  // Сохранение отредактированного контента временного элемента
  Future<void> _createPermanentItem(
      String tempId, String content, int position) async {
    if (!mounted) return;

    try {
      setState(() {
        // Показываем индикатор загрузки
        final index = items.indexWhere((item) => item['id'] == tempId);
        if (index != -1) {
          items[index]['isSaving'] = true;
        }
      });

      // КЛЮЧЕВАЯ ПРОБЛЕМА:
      // 1. Вызываем _disconnectRealtime() что отключает подписки
      // 2. Затем вызываем _reconnectRealtimeWithDelay() что пересоздает подписки

      // Устанавливаем флаг для игнорирования событий realtime во время нашей операции
      _ignoreRealtimeEvents = true;

      try {
        // Создаем элемент в базе данных с содержимым напрямую В ОДИН ЗАПРОС
        final response = await Supabase.instance.client
            .from('task_items')
            .insert({
              'content': content, // Уже включаем контент
              'task_id': widget.taskId,
              'type': 'note',
              'position': position,
              'checked': null,
            })
            .select()
            .single();

        final newItem = response;
        print(
            "Создан элемент с ID: ${newItem['id']} и контентом: ${newItem['content']}");

        if (mounted) {
          // Сохраняем ссылки на ресурсы, которые нужно очистить
          final nodeToDispose = itemFocusNodes[tempId];
          final controllerToDispose = _animationControllers[tempId];
          final textControllerToDispose = itemControllers[tempId];

          setState(() {
            // Удаляем временный элемент
            items.removeWhere((item) => item['id'] == tempId);

            // Добавляем настоящий элемент сразу с правильным контентом
            items.add(newItem);
            items.sort((a, b) =>
                (a['position'] as int).compareTo(b['position'] as int));

            // Создаем контроллер и фокус для нового элемента
            itemControllers[newItem['id']] =
                TextEditingController(text: newItem['content']);
            itemFocusNodes[newItem['id']] = FocusNode();
            _animationControllers[newItem['id']] = AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 100),
            );
            _animationControllers[newItem['id']]!.value = 1.0;

            // Очищаем ресурсы для временного элемента из коллекций
            itemControllers.remove(tempId);
            itemFocusNodes.remove(tempId);
            _animationControllers.remove(tempId);

            if (_currentEditingItemId == tempId) {
              _currentEditingItemId = null;
              _isEditing = false;
            }
          });

          // Теперь безопасно вызываем dispose() для ресурсов после изменения состояния
          Future.microtask(() {
            nodeToDispose?.dispose();
            controllerToDispose?.dispose();
            textControllerToDispose?.dispose();
          });
        }
      } finally {
        // В любом случае снимаем флаг блокировки событий
        _ignoreRealtimeEvents = false;
      }
    } catch (e) {
      print("Ошибка при сохранении элемента: $e");

      if (mounted) {
        setState(() {
          // Находим и удаляем индикатор загрузки на случай ошибки
          final index = items.indexWhere((item) => item['id'] == tempId);
          if (index != -1) {
            items[index]['isSaving'] = false;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.saveError(e.toString()),
            ),
          ),
        );
      }

      // Снимаем флаг даже при ошибке
      _ignoreRealtimeEvents = false;
    }
  }

  // Настройка подписок Supabase Realtime
  void _setupRealtimeSubscriptions() {
    final client = Supabase.instance.client;

    // Добавляем подписку на изменения участников задачи
    _taskMembersChannel = client
        .channel('task-members-updates')
        // Подписка на обновления участников (роли)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'task_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'task_id',
            value: widget.taskId,
          ),
          callback: (payload) {
            if (payload.newRecord != null) {
              final updatedMember =
                  Map<String, dynamic>.from(payload.newRecord);
              final String userId = updatedMember['user_id'];
              final String role = updatedMember['role'] ?? 'user';

              // Проверяем, касается ли это текущего пользователя
              final currentUserId =
                  Supabase.instance.client.auth.currentUser?.id;
              if (userId == currentUserId) {
                TaskMemberRole newRole =
                    TaskMemberRoleExtension.fromString(role);

                setState(() {
                  _currentUserRole = newRole;

                  // Обновляем права в соответствии с ролью
                  switch (newRole) {
                    case TaskMemberRole.admin:
                      _canEdit = true;
                      _canManageMembers = true;
                      break;
                    case TaskMemberRole.editor:
                      _canEdit = true;
                      _canManageMembers = false;
                      break;
                    case TaskMemberRole.user:
                      _canEdit = false;
                      _canManageMembers = false;
                      break;
                    default:
                      break;
                  }
                });

                // Показываем уведомление о смене роли
                Future.microtask(() {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .roleChanged(_getRoleDisplayName(role)),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                });
              }
            }
          },
        );

    // Подписка на удаление участников
    _taskMembersChannel?.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'task_members',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'task_id',
        value: widget.taskId,
      ),
      callback: (payload) {
        final deletedMember = payload.oldRecord;
        final String userId = deletedMember['user_id'];

        // Если текущий пользователь удален из задачи
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == currentUserId) {
          // Показываем уведомление и выходим из задачи
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.removedFromTask),
                duration: const Duration(seconds: 3),
              ),
            );

            // Немного задержки перед возвратом
            Future.delayed(Duration(seconds: 1), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        }
      },
    );

    // 2. Модифицированная подписка на INSERT событий в task_items
    _taskItemsChannel = client.channel('task-items-updates').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'task_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'task_id',
            value: widget.taskId,
          ),
          callback: (payload) {
            if (_ignoreRealtimeEvents) {
              print("Игнорируем Realtime событие INSERT");
              return;
            }

            if (payload.newRecord != null) {
              final newItem = Map<String, dynamic>.from(payload.newRecord);
              final String itemId = newItem['id'];

              // Проверяем, существует ли уже элемент с таким ID
              final existingIndex =
                  items.indexWhere((item) => item['id'] == itemId);
              if (existingIndex != -1) {
                print(
                    "Элемент с ID $itemId уже существует, пропускаем добавление");
                return;
              }

              // Создаем анимационный контроллер для нового элемента
              final animController = AnimationController(
                vsync: this,
                duration: const Duration(milliseconds: 400),
              );

              setState(() {
                // Добавляем флаг появления ПЕРЕД добавлением в список
                newItem['isAppearing'] = true;

                items.add(newItem);
                items.sort((a, b) =>
                    (a['position'] as int).compareTo(b['position'] as int));

                // Создаем контроллеры для редактирования
                if (!itemControllers.containsKey(itemId)) {
                  itemControllers[itemId] =
                      TextEditingController(text: newItem['content']);
                  itemFocusNodes[itemId] = FocusNode();
                }

                _animationControllers[itemId] = animController;
              });

              // Запускаем анимацию появления
              animController.forward();

              // Убираем флаг появления через время анимации
              Future.delayed(Duration(milliseconds: 400), () {
                if (mounted) {
                  setState(() {
                    final index =
                        items.indexWhere((item) => item['id'] == itemId);
                    if (index != -1) {
                      items[index].remove('isAppearing');
                    }
                  });
                }
              });

              // Открываем для редактирования только если это новый пустой элемент
              if (newItem['content'] == '' && items.length == 1) {
                Future.delayed(Duration(milliseconds: 400), () {
                  if (mounted) {
                    toggleEditing(itemId, '');
                    _scrollToItem(items.length - 1);
                  }
                });
              }
            }
          },
        );

    // Подписка на DELETE для task_items с правильными анимациями
    _taskItemsChannel?.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'task_items',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'task_id',
        value: widget.taskId,
      ),
      callback: (payload) {
        final deletedId = payload.oldRecord['id'];

        // Проверяем, не в процессе ли уже удаления этот элемент
        if (_processingDeleteIds.contains(deletedId)) {
          _processingDeleteIds.remove(deletedId);
          return;
        }

        // Важно: Триггер для обновления лога позиций
        _refreshTaskItemPositions();

        // Устанавливаем флаг исчезновения
        setState(() {
          final index = items.indexWhere((item) => item['id'] == deletedId);
          if (index != -1) {
            items[index]['isDisappearing'] = true;
          }
        });

        // Если у нас есть анимационный контроллер, анимируем удаление
        if (_animationControllers.containsKey(deletedId)) {
          // ignore: unused_local_variable
          final controller = _animationControllers[deletedId]!;

          // Создаем анимацию исчезновения
          final removeController = AnimationController(
            duration: const Duration(milliseconds: 350),
            vsync: this,
          );

          // Обновляем анимации для удаления
          final removeScale = Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                  parent: removeController, curve: Curves.easeInBack));

          final removeFade = Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(parent: removeController, curve: Curves.easeOut));

          final removeSlide =
              Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0))
                  .animate(CurvedAnimation(
                      parent: removeController, curve: Curves.easeInCubic));

          // Заменяем анимации контроллера
          _scaleAnimations[deletedId] = removeScale;
          _fadeAnimations[deletedId] = removeFade;
          _slideAnimations[deletedId] = removeSlide;

          // Запускаем анимацию удаления
          removeController.forward().then((_) {
            removeController.dispose();

            if (mounted) {
              setState(() {
                items.removeWhere((item) => item['id'] == deletedId);
                // Очищаем ресурсы
                itemControllers.remove(deletedId);
                itemFocusNodes.remove(deletedId);
                _animationControllers.remove(deletedId);
                editingItems.remove(deletedId);
              });
            }
          });
        } else {
          // Если нет контроллера, удаляем элемент с анимированной задержкой
          Future.delayed(Duration(milliseconds: 350), () {
            if (mounted) {
              setState(() {
                items.removeWhere((item) => item['id'] == deletedId);
                itemControllers.remove(deletedId);
                itemFocusNodes.remove(deletedId);
                editingItems.remove(deletedId);
              });
            }
          });
        }
      },
    );

    // 3. Подписка на UPDATE событий в task_items с правильными анимациями
    _taskItemsChannel?.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'task_items',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'task_id',
        value: widget.taskId,
      ),
      callback: (payload) {
        if (_ignoreRealtimeEvents) {
          print("Игнорируем Realtime событие UPDATE");
          return;
        }

        if (payload.newRecord != null && payload.oldRecord != null) {
          final itemId = payload.newRecord['id'];

          // Получаем старое и новое значение position
          final oldPosition = payload.oldRecord['position'] as int;
          final newPosition = payload.newRecord['position'] as int;

          // Получаем старое и новое значение assigned_to
          final oldAssignedTo = payload.oldRecord['assigned_to'];
          final newAssignedTo = payload.newRecord['assigned_to'];

          // Проверяем, изменился ли assigned_to
          final hasAssignedToChanged = oldAssignedTo != newAssignedTo;

          // Если изменилась только позиция, игнорируем это событие
          if (oldPosition != newPosition &&
              !hasAssignedToChanged &&
              _areRecordsEqualExceptPosition(
                  payload.oldRecord, payload.newRecord)) {
            print("Игнорируем обновление позиции элемента");
            return;
          }

          // Получаем текущие значения
          final currentIndex = items.indexWhere((item) => item['id'] == itemId);

          if (currentIndex == -1) {
            print("Элемент с ID $itemId не найден в списке");
            return;
          }

          final currentItem = items[currentIndex];
          final newItem = Map<String, dynamic>.from(payload.newRecord);

          // Если редактируем элемент, обновляем только некоторые поля
          if (editingItems[itemId] == true) {
            setState(() {
              if (currentItem['checked'] != newItem['checked']) {
                items[currentIndex]['checked'] = newItem['checked'];
              }
              if (currentItem['deadline'] != newItem['deadline']) {
                items[currentIndex]['deadline'] = newItem['deadline'];
              }
              if (currentItem['type'] != newItem['type']) {
                items[currentIndex]['type'] = newItem['type'];
              }
              if (hasAssignedToChanged) {
                items[currentIndex]['assigned_to'] = newItem['assigned_to'];

                if (newItem['assigned_to'] != null &&
                    !_usersCache.containsKey(newItem['assigned_to'])) {
                  _getCachedUserById(newItem['assigned_to']);
                }
              }
            });
            return;
          }

          // Проверяем изменения
          final hasContentChanged =
              currentItem['content'] != newItem['content'];
          final hasDeadlineChanged =
              currentItem['deadline'] != newItem['deadline'];
          final hasCheckedChanged =
              currentItem['checked'] != newItem['checked'];
          final hasTypeChanged = currentItem['type'] != newItem['type'];

          // Обрабатываем обновления, не связанные с позицией
          if (hasContentChanged ||
              hasDeadlineChanged ||
              hasCheckedChanged ||
              hasTypeChanged ||
              hasAssignedToChanged) {
            setState(() {
              // Сохраняем position из текущего элемента
              final currentPosition = currentItem['position'];

              // Добавляем флаг обновления для анимации
              newItem['isUpdating'] = true;

              // Обновляем элемент, сохраняя текущую позицию
              items[currentIndex] = newItem;
              items[currentIndex]['position'] = currentPosition;

              // Обновляем контроллер текста
              if (itemControllers.containsKey(itemId) &&
                  !(editingItems[itemId] ?? false)) {
                itemControllers[itemId]!.text = newItem['content'] ?? '';
              }

              // Если изменился assigned_to, загружаем данные нового пользователя
              if (hasAssignedToChanged &&
                  newItem['assigned_to'] != null &&
                  !_usersCache.containsKey(newItem['assigned_to'])) {
                _getCachedUserById(newItem['assigned_to']).then((userData) {
                  if (userData != null && mounted) {
                    setState(() {
                      // Обновление будет автоматически через кеш
                    });
                  }
                });
              }
            });

            // Убираем флаг обновления через время анимации
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  final index =
                      items.indexWhere((item) => item['id'] == itemId);
                  if (index != -1) {
                    items[index].remove('isUpdating');
                  }
                });
              }
            });

            // Создаем контроллер анимации если его нет
            if (!_animationControllers.containsKey(itemId)) {
              _animationControllers[itemId] = AnimationController(
                vsync: this,
                duration: const Duration(milliseconds: 300),
              );
              _animationControllers[itemId]!.value = 1.0;
            }

            // Запускаем анимацию изменения (пульсация)
            final controller = _animationControllers[itemId]!;
            controller.reset();
            controller.forward().then((_) {
              if (mounted) {
                controller.reverse().then((_) {
                  if (mounted) {
                    controller.forward();
                  }
                });
              }
            });
          }
        }
      },
    );

    // Остальные подписки остаются без изменений...
    _taskChannel = client.channel('task-updates').onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.taskId,
          ),
          callback: (payload) {
            if (payload.newRecord != null) {
              final updatedTask = Map<String, dynamic>.from(payload.newRecord);

              if (updatedTask['title'] != null &&
                  updatedTask['title'] != taskTitle) {
                setState(() {
                  taskTitle = updatedTask['title'];
                });
              }
            }
          },
        );

    // Запускаем все подписки
    _taskChannel?.subscribe();
    _taskItemsChannel?.subscribe();
    _taskMembersChannel?.subscribe();
    _positionLogChannel?.subscribe();
  }

  // Скролл к определенному элементу списка
  // Улучшенный метод скролла к элементу
  void _scrollToItem(int index) {
    if (index < 0 || index >= items.length) return;

    // Если ScrollController еще не присоединен, отложим скролл
    if (!_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 50), () => _scrollToItem(index));
      return;
    }

    // Вычисляем предполагаемую высоту элемента с учетом типа
    double estimatedHeight = 80.0;
    if (items[index]['type'] == 'header') {
      estimatedHeight = 100.0;
    } else if (items[index]['deadline'] != null) {
      estimatedHeight = 90.0;
    }

    // Рассчитываем приблизительную позицию элемента
    double estimatedOffset = 0.0;
    for (int i = 0; i < index; i++) {
      double itemHeight = 80.0;
      if (items[i]['type'] == 'header') {
        itemHeight = 100.0;
      } else if (items[i]['deadline'] != null) {
        itemHeight = 90.0;
      }
      estimatedOffset += itemHeight;
    }

    // Получаем размеры экрана и клавиатуры
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight =
        screenHeight - keyboardHeight - 200; // Увеличиваем запас

    // Для нового элемента скроллим так, чтобы он был в нижней части экрана
    // Это даст место для клавиатуры
    double targetOffset =
        estimatedOffset - availableHeight + estimatedHeight + 100;

    // Проверяем границы
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    targetOffset = targetOffset.clamp(0.0, maxScrollExtent);

    // Анимированный скролл с более плавными параметрами
    _scrollController.animateTo(
      targetOffset,
      duration: Duration(milliseconds: 300), // Увеличили время для плавности
      curve: Curves.easeOutCubic, // Более плавная кривая
    );
  }

  void _onBackgroundFocusChange() {
    // Если фоновый фокус получен, а текущий элемент находится в режиме редактирования,
    // значит пользователь нажал вне элемента - сохраняем текущий элемент
    if (_backgroundFocusNode.hasFocus &&
        _currentEditingItemId != null &&
        !_isSavingItem &&
        !_isProcessingSave) {
      _isProcessingSave = true;
      saveItemContent(_currentEditingItemId!).then((_) {
        _isProcessingSave = false;
        if (_currentEditingItemId == null && mounted) {
          setState(() {
            _isEditing = false;
          });
        }
      });
    }
  }

  // Переключение режима редактирования для конкретного элемента
  void toggleEditing(String itemId, String content) {
    // Если контроллер для элемента еще не создан, создаем его
    if (!itemControllers.containsKey(itemId)) {
      itemControllers[itemId] = TextEditingController(text: content);
    }

    // Если фокус для элемента еще не создан, создаем его
    if (!itemFocusNodes.containsKey(itemId)) {
      itemFocusNodes[itemId] = FocusNode();

      // Добавляем слушатель события потери фокуса
      itemFocusNodes[itemId]!.addListener(() {
        // Когда поле получает фокус, устанавливаем _isEditing в true
        if (itemFocusNodes[itemId]!.hasFocus) {
          setState(() {
            _isEditing = true;
          });
        } else if (!itemFocusNodes[itemId]!.hasFocus &&
            editingItems[itemId] == true) {
          // Когда поле теряет фокус, можно сбросить _isEditing и сохранить контент
          setState(() {
            _isEditing = false;
          });
          saveItemContent(itemId);
        }
      });
    }

    // Если уже есть активный редактор для другого элемента,
    // просто сохраняем его и не открываем новый
    if (_currentEditingItemId != null && _currentEditingItemId != itemId) {
      saveItemContent(_currentEditingItemId!);
      return; // Важно! Выходим из метода, не открывая новый редактор
    }

    setState(() {
      // Переключаем режим редактирования для выбранного элемента
      final wasEditing = editingItems[itemId] ?? false;

      if (wasEditing) {
        // Если редактор был открыт, закрываем его
        editingItems[itemId] = false;
        _currentEditingItemId = null;
        _isEditing = false; // Сбрасываем флаг редактирования
      } else {
        // Открываем редактор, если никакой другой элемент не редактируется
        editingItems[itemId] = true;
        _currentEditingItemId = itemId;
        _isEditing = true; // Устанавливаем флаг редактирования
      }
    });

    // Если включен режим редактирования, устанавливаем фокус
    if (editingItems[itemId] == true) {
      // Находим индекс элемента для скролла
      final index = items.indexWhere((item) => item['id'] == itemId);
      if (index != -1) {
        // Делаем скролл к элементу
        _scrollToItem(index);
      }

      // Задержка нужна для правильной инициализации TextField
      Future.delayed(Duration(milliseconds: 20), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(itemFocusNodes[itemId]);
        }
      });
    }
  }

  // Сохранение отредактированного контента
  Future<void> saveItemContent(String itemId) async {
    // Если уже идет сохранение этого элемента, выходим
    if (_isSavingItem) return;
    _isSavingItem = true;

    if (!itemControllers.containsKey(itemId)) {
      _isSavingItem = false;
      return;
    }

    final newContent = itemControllers[itemId]!.text.trim();

    // Проверяем, изменился ли контент
    final index = items.indexWhere((item) => item['id'] == itemId);
    if (index == -1) {
      _isSavingItem = false;
      return;
    }

    final isTemporary = items[index]['isTemporary'] == true;

    // Сбрасываем состояние редактирования
    setState(() {
      editingItems[itemId] = false;
      if (_currentEditingItemId == itemId) {
        _currentEditingItemId = null;
      }
      _isEditing = false;
    });

    // Если это временный элемент
    if (isTemporary) {
      if (newContent.isEmpty) {
        // Если контент пустой, анимированно удаляем временный элемент
        setState(() {
          items[index]['isDisappearing'] = true;
        });

        // Показываем сообщение
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.emptyNoteDeleted),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        // Создаем анимацию удаления
        if (!_animationControllers.containsKey(itemId)) {
          _animationControllers[itemId] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 350),
          );
          _animationControllers[itemId]!.value = 1.0;
        }

        final controller = _animationControllers[itemId]!;
        controller.reverse().then((_) {
          if (mounted) {
            // Сохраняем ссылки на объекты для disposal
            final nodeToDispose = itemFocusNodes[itemId];
            final controllerToDispose = _animationControllers[itemId];

            setState(() {
              items.removeWhere((item) => item['id'] == itemId);
              itemControllers.remove(itemId);
              itemFocusNodes.remove(itemId);
              _animationControllers.remove(itemId);
            });

            // Безопасно вызываем dispose после setState
            Future.microtask(() {
              nodeToDispose?.dispose();
              controllerToDispose?.dispose();
            });
          }
        });

        _isSavingItem = false;
      } else {
        // Если контент не пустой, сохраняем временный элемент в базу
        int position = items[index]['position'] as int;
        try {
          await _createPermanentItem(itemId, newContent, position);
        } finally {
          _isSavingItem = false;
        }
      }
      return;
    }

    // Для существующих элементов из базы данных:
    // Если содержимое пустое, анимированно удаляем элемент
    if (newContent.isEmpty) {
      // Показываем сообщение
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.emptyNoteDeleted),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Устанавливаем флаг исчезновения
      setState(() {
        items[index]['isDisappearing'] = true;
      });

      // Создаем анимацию удаления если её нет
      if (!_animationControllers.containsKey(itemId)) {
        _animationControllers[itemId] = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350),
        );
        _animationControllers[itemId]!.value = 1.0;
      }

      final controller = _animationControllers[itemId]!;
      controller.reverse().then((_) async {
        if (mounted) {
          // Удаляем элемент из базы данных
          await _supabaseService.deleteTaskItemWithLog(itemId);

          // Сохраняем ссылки на объекты для disposal
          final nodeToDispose = itemFocusNodes[itemId];
          final controllerToDispose = _animationControllers[itemId];

          // Удаляем элемент локально
          setState(() {
            items.removeWhere((item) => item['id'] == itemId);
            itemControllers.remove(itemId);
            itemFocusNodes.remove(itemId);
            _animationControllers.remove(itemId);
            editingItems.remove(itemId);
          });

          // Безопасно вызываем dispose после setState
          Future.microtask(() {
            nodeToDispose?.dispose();
            controllerToDispose?.dispose();
          });
        }
      });

      _isSavingItem = false;
      return;
    }

    // Остальная часть метода остается без изменений...
    final currentContent = items[index]['content'];

    if (newContent == currentContent) {
      _isSavingItem = false;
      return;
    }

    setState(() {
      items[index]['isSaving'] = true;
    });

    try {
      await _supabaseService.updateTaskItemContent(itemId, newContent);

      if (mounted) {
        setState(() {
          items[index]['isSaving'] = false;
          items[index]['content'] = newContent;
        });
      }
    } catch (e) {
      print("Error saving content: $e");
      if (mounted) {
        setState(() {
          items[index]['isSaving'] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.saveError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      _isSavingItem = false;
    }
  }

  Future<void> addQuickNoteItem() async {
    // Проверяем дебаунсинг для защиты от двойного срабатывания на macOS
    final now = DateTime.now();
    if (_lastAddItemTime != null &&
        now.difference(_lastAddItemTime!).inMilliseconds < _addItemDebounceMs) {
      print("🚫 Игнорируем повторный вызов addQuickNoteItem (дебаунсинг)");
      return;
    }
    _lastAddItemTime = now;

    // Если уже идет сохранение или обработка сохранения, выходим
    if (_isSavingItem || _isProcessingSave) {
      print("🚫 Игнорируем вызов - уже идет сохранение");
      return;
    }

    print("✅ Начинаем addQuickNoteItem");
    final newPosition = await getNextPosition();

    try {
      // Если уже есть редактируемый элемент, сначала сохраняем его
      if (_currentEditingItemId != null) {
        print("💾 Сохраняем текущий редактируемый элемент");
        _isProcessingSave = true;
        await saveItemContent(_currentEditingItemId!);
        _isProcessingSave = false;
        return; // Выходим, потому что сохранение может вызвать перерисовку и повторное добавление
      }

      // Создаем временный ID для нового элемента
      final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      print("🆔 Создан временный ID: $tempId");

      // Создаем контроллер и фокусноду для временного элемента
      itemControllers[tempId] = TextEditingController(text: '');
      itemFocusNodes[tempId] = FocusNode();

      // Модифицируем слушатель потери фокуса с проверкой флага _isProcessingSave
      itemFocusNodes[tempId]!.addListener(() {
        if (!itemFocusNodes[tempId]!.hasFocus && editingItems[tempId] == true) {
          // Проверяем, что элемент не в процессе сохранения и не обрабатывается
          if (!_isSavingItem && !_isProcessingSave) {
            final content = itemControllers[tempId]!.text.trim();

            // Устанавливаем флаг для предотвращения двойной обработки
            _isProcessingSave = true;

            // Используем Future.microtask чтобы отложить обработку до завершения текущей операции
            Future.microtask(() async {
              try {
                if (content.isEmpty) {
                  // Если контент пустой и фокус потерян, удаляем временный элемент
                  if (mounted) {
                    setState(() {
                      items.removeWhere((item) => item['id'] == tempId);
                      itemControllers.remove(tempId);
                      _isEditing = false;

                      // Сохраняем ссылки на объекты, которые нужно уничтожить
                      final nodeToDispose = itemFocusNodes[tempId];
                      itemFocusNodes.remove(tempId);
                      final animControllerToDispose =
                          _animationControllers[tempId];
                      _animationControllers.remove(tempId);

                      editingItems.remove(tempId);
                      if (_currentEditingItemId == tempId) {
                        _currentEditingItemId = null;
                      }

                      // Безопасно вызываем dispose() после setState
                      Future.microtask(() {
                        nodeToDispose?.dispose();
                        animControllerToDispose?.dispose();
                      });
                    });
                  }
                } else {
                  // Если контент не пустой, сохраняем временный элемент в базу данных
                  await _createPermanentItem(tempId, content, newPosition);
                }
              } finally {
                _isProcessingSave = false;
              }
            });
          }
        }
      });

      // Сначала добавляем элемент в состояние
      setState(() {
        // Добавляем временный элемент
        items.add({
          'id': tempId,
          'content': '',
          'type': 'note',
          'position': newPosition,
          'task_id': widget.taskId,
          'isTemporary': true, // Маркер временного элемента
        });

        // Создаем анимационный контроллер
        _animationControllers[tempId] = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 100),
        );
        _animationControllers[tempId]!
            .forward(); // Запускаем анимацию появления

        print("📝 Временный элемент добавлен в состояние");
      });

      // КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: Сначала делаем скролл к новому элементу
      // Ждем, пока виджет перестроится
      await Future.delayed(Duration(milliseconds: 100));

      if (mounted) {
        // Скроллим к новому элементу (он теперь последний в списке)
        _scrollToItem(items.length - 1);
        print("📜 Скролл к новому элементу выполнен");

        // Ждем завершения скролла
        await Future.delayed(Duration(milliseconds: 200));

        // Только ПОСЛЕ скролла включаем режим редактирования
        if (mounted) {
          setState(() {
            editingItems[tempId] = true;
            _currentEditingItemId = tempId;
            _isEditing = true;
          });

          print("✏️ Режим редактирования включен");

          // И только теперь устанавливаем фокус на TextField
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted && itemFocusNodes.containsKey(tempId)) {
              FocusScope.of(context).requestFocus(itemFocusNodes[tempId]);
              print("🎯 Фокус установлен на TextField");
            }
          });
        }
      }
    } catch (e) {
      print("❌ Ошибка при добавлении элемента: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.saveError(e.toString()),
            ),
          ),
        );
      }
      _isEditing = false;
      _isProcessingSave = false;
    }
  }

  // Метод для отображения расширенных опций элемента
  // Обновленный метод showItemOptions
  Future<void> showItemOptions(Map<String, dynamic> item) async {
    // Предотвращаем открытие диалога, если перетаскивание
    if (_longPressIsMove) return;

    _showingDialog = true;

    String selectedType = item['type']; // Текущий тип элемента
    final availableTypes = await fetchExistingTypes();

    DateTime? selectedDate =
        item['deadline'] != null ? DateTime.parse(item['deadline']) : null;
    // ignore: unused_local_variable
    final bool isChecklist = selectedType == 'checklist';
    bool isChecked = item['checked'] ?? false;

    // Получаем текущего назначенного пользователя
    String? assignedToId = item['assigned_to'];
    // ignore: unused_local_variable
    Map<String, dynamic>? assignedUser;

    if (assignedToId != null) {
      assignedUser = await _getCachedUserById(assignedToId);
    }

// Получаем всех участников задачи
    final List<Map<String, dynamic>> taskMembers =
        await _supabaseService.getTaskMembers(widget.taskId);

// Создаем список элементов для выпадающего списка
    List<Map<String, dynamic>> selectableMembers = [];

// Добавляем опцию "Не назначено"
    selectableMembers.add({
      'id': null,
      'display_name': AppLocalizations.of(context)!.notAssigned,
      'avatar_url': null,
      'user_data': {
        'id': null,
        'first_name': AppLocalizations.of(context)!.notAssigned,
        'last_name': ''
      },
    });

// Добавляем всех участников
    for (var member in taskMembers) {
      final userData = member['user_data'] as Map<String, dynamic>;
      final userId = userData['id'] as String;
      final login = userData['login'] as String? ?? 'User'; // Используем логин
      final avatarUrl = userData['avatar_url'] as String?;

      selectableMembers.add({
        'id': userId,
        'display_name': login, // Отображаем логин
        'avatar_url': avatarUrl,
        'user_data': userData,
      });
    }

// Выбранный пользователь (начальное значение)
    var selectedMember = selectableMembers.firstWhere(
      (m) => m['id'] == assignedToId,
      orElse: () => selectableMembers.first, // "Не назначено" по умолчанию
    );

    if (assignedToId == null) {
      // Если пользователь не назначен, выбираем "Не назначено"
      selectedMember = selectableMembers.first;
    } else {
      // Если пользователь назначен, находим его в списке
      selectedMember = selectableMembers.firstWhere(
        (member) => member['user_data']!['id'] == assignedToId,
        orElse: () => selectableMembers.first,
      );
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.itemOptionsTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Существующий код для выбора типа элемента
                Text(AppLocalizations.of(context)!.itemTypeLabel,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedType,
                      items: availableTypes
                          .map((type) => DropdownMenuItem<String>(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(_getIconForType(type)),
                                    SizedBox(width: 12),
                                    Text(_getTypeDisplayName(type)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                  ),
                ),

                // Добавляем секцию для выбора назначенного пользователя
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.assignParticipant,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedMember['id']
                          as String?, // Используем ID как значение
                      items: selectableMembers.map((member) {
                        final userId = member['id'] as String?;
                        final name = member['display_name'] as String;
                        final avatarUrl = member['avatar_url'] as String?;

                        return DropdownMenuItem<String>(
                          value: userId, // ID как значение
                          child: Row(
                            children: [
                              // Аватар пользователя
                              if (userId == null)
                                Icon(Icons.person_off,
                                    size: 24, color: Colors.grey)
                              else if (avatarUrl != null)
                                CircleAvatar(
                                  radius: 12,
                                  backgroundImage: NetworkImage(avatarUrl),
                                )
                              else
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: _getAvatarColor(userId),
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.white),
                                  ),
                                ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null || value == null) {
                          // null тоже валидное значение (Не назначено)
                          setStateDialog(() {
                            selectedMember = selectableMembers.firstWhere(
                              (m) => m['id'] == value,
                              orElse: () => selectableMembers.first,
                            );
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.deadlineLabel,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedDate != null
                            ? _getDeadlineColor(selectedDate?.toIso8601String())
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        selectedDate != null
                            ? _formatDeadline(selectedDate?.toIso8601String())
                            : AppLocalizations.of(context)!.notSet,
                        style: TextStyle(
                          color: selectedDate != null
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(Duration(days: 30)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setStateDialog(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (selectedDate != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setStateDialog(() {
                          selectedDate = null;
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.clearDeadline),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  final updateData = {
                    'type': selectedType,
                    'deadline': selectedDate?.toIso8601String(),
                    'checked': selectedType == 'checklist' ? isChecked : null,
                    'assigned_to': selectedMember[
                        'id'], // Используем ID выбранного пользователя
                  };

                  await _supabaseService.updateTaskItem(item['id'], updateData);

                  Navigator.pop(dialogContext, {
                    ...item,
                    ...updateData,
                  });
                } catch (e) {
                  print("Ошибка при обновлении элемента: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.saveError(e.toString()),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
            // Сохраняем кнопку удаления (без изменений)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.confirmation),
                        content: Text(AppLocalizations.of(context)!
                            .deleteItemConfirmation),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(AppLocalizations.of(context)!.delete),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (confirmed) {
                  try {
                    await _supabaseService.deleteTaskItemWithLog(item['id']);
                    Navigator.pop(dialogContext, null);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!
                                .deleteError(e.toString()),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        ),
      ),
    );

    _showingDialog = false;

    // Если диалог вернул обновленные данные, обновляем локальный элемент
    if (result != null) {
      setState(() {
        final index = items.indexWhere((i) => i['id'] == item['id']);
        if (index != -1) {
          items[index] = result;
        }
      });
    }
  }

  // Формирование обработки дедлайна и его отображения
  String _formatDeadline(String? deadlineStr) {
    if (deadlineStr == null) return AppLocalizations.of(context)!.noDeadline;

    try {
      final deadline = DateTime.parse(deadlineStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadlineDate =
          DateTime(deadline.year, deadline.month, deadline.day);

      final difference = deadlineDate.difference(today).inDays;

      if (difference == 0) {
        return AppLocalizations.of(context)!.today;
      } else if (difference == 1) {
        return AppLocalizations.of(context)!.tomorrow;
      } else if (difference < 0) {
        return AppLocalizations.of(context)!
            .overdueWithDate(DateFormat('dd.MM.yyyy').format(deadline));
      } else if (difference < 7) {
        final locale = Localizations.localeOf(context).toString();

        // Используем правильную локаль для форматирования
        DateFormat dateFormat = DateFormat('dd.MM (EEE)', locale);
        return dateFormat.format(deadline);
      } else {
        return DateFormat('dd.MM.yyyy').format(deadline);
      }
    } catch (e) {
      return AppLocalizations.of(context)!.invalidDate;
    }
  }

  // Проверка истек ли срок дедлайна
  bool _isDeadlineExpired(String? deadlineStr) {
    if (deadlineStr == null) return false;

    try {
      final deadline = DateTime.parse(deadlineStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadlineDate =
          DateTime(deadline.year, deadline.month, deadline.day);

      return deadlineDate.isBefore(today);
    } catch (e) {
      return false;
    }
  }

  // Вспомогательный метод для определения цвета дедлайна
  Color _getDeadlineColor(String? deadlineStr) {
    if (deadlineStr == null) return Colors.grey;

    try {
      final deadline = DateTime.parse(deadlineStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadlineDate =
          DateTime(deadline.year, deadline.month, deadline.day);

      final difference = deadlineDate.difference(today).inDays;

      if (difference < 0) {
        return Colors.red; // Просрочено
      } else if (difference == 0) {
        return Colors.orange; // Сегодня
      } else if (difference <= 2) {
        return Colors.amber; // Скоро
      } else {
        return Theme.of(context).colorScheme.primary; // В будущем
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  // Получение доступных типов элементов
  Future<List<String>> fetchExistingTypes() async {
    try {
      return await _supabaseService.getTaskItemTypes();
    } catch (e) {
      print("Ошибка при получении типов элементов: $e");
      return ['note', 'header', 'checklist']; // Резервные типы
    }
  }

  // Создание нового элемента задачи
  Future<void> addTaskItem() async {
    final existingTypes = await fetchExistingTypes();

    if (existingTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.noAvailableItemTypes)),
      );
      return;
    }

    String selectedType = 'note'; // Значение по умолчанию

    // Показываем диалог выбора типа элемента
    final selectedTypeResult = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.selectItemType),
        children: existingTypes
            .map((type) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, type),
                  child: Row(
                    children: [
                      Icon(_getIconForType(type)),
                      SizedBox(width: 16),
                      Text(
                        _getTypeDisplayName(type),
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );

    // Если диалог закрыт без выбора, выходим
    if (selectedTypeResult == null) return;
    selectedType = selectedTypeResult;

    final newPosition = await getNextPosition();

    try {
      setState(() {
        isLoading = true; // Показываем загрузку
      });

      await _supabaseService.createTaskItem(
        widget.taskId,
        selectedType,
        newPosition,
      );

      // Новый элемент будет добавлен через Realtime подписку
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Ошибка при добавлении элемента: $e");
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .genericErrorWithDetails(e.toString()),
            ),
          ),
        );
      }
    }
  }

  // Получение иконки для типа элемента
  IconData _getIconForType(String type) {
    switch (type) {
      case 'note':
        return Icons.notes;
      case 'header':
        return Icons.title;
      case 'checklist':
        return Icons.check_box;
      default:
        return Icons.text_fields;
    }
  }

  // Получение понятного названия для типа элемента
  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'note':
        return AppLocalizations.of(context)!.note;
      case 'header':
        return AppLocalizations.of(context)!.header;
      case 'checklist':
        return AppLocalizations.of(context)!.checklist;
      default:
        return type.toUpperCase();
    }
  }

  Future<void> addFriendToTask() async {
    print('Запрос на добавление участника задачи ${widget.taskId}');
    final availableUsers =
        await _supabaseService.getAvailableUsersForTask(widget.taskId);

    if (availableUsers.isEmpty) {
      print(
          'Нет доступных пользователей для добавления в задачу ${widget.taskId}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noAvailableUsers),
        ),
      );
      return;
    }

    print('Получено ${availableUsers.length} пользователей для добавления');
    String? selectedUserId = availableUsers.first['id'];
    TaskMemberRole selectedRole =
        TaskMemberRole.user; // По умолчанию роль "Пользователь"

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.addParticipant),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.selectUser,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  // Dropdown для выбора пользователя
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedUserId,
                        items: availableUsers.map((user) {
                          final name =
                              "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}"
                                  .trim();
                          return DropdownMenuItem<String>(
                            value: user['id'],
                            child: Row(
                              children: [
                                // Добавляем аватар или иконку профиля
                                if (user['avatar_url'] != null)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        NetworkImage(user['avatar_url']),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        _getAvatarColor(user['id']),
                                    child: Icon(
                                      Icons.person,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name.isEmpty ? user['id'] : name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedUserId = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.selectRole,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  // Dropdown для выбора роли
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TaskMemberRole>(
                        isExpanded: true,
                        value: selectedRole,
                        items: [
                          DropdownMenuItem<TaskMemberRole>(
                            value: TaskMemberRole.admin,
                            child: Text(AppLocalizations.of(context)!.admin),
                          ),
                          DropdownMenuItem<TaskMemberRole>(
                            value: TaskMemberRole.editor,
                            child: Text(AppLocalizations.of(context)!.editor),
                          ),
                          DropdownMenuItem<TaskMemberRole>(
                            value: TaskMemberRole.user,
                            child: Text(AppLocalizations.of(context)!.user),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedRole = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  // Информационная кнопка о ролях
                  TextButton.icon(
                    icon: Icon(Icons.info_outline, size: 18),
                    label: Text(AppLocalizations.of(context)!.rolesInfoButton),
                    onPressed: () {
                      showDialog(
                        context: dialogContext,
                        builder: (_) => AlertDialog(
                          title: Text(
                              AppLocalizations.of(context)!.rolesInfoTitle),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title:
                                    Text(AppLocalizations.of(context)!.admin),
                                subtitle: Text(AppLocalizations.of(context)!
                                    .userRoleAdminDescription),
                                leading: Icon(Icons.admin_panel_settings,
                                    color: Colors.deepPurple),
                              ),
                              ListTile(
                                title:
                                    Text(AppLocalizations.of(context)!.editor),
                                subtitle: Text(AppLocalizations.of(context)!
                                    .userRoleEditorDescription),
                                leading: Icon(Icons.edit, color: Colors.blue),
                              ),
                              ListTile(
                                title: Text(AppLocalizations.of(context)!.user),
                                subtitle: Text(AppLocalizations.of(context)!
                                    .userRoleUserDescription),
                                leading:
                                    Icon(Icons.person, color: Colors.green),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(AppLocalizations.of(context)!.ok),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => {
                  Navigator.pop(context),
                  showTaskMembers(),
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedUserId == null) return;

                  try {
                    print(
                        'Добавление пользователя $selectedUserId с ролью ${selectedRole.value} в задачу ${widget.taskId}');
                    await _supabaseService.addTaskMember(
                        widget.taskId, selectedUserId!, selectedRole);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(AppLocalizations.of(context)!.userAdded)),
                    );
                  } catch (e) {
                    print('Ошибка при добавлении пользователя в задачу: $e');
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .errorWhileAdding(e.toString())),
                      ),
                    );
                  }

                  showTaskMembers();
                },
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ],
          ),
        );
      },
    );
  }

  // Редактирование заголовка задачи
  Future<void> editTaskTitle() async {
    final TextEditingController titleController =
        TextEditingController(text: taskTitle);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editTaskTitle),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.task_name,
            border: OutlineInputBorder(),
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              if (newTitle.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.emptyTaskNameError)),
                );
                return;
              }

              try {
                await _supabaseService.updateTaskTitle(widget.taskId, newTitle);

                setState(() {
                  taskTitle = newTitle;
                });

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!
                        .genericErrorWithDetails(e.toString())),
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  // Функция для показа участников задачи
  Future<void> showTaskMembers() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TaskMembersDialog(
        taskId: widget.taskId,
        canManageMembers: _canManageMembers,
        supabaseService: _supabaseService,
        onNavigateToProfile: _navigateToUserProfile, // ДОБАВЛЯЕМ КОЛБЭК
      ),
    );

    // Если пользователь покинул задачу
    if (result == true) {
      Navigator.pop(context);
    }
  }

// Функция для получения цвета аватара на основе ID пользователя
  Color _getAvatarColor(String userId) {
    // Создаем стабильный цвет на основе хэша ID пользователя
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

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppLocalizations.of(context)!.admin;
      case 'editor':
        return AppLocalizations.of(context)!.editor;
      case 'user':
        return AppLocalizations.of(context)!.user;
      default:
        return AppLocalizations.of(context)!.user;
    }
  }

  // Получение следующей позиции для нового элемента
  Future<int> getNextPosition() async {
    try {
      // Если список элементов пустой, начинаем с 0
      if (items.isEmpty) return 0;

      // Иначе находим максимальную позицию и добавляем 1
      int maxPosition = 0;
      for (var item in items) {
        if ((item['position'] as int) > maxPosition) {
          maxPosition = item['position'] as int;
        }
      }
      return maxPosition + 1;
    } catch (e) {
      print("Ошибка при определении следующей позиции: $e");
      return items.length; // Резервный вариант
    }
  }

  // Получение информации о задаче и её элементах
  Future<void> fetchTaskDetailData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final taskData = await _supabaseService.getTaskDetails(widget.taskId);
      taskTitle = taskData.title;
      items = taskData.items;

      // Создаем контроллеры для всех загруженных элементов
      for (var item in items) {
        final String itemId = item['id'];
        itemControllers[itemId] = TextEditingController(text: item['content']);
        itemFocusNodes[itemId] = FocusNode();

        // Создаем анимационные контроллеры для каждого элемента
        _animationControllers[itemId] = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        );
        _animationControllers[itemId]!.value =
            1.0; // Начальное состояние - видимый
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Ошибка при получении данных задачи: $e");
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            AppLocalizations.of(context)!.taskLoadingError(e.toString());
      });
    }
  }

  // Кеш пользователей для оптимизации запросов
  Map<String, Map<String, dynamic>> _usersCache = {};

// Метод для получения пользователя с кешированием
  Future<Map<String, dynamic>?> _getCachedUserById(String userId) async {
    if (_usersCache.containsKey(userId)) {
      return _usersCache[userId];
    }

    final userData = await _supabaseService.getUserById(userId);
    if (userData != null) {
      _usersCache[userId] = userData;
    }

    return userData;
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return GestureDetector(
      onTap: () {
        // Проверяем, не идет ли уже сохранение
        if (_currentEditingItemId != null && !_isSavingItem) {
          FocusScope.of(context).requestFocus(_backgroundFocusNode);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    taskTitle.isNotEmpty
                        ? taskTitle
                        : AppLocalizations.of(context)!.taskDetailsTitle,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          actions: [
            IconButton(
              icon: Icon(Icons.people),
              onPressed: showTaskMembers,
              tooltip: AppLocalizations.of(context)!.membersTooltip,
            ),
            if (_canManageMembers)
              IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {
                  // Сохраняем текущий элемент перед открытием меню
                  if (_currentEditingItemId != null) {
                    saveItemContent(_currentEditingItemId!);
                  }

                  // Показываем меню опций
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Опция изменения названия только с правами редактирования
                        ListTile(
                          leading: Icon(Icons.edit),
                          title: Text(AppLocalizations.of(context)!.edit_name),
                          onTap: () {
                            Navigator.pop(context);
                            editTaskTitle();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        body: ResponsiveWrapper(
          maxWidth: 500,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(child: Text(errorMessage!))
                  : items.isEmpty
                      ? EmptyStateWidget(
                          onAddItem: _canEdit ? addQuickNoteItem : null)
                      : _buildTaskItemsListAlternative(),
        ),
        floatingActionButton: (_canEdit && !isKeyboardVisible && !_isEditing)
            ? FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: () {
                  // Сохраняем текущий элемент перед добавлением нового
                  if (_currentEditingItemId != null) {
                    saveItemContent(_currentEditingItemId!);
                  }
                  addQuickNoteItem();
                },
                child: const Icon(Icons.add),
                tooltip: AppLocalizations.of(context)!.addNoteTooltip,
              )
            : null, // Скрываем кнопку если нет прав на редактирование
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

// // Новый метод для создания стека с списком и кнопкой
//   Widget _buildTaskItemsStack() {
//     return Stack(
//       children: [
//         _buildTaskItemsList(),
//         // Добавляем пустое пространство для корректного отображения списка под FAB
//         Positioned(
//           bottom: 0,
//           left: 0,
//           right: 0,
//           child: SizedBox(height: 80), // Высота для FAB
//         ),
//       ],
//     );
//   }

// // // Модифицированный метод для списка без нижнего отступа
  // Widget _buildTaskItemsList() {
  //   return ListView(
  //     children: [
  //       SizedBox(height: 16),
  //       // Показываем нужный виджет в зависимости от прав пользователя
  //       _buildEditableList(),
  //       SizedBox(height: 20),
  //     ],
  //   );
  // }

// Список с возможностью перетаскивания
  Widget _buildTaskItemsListAlternative() {
    return Column(
      children: [
        Expanded(
          child: TaskItemsReorderableList(
            scrollController: _scrollController,
            items: items,
            editingItems: editingItems,
            itemControllers: itemControllers,
            itemFocusNodes: itemFocusNodes,
            currentEditingItemId: _currentEditingItemId,
            canEdit: _canEdit,
            usersCache: _usersCache,
            onNavigateToProfile: _navigateToUserProfile, // ДОБАВЛЯЕМ ЭТУ СТРОКУ

            onToggleEditing: (itemId, content) {
              if (_currentEditingItemId != null &&
                  _currentEditingItemId != itemId) {
                saveItemContent(_currentEditingItemId!);
              } else if (!(editingItems[itemId] ?? false)) {
                toggleEditing(itemId, content);
              }
            },

            onSaveItemContent: (itemId) => saveItemContent(itemId),
            onShowItemOptions: (item) => showItemOptions(item),

            onCheckChanged: (itemId, value) async {
              if (_currentEditingItemId != null) {
                saveItemContent(_currentEditingItemId!);
              }

              try {
                setState(() {
                  final index = items.indexWhere((i) => i['id'] == itemId);
                  if (index != -1) {
                    items[index]['isSaving'] = true;
                  }
                });

                await _supabaseService.updateTaskItemChecked(itemId, value);

                if (mounted) {
                  setState(() {
                    final index = items.indexWhere((i) => i['id'] == itemId);
                    if (index != -1) {
                      items[index]['checked'] = value;
                      items[index]['isSaving'] = false;
                    }
                  });
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    final index = items.indexWhere((i) => i['id'] == itemId);
                    if (index != -1) {
                      items[index]['isSaving'] = false;
                    }
                  });
                }
              }
            },

            onReorderFinished: (item, oldIndex, newIndex) {
              if (_currentEditingItemId != null) {
                saveItemContent(_currentEditingItemId!);
              }

              setState(() {
                final movedItem = items.removeAt(oldIndex!);
                items.insert(newIndex!, movedItem);
              });

              Future.delayed(Duration(milliseconds: 100), () {
                _updatePositionsExtended(item['id']);
              });
            },

            formatDeadline: _formatDeadline,
            isDeadlineExpired: _isDeadlineExpired,
            getDeadlineColor: _getDeadlineColor,
            getAvatarColor: _getAvatarColor,
            getCachedUserById: (userId) {
              _getCachedUserById(userId).then((userData) {
                if (userData != null && mounted) {
                  setState(() {
                    _usersCache[userId] = userData;
                  });
                }
              });
              return userId;
            },
          ),
        ),
      ],
    );
  }
}

/// Виджет для отображения пустого состояния (когда нет элементов)
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback? onAddItem; // Теперь опциональный - null если нет прав

  const EmptyStateWidget({
    Key? key,
    required this.onAddItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool canAddItems = onAddItem != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 64,
            // ignore: deprecated_member_use
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noTaskItems,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              // ignore: deprecated_member_use
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canAddItems
                ? AppLocalizations.of(context)!.tapToAddFirstItem
                : AppLocalizations.of(context)!.noPermissionToAddItems,
            style: TextStyle(
              // ignore: deprecated_member_use
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Очередь обновлений позиций
class PositionUpdateQueue {
  final _queue = <Map<String, dynamic>>[];
  bool _processing = false;
  final Function(String, int, String) _updateFunction;
  final Function(String) _onError;
  final Function() _onComplete;

  PositionUpdateQueue(this._updateFunction, this._onError, this._onComplete);

  void add(String itemId, int position, String taskId) {
    _queue.add({
      'itemId': itemId,
      'position': position,
      'taskId': taskId,
    });

    if (!_processing) {
      _processNext();
    }
  }

  Future<void> _processNext() async {
    if (_queue.isEmpty) {
      _processing = false;
      _onComplete();
      return;
    }

    _processing = true;
    final item = _queue.removeAt(0);

    try {
      await _updateFunction(item['itemId'], item['position'], item['taskId']);
      // Небольшая задержка между запросами
      _processNext();
    } catch (e) {
      print("Ошибка в очереди обновлений: $e");
      _onError(item['itemId']);
      // Продолжаем с следующим элементом
      _processNext();
    }
  }

  void clear() {
    _queue.clear();
  }
}

// Создаем отдельный виджет для управления участниками
// ignore: must_be_immutable
class TaskMembersDialog extends StatefulWidget {
  final String taskId;
  bool canManageMembers;
  final SupabaseService supabaseService;
  final Function(String) onNavigateToProfile;

  TaskMembersDialog({
    Key? key,
    required this.taskId,
    required this.canManageMembers,
    required this.supabaseService,
    required this.onNavigateToProfile,
  }) : super(key: key);

  @override
  _TaskMembersDialogState createState() => _TaskMembersDialogState();
}

class _TaskMembersDialogState extends State<TaskMembersDialog> {
  List<Map<String, dynamic>> regularMembers = [];
  Map<String, dynamic>? creator;
  String? currentUserId;
  String? taskCreatorId;
  bool isLoading = true;
  RealtimeChannel? _membersChannel;

  bool _isCurrentUserAdmin = false;
  bool _isCurrentUserCreator = false;

  @override
  void initState() {
    super.initState();
    currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _fetchMembers();
    _setupRealtimeForMembers();
  }

  @override
  void dispose() {
    _membersChannel?.unsubscribe();
    super.dispose();
  }

  void _updatePermissions() {
    if (currentUserId == null) return;

    bool isCreator =
        creator != null && creator!['user_data']['id'] == currentUserId;
    bool isAdmin = false;

    for (var member in regularMembers) {
      if (member['user_data']['id'] == currentUserId) {
        isAdmin = member['role'] == 'admin';
        break;
      }
    }

    if (_isCurrentUserCreator != isCreator || _isCurrentUserAdmin != isAdmin) {
      setState(() {
        _isCurrentUserCreator = isCreator;
        _isCurrentUserAdmin = isAdmin;
        widget.canManageMembers = isCreator || isAdmin;
      });
    }
  }

  void _setupRealtimeForMembers() {
    final client = Supabase.instance.client;

    _membersChannel = client
        .channel('task-members-updates-${widget.taskId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'task_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'task_id',
            value: widget.taskId,
          ),
          callback: (_) {
            _fetchMembers();
          },
        );

    _membersChannel?.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'task_members',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'task_id',
        value: widget.taskId,
      ),
      callback: (payload) {
        if (payload.newRecord != null) {
          final updatedMember = Map<String, dynamic>.from(payload.newRecord);
          final String userId = updatedMember['user_id'];
          final String role = updatedMember['role'] ?? 'user';

          setState(() {
            for (int i = 0; i < regularMembers.length; i++) {
              if (regularMembers[i]['user_data']['id'] == userId) {
                regularMembers[i]['role'] = role;
                break;
              }
            }
          });

          if (userId == currentUserId) {
            _updatePermissions();

            if (role != 'admin' && !_isCurrentUserCreator) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      AppLocalizations.of(context)!.roleChangedLimitedAccess),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      },
    );

    _membersChannel?.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'task_members',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'task_id',
        value: widget.taskId,
      ),
      callback: (payload) {
        final deletedMember = payload.oldRecord;
        final String userId = deletedMember['user_id'];

        if (userId == currentUserId) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.removedFromTask)),
          );
          return;
        }

        setState(() {
          regularMembers
              .removeWhere((member) => member['user_data']['id'] == userId);
        });
      },
    );

    _membersChannel?.subscribe();
  }

  Future<void> _fetchMembers() async {
    try {
      final fetchedMembers =
          await widget.supabaseService.getTaskMembers(widget.taskId);
      taskCreatorId =
          await widget.supabaseService.getTaskCreatorId(widget.taskId);

      Map<String, dynamic>? fetchedCreator;
      List<Map<String, dynamic>> fetchedRegularMembers = [];

      for (var member in fetchedMembers) {
        final user = member['user_data'] as Map<String, dynamic>;
        if (user['id'] == taskCreatorId) {
          fetchedCreator = member;
        } else {
          fetchedRegularMembers.add(member);
        }
      }

      if (fetchedCreator == null && taskCreatorId != null) {
        final userResponse = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', taskCreatorId!)
            .maybeSingle();

        if (userResponse != null) {
          fetchedCreator = {
            'user_data': userResponse,
            'role': 'admin',
          };
        }
      }

      if (mounted) {
        setState(() {
          creator = fetchedCreator;
          regularMembers = fetchedRegularMembers;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при получении участников задачи: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToLoadMembers(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.removeMemberTitle),
            content:
                Text(AppLocalizations.of(context)!.removeMemberConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(context)!.delete),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        // Важно: удаляем пользователя из списка до вызова API
        // для мгновенной обратной связи
        setState(() {
          isLoading = true;
          // Оптимистично удаляем участника до получения ответа с сервера
          regularMembers
              .removeWhere((member) => member['user_data']['id'] == userId);
        });

        // Вызываем API для удаления участника
        await widget.supabaseService.removeTaskMember(widget.taskId, userId);

        if (mounted) {
          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.memberRemoved)),
          );
        }
      } catch (e) {
        if (mounted) {
          // В случае ошибки обновляем полный список
          _fetchMembers();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .genericErrorWithDetails(e.toString())),
            ),
          );
        }
      }
    }
  }

// Изменение роли участника
  Future<void> _updateMemberRole(String userId, String currentRole) async {
    final newRoleString =
        await _showRolePickerBottomSheet(context, currentRole);
    if (newRoleString != null && newRoleString != currentRole) {
      try {
        setState(() {
          isLoading = true; // Показываем индикатор загрузки
        });

        // Отправляем изменения на сервер
        final newRoleEnum = TaskMemberRoleExtension.fromString(newRoleString);
        await widget.supabaseService
            .updateTaskMemberRole(widget.taskId, userId, newRoleEnum);

        if (mounted) {
          setState(() {
            isLoading = false;

            // Обновляем UI
            for (int i = 0; i < regularMembers.length; i++) {
              if (regularMembers[i]['user_data']['id'] == userId) {
                regularMembers[i]['role'] = newRoleString;
              }
            }
          });

          // Обновляем права после изменения данных
          _updatePermissions();

          // Если это текущий пользователь, закрываем диалог и передаем информацию
          if (userId == currentUserId) {
            bool canManage = (newRoleString == 'admin');
            bool canEdit =
                (newRoleString == 'admin' || newRoleString == 'editor');

            Navigator.pop(context, {
              'roleChanged': true,
              'canManageMembers': canManage,
              'canEdit': canEdit,
              'newRole': newRoleString
            });

            return; // Выходим из метода
          }

          // Для других пользователей
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.roleUpdated)),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          _fetchMembers(); // Обновляем данные в случае ошибки
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .roleUpdateError(e.toString()))),
          );
        }
      }
    }
  }

// Показ диалога для выбора роли
  Future<String?> _showRolePickerBottomSheet(
      BuildContext parentContext, String currentRole) async {
    return await showModalBottomSheet<String>(
      context: parentContext,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  AppLocalizations.of(context)!.selectNewMemberRole,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Text(
                  AppLocalizations.of(context)!.rolesInfoDescription,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              ListTile(
                leading: Icon(Icons.admin_panel_settings),
                title: Text(AppLocalizations.of(context)!.userRoleAdmin),
                selected: currentRole == 'admin',
                onTap: () => Navigator.pop(context, 'admin'),
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text(AppLocalizations.of(context)!.userRoleEditor),
                selected: currentRole == 'editor',
                onTap: () => Navigator.pop(context, 'editor'),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text(AppLocalizations.of(context)!.userRoleUser),
                selected: currentRole == 'user',
                onTap: () => Navigator.pop(context, 'user'),
              ),
            ],
          ),
        );
      },
    );
  }

// Выход из задачи
  Future<void> _leaveTask() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.leaveTask),
            content: Text(AppLocalizations.of(context)!.leaveTaskConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(context)!.leave),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && currentUserId != null) {
      try {
        await widget.supabaseService
            .removeTaskMember(widget.taskId, currentUserId!);
        // Закрываем диалог и возвращаемся на предыдущий экран
        Navigator.of(context).pop(true); // true означает что пользователь вышел

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.leftTask)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .genericErrorWithDetails(e.toString())),
          ),
        );
      }
    }
  }

  void _showRolesInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rolesInfoTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.admin),
              subtitle:
                  Text(AppLocalizations.of(context)!.userRoleAdminDescription),
              leading:
                  Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.editor),
              subtitle:
                  Text(AppLocalizations.of(context)!.userRoleEditorDescription),
              leading: Icon(Icons.edit, color: Colors.blue),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.user),
              subtitle:
                  Text(AppLocalizations.of(context)!.userRoleUserDescription),
              leading: Icon(Icons.person, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  // Новый метод для создания кликабельного аватара
  Widget _buildClickableAvatarWidget(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final name =
        "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();
    final avatarUrl = user['avatar_url'] as String?;

    return GestureDetector(
      onTap: () {
        if (userId == currentUserId) {
          return;
        }
        Navigator.pop(context);
        widget.onNavigateToProfile(userId);
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            // ignore: deprecated_member_use
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(avatarUrl),
              )
            : CircleAvatar(
                radius: 16,
                backgroundColor: _getAvatarColor(userId),
                child: name.isNotEmpty
                    ? Text(
                        name[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.person, size: 12, color: Colors.white),
              ),
      ),
    );
  }

  // Остальные вспомогательные методы
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

  String _getUserDisplayName(Map<String, dynamic> user) {
    final name =
        "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();
    return name.isEmpty ? user['id'] : name;
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.deepPurple;
      case 'editor':
        return Colors.blue;
      case 'user':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppLocalizations.of(context)!.admin;
      case 'editor':
        return AppLocalizations.of(context)!.editor;
      case 'user':
        return AppLocalizations.of(context)!.user;
      default:
        return AppLocalizations.of(context)!.user;
    }
  }

  // Добавление нового участника
  Future<void> _addMember() async {
    final taskCreatorId =
        await widget.supabaseService.getTaskCreatorId(widget.taskId);
    final unfilteredUsers =
        await widget.supabaseService.getAvailableUsersForTask(widget.taskId);
    final availableUsers =
        unfilteredUsers.where((user) => user['id'] != taskCreatorId).toList();

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noAvailableUsers)),
      );
      return;
    }

    String? selectedUserId = availableUsers.first['id'];
    TaskMemberRole selectedRole = TaskMemberRole.user;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.addParticipant),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.selectUser,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedUserId,
                        items: availableUsers.map((user) {
                          final name =
                              "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}"
                                  .trim();
                          return DropdownMenuItem<String>(
                            value: user['id'],
                            child: GestureDetector(
                              onTap: () {
                                // Закрываем диалоги и навигируем к профилю
                                Navigator.pop(dialogContext);
                                Navigator.pop(context);
                                widget.onNavigateToProfile(user['id']);
                              },
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      _buildAvatarWidget(user),
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.launch,
                                            size: 8,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          name.isEmpty ? user['id'] : name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color,
                                          ),
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .tapToViewProfile,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedUserId = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.selectRole,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TaskMemberRole>(
                        isExpanded: true,
                        value: selectedRole,
                        items: [
                          DropdownMenuItem<TaskMemberRole>(
                            value: TaskMemberRole.admin,
                            child: Text(AppLocalizations.of(context)!.admin),
                          ),
                          DropdownMenuItem<TaskMemberRole>(
                            value: TaskMemberRole.editor,
                            child: Text(AppLocalizations.of(context)!.editor),
                          ),
                          DropdownMenuItem<TaskMemberRole>(
                            value: TaskMemberRole.user,
                            child: Text(AppLocalizations.of(context)!.user),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedRole = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  if (selectedUserId == null) return;
                  Navigator.pop(dialogContext, {
                    'userId': selectedUserId,
                    'role': selectedRole,
                  });
                },
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      try {
        setState(() {
          isLoading = true;
        });

        await widget.supabaseService
            .addTaskMember(widget.taskId, result['userId'], result['role']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.userAdded)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorWhileAdding(e.toString())),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Недостающий метод _buildAvatarWidget для совместимости
  Widget _buildAvatarWidget(Map<String, dynamic> user) {
    final name =
        "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();

    if (user['avatar_url'] != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(user['avatar_url']),
      );
    } else {
      return CircleAvatar(
        radius: 16,
        backgroundColor: _getAvatarColor(user['id']),
        child: name.isNotEmpty
            ? Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.person, size: 12, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _updatePermissions();

    final bool canChangeRoles = _isCurrentUserCreator || _isCurrentUserAdmin;
    final bool userCanManageMembers = widget.canManageMembers;
    final bool isCreator =
        creator != null && creator!['user_data']['id'] == currentUserId;

    bool isAdmin = false;
    for (var member in regularMembers) {
      if (member['user_data']['id'] == currentUserId) {
        isAdmin = member['role'] == 'admin';
        break;
      }
    }

    final bool showAddMemberButton =
        isCreator || isAdmin || userCanManageMembers;

    return Dialog(
      insetPadding: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minWidth: 300,
            maxWidth: 600,
          ),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Заголовок диалога
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.task_members,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.info_outline),
                            onPressed: () => _showRolesInfoDialog(context),
                            tooltip:
                                AppLocalizations.of(context)!.rolesInfoButton,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),

                    // Секция создателя
                    if (creator != null) ...[
                      ListTile(
                        leading:
                            _buildClickableAvatarWidget(creator!['user_data']),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getUserDisplayName(creator!['user_data']),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.creator,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: creator!['user_data']['id'] == currentUserId
                            ? Text(
                                AppLocalizations.of(context)!.you,
                                style: TextStyle(fontSize: 12),
                              )
                            : Text(''),
                      ),
                      Divider(
                        height: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],

                    // Список обычных участников
                    Expanded(
                      child: regularMembers.isEmpty
                          ? Center(
                              child:
                                  Text(AppLocalizations.of(context)!.noMembers))
                          : ListView.builder(
                              itemCount: regularMembers.length,
                              itemBuilder: (context, index) {
                                final member = regularMembers[index];
                                final user =
                                    member['user_data'] as Map<String, dynamic>;
                                final String role = member['role'] ?? 'user';
                                final String userId = user['id'];
                                final isCurrentUser = userId == currentUserId;

                                return ListTile(
                                  leading: _buildClickableAvatarWidget(user),
                                  title: Text(
                                    _getUserDisplayName(user),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      GestureDetector(
                                        // Изменение роли доступно только если есть права И это не текущий пользователь
                                        onTap: canChangeRoles && !isCurrentUser
                                            ? () =>
                                                _updateMemberRole(userId, role)
                                            : null,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(role),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            // Добавляем визуальную подсказку что элемент кликабельный
                                            border:
                                                canChangeRoles && !isCurrentUser
                                                    ? Border.all(
                                                        color: Colors.white
                                                            .withOpacity(0.3),
                                                        width: 1)
                                                    : null,
                                          ),
                                          child: Text(
                                            _getRoleDisplayName(role),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isCurrentUser)
                                        Text(
                                          AppLocalizations.of(context)!.you,
                                          style: TextStyle(fontSize: 12),
                                        )
                                      else
                                        Text(''),
                                    ],
                                  ),
                                  trailing: canChangeRoles && !isCurrentUser
                                      ? IconButton(
                                          icon: Icon(
                                              Icons.remove_circle_outline,
                                              size: 20),
                                          color: Colors.red,
                                          onPressed: () =>
                                              _removeMember(userId),
                                          tooltip: AppLocalizations.of(context)!
                                              .removeMemberTitle,
                                        )
                                      : isCurrentUser
                                          ? IconButton(
                                              icon: Icon(Icons.exit_to_app,
                                                  size: 20),
                                              color: Colors.orange,
                                              onPressed: _leaveTask,
                                              tooltip:
                                                  AppLocalizations.of(context)!
                                                      .leaveTask,
                                            )
                                          : null,
                                );
                              },
                            ),
                    ),

                    // Кнопки снизу
                    Divider(
                      height: 10,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (showAddMemberButton)
                            TextButton(
                              onPressed: _addMember,
                              child: Text(
                                  AppLocalizations.of(context)!.add_member),
                            ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.close),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
