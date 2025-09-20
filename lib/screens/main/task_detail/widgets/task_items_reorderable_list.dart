import 'dart:async';
import 'package:pointo/screens/main/task_detail/widgets/animated_task_item_widget.dart';
import 'package:pointo/screens/main/task_detail/widgets/animation_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';

// Анимированный виджет для интерактивного списка с перетаскиванием
class TaskItemsReorderableList extends StatefulWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> items;
  final Map<String, bool> editingItems;
  final Map<String, TextEditingController> itemControllers;
  final Map<String, FocusNode> itemFocusNodes;
  final String? currentEditingItemId;
  final bool canEdit;
  final Map<String, Map<String, dynamic>> usersCache;

  // Колбэки
  final Function(String itemId, String content) onToggleEditing;
  final Function(String itemId) onSaveItemContent;
  final Function(Map<String, dynamic> item) onShowItemOptions;
  final Function(String itemId, bool? value) onCheckChanged;
  final Function(Map<String, dynamic> item, int? oldIndex, int? newIndex) onReorderFinished;
  final Function(String) formatDeadline;
  final Function(String?) isDeadlineExpired;
  final Function(String?) getDeadlineColor;
  final Function(String) getAvatarColor;
  final Function(String) getCachedUserById;
  
  // ИСПРАВЛЕННОЕ ПОЛЕ - добавляем правильное поле для навигации
  final Function(String userId)? onNavigateToProfile;

  const TaskItemsReorderableList({
    Key? key,
    required this.scrollController,
    required this.items,
    required this.editingItems,
    required this.itemControllers,
    required this.itemFocusNodes,
    required this.currentEditingItemId,
    required this.canEdit,
    required this.usersCache,
    required this.onToggleEditing,
    required this.onSaveItemContent,
    required this.onShowItemOptions,
    required this.onCheckChanged,
    required this.onReorderFinished,
    required this.formatDeadline,
    required this.isDeadlineExpired,
    required this.getDeadlineColor,
    required this.getAvatarColor,
    required this.getCachedUserById,
    this.onNavigateToProfile, // ИСПРАВЛЕННЫЙ ПАРАМЕТР
  }) : super(key: key);

  // УДАЛЯЕМ ЭТУ НЕПРАВИЛЬНУЮ СТРОКУ:
  // get onNavigateToProfile => UserProfilePage;

  @override
  State<TaskItemsReorderableList> createState() => _TaskItemsReorderableListState();
}

// Остальная часть класса остается без изменений...
class _TaskItemsReorderableListState extends State<TaskItemsReorderableList>
    with TickerProviderStateMixin {
  Timer? _longPressTimer;
  bool _longPressTriggered = false;
  Map<String, dynamic>? _longPressedItem;
  bool _isDragging = false;
  bool _hasMoved = false;
  Offset? _startPosition;

  // Локальные копии для безопасного изменения
  late List<Map<String, dynamic>> _localItems;

  // Анимационные контроллеры для каждого элемента
  Map<String, AnimationController> _itemAnimations = {};
  Map<String, Animation<double>> _scaleAnimations = {};
  Map<String, Animation<double>> _fadeAnimations = {};
  Map<String, Animation<Offset>> _slideAnimations = {};

  // НОВОЕ: Специальные контроллеры для reorder анимации
  Map<String, AnimationController> _reorderAnimations = {};

  @override
  void initState() {
    super.initState();
    _localItems = widget.items.map((item) => Map<String, dynamic>.from(item)).toList();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(TaskItemsReorderableList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Создаем новые локальные копии
    final newLocalItems = widget.items.map((item) => Map<String, dynamic>.from(item)).toList();

    _updateAnimations(oldWidget.items);

    // Обновляем локальные элементы
    _localItems = newLocalItems;
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _disposeAllAnimations();
    super.dispose();
  }

  void _initializeAnimations() {
    for (var item in _localItems) {
      _createAnimationForItem(item['id'], shouldAnimate: false);
    }
  }

  void _updateAnimations(List<Map<String, dynamic>> oldItems) {
    print("🔄 _updateAnimations вызван");

    final oldIds = oldItems.map((item) => item['id'] as String).toSet();
    final newIds = widget.items.map((item) => item['id'] as String).toSet();

    // Удаляем анимации для удаленных элементов
    final removedIds = oldIds.difference(newIds);
    for (final id in removedIds) {
      print("❌ Удаляем анимацию для элемента: $id");
      _disposeAnimationForItem(id);
    }

    // Создаем анимации для новых элементов
    final addedIds = newIds.difference(oldIds);
    for (final id in addedIds) {
      print("✅ Создаем анимацию для нового элемента: $id");
      _createAnimationForItem(id, shouldAnimate: true);

      // Безопасно устанавливаем флаг появления
      _setAnimationFlag(id, 'isAppearing', true);
      _setTemporaryAnimationFlag(id, 'isAppearing', Duration(milliseconds: 400));
    }

    // Проверяем только изменения контента (НЕ позиций)
    for (var newItem in widget.items) {
      final id = newItem['id'] as String;

      if (oldIds.contains(id)) {
        final oldItem = oldItems.firstWhere((old) => old['id'] == id);

        // Проверка на изменение данных (исключаем position)
        if (_hasItemChanged(oldItem, newItem)) {
          print("📝 Элемент $id изменился (контент/чекбокс/дедлайн)");
          _animateItemChange(id);

          _setAnimationFlag(id, 'isUpdating', true);
          _setTemporaryAnimationFlag(id, 'isUpdating', Duration(milliseconds: 500));
        }

        // Запускаем reorder анимацию, если флаг уже установлен
        if (newItem['isReordering'] == true && !_reorderAnimations.containsKey(id)) {
          print("🎬 Обнаружен флаг reorder для элемента $id, запускаем анимацию");
          _animateReorderChange(id);
        }
      }
    }
  }

  // Обновленный метод _hasItemChanged (исключаем position)
  bool _hasItemChanged(Map<String, dynamic> oldItem, Map<String, dynamic> newItem) {
    return oldItem['content'] != newItem['content'] ||
        oldItem['checked'] != newItem['checked'] ||
        oldItem['type'] != newItem['type'] ||
        oldItem['deadline'] != newItem['deadline'] ||
        oldItem['assigned_to'] != newItem['assigned_to'];
    // НЕ сравниваем position!
  }

  // НОВЫЙ МЕТОД: Простая анимация для reorder
  void _animateReorderChange(String itemId) {
    print("🎬 _animateReorderChange вызван для элемента: $itemId");

    // Создаем отдельный контроллер для reorder анимации
    final reorderController = AnimationController(
      duration: Duration(milliseconds: 800), // Увеличиваем время для лучшей видимости
      vsync: this,
    );

    _reorderAnimations[itemId] = reorderController;
    print("✅ Создан reorder контроллер для $itemId");

    // Устанавливаем флаг
    _setAnimationFlag(itemId, 'isReordering', true);
    print("🏁 Установлен флаг isReordering=true для $itemId");

    // Простая анимация: элемент мигает
    reorderController.repeat(reverse: true, period: Duration(milliseconds: 400));
    print("🎭 Запущена анимация мигания для $itemId");

    // Останавливаем анимацию через 800ms
    Future.delayed(Duration(milliseconds: 800), () {
      print("⏹️ Останавливаем анимацию для $itemId");
      if (mounted && _reorderAnimations.containsKey(itemId)) {
        reorderController.stop();
        _setAnimationFlag(itemId, 'isReordering', false);
        _reorderAnimations.remove(itemId)?.dispose();
        print("🗑️ Очищен reorder контроллер для $itemId");
      }
    });
  }

  // Безопасная установка флага анимации
  void _setAnimationFlag(String itemId, String flagName, bool value) {
    print("🏁 _setAnimationFlag: $itemId.$flagName = $value");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          final index = _localItems.indexWhere((item) => item['id'] == itemId);
          if (index != -1) {
            if (value) {
              _localItems[index][flagName] = true;
              print("✅ Флаг $flagName установлен для элемента $itemId (index: $index)");
            } else {
              _localItems[index].remove(flagName);
              print("❌ Флаг $flagName удален для элемента $itemId (index: $index)");
            }
          } else {
            print("⚠️ Элемент $itemId не найден в _localItems для установки флага $flagName");
          }
        });
      }
    });
  }

  // Безопасная установка флага с автоудалением
  void _setTemporaryAnimationFlag(String itemId, String flagName, Duration duration) {
    _setAnimationFlag(itemId, flagName, true);

    Future.delayed(duration, () {
      if (mounted) {
        _setAnimationFlag(itemId, flagName, false);
      }
    });
  }

  void _createAnimationForItem(String itemId, {bool shouldAnimate = false}) {
    if (_itemAnimations.containsKey(itemId)) return;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final scaleAnimation = Tween<double>(
      begin: shouldAnimate ? 0.8 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));

    final fadeAnimation = Tween<double>(
      begin: shouldAnimate ? 0.0 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    final slideAnimation = Tween<Offset>(
      begin: shouldAnimate ? const Offset(0.3, 0) : Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));

    _itemAnimations[itemId] = controller;
    _scaleAnimations[itemId] = scaleAnimation;
    _fadeAnimations[itemId] = fadeAnimation;
    _slideAnimations[itemId] = slideAnimation;

    // Запускаем анимацию
    if (shouldAnimate) {
      controller.forward();
    } else {
      controller.value = 1.0;
    }
  }

  void _animateItemChange(String itemId) {
    final controller = _itemAnimations[itemId];
    if (controller != null) {
      // Создаем эффект "пульсации" для изменения
      controller.reset();
      controller.forward().then((_) {
        if (mounted) {
          // Небольшая пульсация
          controller.reverse().then((_) {
            if (mounted) {
              controller.forward();
            }
          });
        }
      });
    }
  }

  void _animateItemRemoval(String itemId, VoidCallback onComplete) {
    final controller = _itemAnimations[itemId];
    if (controller != null) {
      // Анимация удаления
      final removeController = AnimationController(
        duration: const Duration(milliseconds: 350),
        vsync: this,
      );

      final removeScale = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: removeController, curve: Curves.easeInBack));

      final removeFade = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: removeController, curve: Curves.easeOut));

      final removeSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0)).animate(
          CurvedAnimation(parent: removeController, curve: Curves.easeInCubic));

      _scaleAnimations[itemId] = removeScale;
      _fadeAnimations[itemId] = removeFade;
      _slideAnimations[itemId] = removeSlide;

      removeController.forward().then((_) {
        removeController.dispose();
        onComplete();
      });
    } else {
      onComplete();
    }
  }

  void _disposeAnimationForItem(String itemId) {
    _itemAnimations[itemId]?.dispose();
    _itemAnimations.remove(itemId);
    _scaleAnimations.remove(itemId);
    _fadeAnimations.remove(itemId);
    _slideAnimations.remove(itemId);

    // Очищаем reorder анимации
    _reorderAnimations[itemId]?.dispose();
    _reorderAnimations.remove(itemId);
  }

  void _disposeAllAnimations() {
    for (var controller in _itemAnimations.values) {
      controller.dispose();
    }
    _itemAnimations.clear();
    _scaleAnimations.clear();
    _fadeAnimations.clear();
    _slideAnimations.clear();

    // Очищаем reorder анимации
    for (var controller in _reorderAnimations.values) {
      controller.dispose();
    }
    _reorderAnimations.clear();
  }

  void _handlePointerDown(PointerDownEvent event, Map<String, dynamic> item) {
    _startPosition = event.localPosition;
    _longPressTriggered = false;
    _longPressedItem = item;
    _isDragging = false;
    _hasMoved = false;

    _longPressTimer = Timer(const Duration(milliseconds: 600), () {
      if (!_hasMoved && !_isDragging) {
        _longPressTriggered = true;
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_startPosition != null) {
      final distance = (event.localPosition - _startPosition!).distance;
      if (distance > 10) {
        _hasMoved = true;
        _longPressTimer?.cancel();
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_longPressTriggered && !_hasMoved && !_isDragging && _longPressedItem != null) {
      final itemToShow = _longPressedItem!;
      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted) {
          widget.onShowItemOptions(itemToShow);
        }
      });
    }

    _cleanup();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _cleanup();
  }

  void _cleanup() {
    _longPressTimer?.cancel();
    _longPressTriggered = false;
    _longPressedItem = null;
    _isDragging = false;
    _hasMoved = false;
    _startPosition = null;
  }

  void _handleTap(Map<String, dynamic> item) {
    if (!_longPressTriggered && !_hasMoved) {
      widget.onToggleEditing(item['id'], item['content']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            scrollController: widget.scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: _localItems.length,
            onReorder: (oldIndex, newIndex) {
              print("Reorder: oldIndex=$oldIndex, newIndex=$newIndex");

              _isDragging = true;
              _cleanup();

              if (oldIndex < newIndex) {
                newIndex -= 1;
              }

              HapticFeedback.lightImpact();

              final item = _localItems[oldIndex];

              // Обновляем локальные элементы
              setState(() {
                final movedItem = _localItems.removeAt(oldIndex);
                _localItems.insert(newIndex, movedItem);
              });

              widget.onReorderFinished(item, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final item = _localItems[index];
              final String itemId = item['id'];
              final bool isEditing = widget.editingItems[itemId] ?? false;

              return _buildAnimatedTaskItem(
                itemId,
                item,
                isEditing,
                index,
                key: ValueKey(itemId),
              );
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final double scale = animation.value * 0.05 + 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTaskItem(
    String itemId,
    Map<String, dynamic> item,
    bool isEditing,
    int index, {
    required Key key,
  }) {
    // Определяем тип анимации на основе состояния элемента
    AnimationType? animationType;

    bool isAppearing = item['isAppearing'] == true;
    bool isDisappearing = item['isDisappearing'] == true;
    bool isUpdating = item['isUpdating'] == true;
    bool isReordering = item['isReordering'] == true;

    print("🎭 _buildAnimatedTaskItem для $itemId: appearing=$isAppearing, disappearing=$isDisappearing, updating=$isUpdating, reordering=$isReordering");

    if (isAppearing) {
      animationType = AnimationType.add;
    } else if (isDisappearing) {
      animationType = AnimationType.remove;
    } else if (isUpdating) {
      animationType = AnimationType.update;
    } else if (isReordering) {
      animationType = AnimationType.reorder;
      print("🎯 Элемент $itemId помечен для reorder анимации");
    }

    Widget itemContent = _buildTaskItem(itemId, item, isEditing, index);

    // УЛУЧШЕННАЯ ЛОГИКА: Применяем reorder анимацию напрямую
    if (isReordering && _reorderAnimations.containsKey(itemId)) {
      print("🎨 Применяем reorder анимацию для $itemId");
      itemContent = AnimatedBuilder(
        animation: _reorderAnimations[itemId]!,
        builder: (context, child) {
          double opacity = 0.7 + (_reorderAnimations[itemId]!.value * 0.3);
          double scale = 0.98 + (_reorderAnimations[itemId]!.value * 0.04);
          print("🎨 Reorder анимация $itemId: opacity=$opacity, scale=$scale");
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2), // Отладочная граница
                  borderRadius: BorderRadius.circular(8),
                ),
                child: child,
              ),
            ),
          );
        },
        child: itemContent,
      );
    } else if (isReordering) {
      print("⚠️ Элемент $itemId помечен как reordering, но нет контроллера анимации");
    }

    return Container(
      key: key,
      child: AnimatedTaskItemWidget(
        itemId: itemId,
        item: item,
        isEditing: isEditing,
        animationType: animationType,
        onAnimationComplete: () {
          print("🏁 Анимация завершена для $itemId");
          // Убираем флаги после завершения анимации
          if (mounted) {
            setState(() {
              final index = _localItems.indexWhere((i) => i['id'] == itemId);
              if (index != -1) {
                _localItems[index].remove('isAppearing');
                _localItems[index].remove('isDisappearing');
                _localItems[index].remove('isUpdating');
                // НЕ убираем isReordering здесь, это делается в _animateReorderChange
              }
            });
          }
        },
        child: itemContent,
      ),
    );
  }

  Widget _buildTaskItem(
    String itemId,
    Map<String, dynamic> item,
    bool isEditing,
    int index,
  ) {
    // Получение данных назначенного пользователя
    Map<String, dynamic>? assignedUser;
    if (item['assigned_to'] != null) {
      assignedUser = widget.usersCache[item['assigned_to']];

      if (assignedUser == null) {
        widget.getCachedUserById(item['assigned_to']);
      }
    }

    final String type = item['type'] as String;
    final bool hasDeadline = item['deadline'] != null;
    final bool isTemporary = item['isTemporary'] == true;

    // Определяем цвет фона элемента в зависимости от дедлайна
    Color containerColor = Theme.of(context).cardColor;
    Color borderColor = Colors.transparent;

    if (hasDeadline) {
      final deadlineColor = widget.getDeadlineColor(item['deadline']);
      containerColor = deadlineColor.withOpacity(0.05);
      borderColor = deadlineColor.withOpacity(0.3);
    }

    // Основной контент элемента
    Widget itemContent = _buildItemContent(item, isEditing, type);

    // Создаем полный виджет элемента
    Widget fullItem = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Строка с дедлайном и назначенным пользователем
        if ((hasDeadline || assignedUser != null) && !isEditing)
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasDeadline)
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: widget.getDeadlineColor(item['deadline']),
                            ),
                            SizedBox(width: 4),
                            Text(
                              widget.formatDeadline(item['deadline']),
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.isDeadlineExpired(item['deadline'])
                                    ? Colors.red
                                    : widget.getDeadlineColor(item['deadline']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  SizedBox.shrink(),

                // Назначенный пользователь
                if (assignedUser != null)
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: _buildAssignedUserAvatar(assignedUser!),
                      );
                    },
                  ),
              ],
            ),
          ),

        // Основной контейнер элемента
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            top: index == 0 && !hasDeadline ? 4.0 : 0.0,
            bottom: 4.0,
          ),
          decoration: BoxDecoration(
            color: isTemporary
                ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                : containerColor,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
            border: hasDeadline ? Border.all(color: borderColor, width: 1.5) : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: itemContent,
            ),
          ),
        ),
      ],
    );

    // Обработка событий для разных типов элементов
    Widget finalWidget;

    if (widget.canEdit) {
      if (type == 'checklist') {
        finalWidget = Stack(
          children: [
            fullItem,
            Positioned(
              left: 80,
              right: 0,
              top: 0,
              bottom: 0,
              child: Listener(
                onPointerDown: (event) => _handlePointerDown(event, item),
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerUp,
                onPointerCancel: _handlePointerCancel,
                child: GestureDetector(
                  onTap: () => _handleTap(item),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ],
        );
      } else {
        finalWidget = Listener(
          onPointerDown: (event) => _handlePointerDown(event, item),
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: GestureDetector(
            onTap: () => _handleTap(item),
            child: fullItem,
          ),
        );
      }
    } else {
      finalWidget = fullItem;
    }

    return finalWidget;
  }

  Widget _buildItemContent(Map<String, dynamic> item, bool isEditing, String type) {
    if (isEditing) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(4.0),
        child: TextField(
          controller: widget.itemControllers[item['id']],
          focusNode: widget.itemFocusNodes[item['id']],
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterTextHint,
            suffixIcon: item['isSaving'] == true
                ? Container(
                    width: 24,
                    height: 24,
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
          maxLines: null,
          autofocus: true,
        ),
      );
    }

    switch (type) {
      case 'header':
        return AnimatedContentChange(
          content: item['content'],
          builder: (content) => AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );

      case 'note':
        return AnimatedContentChange(
          content: item['content'],
          builder: (content) => Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: Text(
              content,
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ),
        );

      case 'checklist':
        return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => widget.onCheckChanged(item['id'], !(item['checked'] ?? false)),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: (item['checked'] ?? false)
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      width: 2,
                    ),
                    color: (item['checked'] ?? false)
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: (item['checked'] ?? false)
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                            key: ValueKey('checked'),
                          )
                        : SizedBox.shrink(key: ValueKey('unchecked')),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedStyleTransition(
                style: TextStyle(
                  fontSize: 16.0,
                  decoration: (item['checked'] ?? false)
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: (item['checked'] ?? false)
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                      : Theme.of(context).colorScheme.onSurface,
                ),
                child: AnimatedContentChange(
                  content: item['content'],
                  builder: (content) => Text(content),
                ),
              ),
            ),
            if (item['isSaving'] == true)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        );

      default:
        return AnimatedContentChange(
          content: item['content'],
          builder: (content) => Text(
            content,
            style: const TextStyle(fontSize: 16.0),
          ),
        );
    }
  }

  Widget _buildAssignedUserAvatar(Map<String, dynamic> assignedUser) {
    final userId = assignedUser['id'];
    final login = assignedUser['login'] ?? '';

    Widget avatarWidget = AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
        border: widget.onNavigateToProfile != null
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: assignedUser['avatar_url'] != null
                ? CircleAvatar(
                    key: ValueKey('avatar_${userId}'),
                    radius: 10,
                    backgroundImage: NetworkImage(assignedUser['avatar_url']),
                  )
                : CircleAvatar(
                    key: ValueKey('initials_${userId}'),
                    radius: 10,
                    backgroundColor: widget.getAvatarColor(userId),
                    child: Text(
                      login.isNotEmpty ? login[0].toUpperCase() : '',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
          ),
          SizedBox(width: 4),
          AnimatedDefaultTextStyle(
            duration: Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            child: Text(
              login.isEmpty ? 'User' : login,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (widget.onNavigateToProfile != null) {
      return GestureDetector(
        onTap: () {
          widget.onNavigateToProfile!(userId);
        },
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  void animateItemRemoval(String itemId, VoidCallback onComplete) {
    _animateItemRemoval(itemId, onComplete);
  }

  void animateItemChange(String itemId) {
    _animateItemChange(itemId);
  }
}