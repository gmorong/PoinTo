import 'package:flutter/material.dart';

enum AnimationType { add, remove, update, reorder }

class ItemAnimation {
  final String itemId;
  final AnimationType type;
  final DateTime timestamp;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;

  ItemAnimation({
    required this.itemId,
    required this.type,
    required this.timestamp,
    this.oldData,
    this.newData,
  });
}

class TaskItemAnimationManager {
  static final TaskItemAnimationManager _instance =
      TaskItemAnimationManager._internal();

  factory TaskItemAnimationManager() => _instance;

  TaskItemAnimationManager._internal();

  final Map<String, AnimationController> _controllers = {};
  final Map<String, Animation<double>> _scaleAnimations = {};
  final Map<String, Animation<double>> _fadeAnimations = {};
  final Map<String, Animation<Offset>> _slideAnimations = {};
  final List<ItemAnimation> _animationQueue = [];

  bool _isProcessing = false;

  AnimationController? getController(String itemId) {
    return _controllers[itemId];
  }

  // Создание анимаций для элемента
  void createAnimationsForItem(
    String itemId,
    TickerProvider vsync, {
    bool shouldAnimate = false,
    AnimationType animationType = AnimationType.add,
  }) {
    if (_controllers.containsKey(itemId)) return;

    final controller = AnimationController(
      duration: _getDurationForAnimationType(animationType),
      vsync: vsync,
    );

    late Animation<double> scaleAnimation;
    late Animation<double> fadeAnimation;
    late Animation<Offset> slideAnimation;

    switch (animationType) {
      case AnimationType.add:
        scaleAnimation = Tween<double>(
          begin: shouldAnimate ? 0.8 : 1.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ));

        fadeAnimation = Tween<double>(
          begin: shouldAnimate ? 0.0 : 1.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ));

        slideAnimation = Tween<Offset>(
          begin: shouldAnimate ? const Offset(0.3, 0) : Offset.zero,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ));
        break;

      case AnimationType.remove:
        scaleAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInBack,
        ));

        fadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ));

        slideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.0, 0),
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInCubic,
        ));
        break;

      case AnimationType.update:
        scaleAnimation = Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.elasticInOut,
        ));

        fadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.9,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ));

        slideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.02, 0),
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.elasticInOut,
        ));
        break;

      case AnimationType.reorder:
        // УЛУЧШЕННАЯ АНИМАЦИЯ REORDER - простое fade out/in
        scaleAnimation = Tween<double>(
          begin: 1.0,
          end: 1.0, // Не изменяем размер
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ));

        fadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.3, // Делаем полупрозрачным
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ));

        slideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero, // Не двигаем элемент
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ));
        break;
    }

    _controllers[itemId] = controller;
    _scaleAnimations[itemId] = scaleAnimation;
    _fadeAnimations[itemId] = fadeAnimation;
    _slideAnimations[itemId] = slideAnimation;

    if (shouldAnimate) {
      if (animationType == AnimationType.update) {
        // Для обновлений делаем пульсацию
        controller.forward().then((_) {
          controller.reverse().then((_) {
            controller.forward();
          });
        });
      } else if (animationType == AnimationType.reorder) {
        // Для reorder - простое fade out -> fade in
        controller.forward().then((_) {
          controller.reverse();
        });
      } else {
        controller.forward();
      }
    } else {
      controller.value = 1.0;
    }
  }

  // УЛУЧШЕННАЯ АНИМАЦИЯ REORDER
  void animateItemReorder(
    String itemId,
    TickerProvider vsync,
  ) {
    _queueAnimation(ItemAnimation(
      itemId: itemId,
      type: AnimationType.reorder,
      timestamp: DateTime.now(),
    ));

    // Если уже есть контроллер, используем его
    if (_controllers.containsKey(itemId)) {
      // ignore: unused_local_variable
      final controller = _controllers[itemId]!;
      
      // Создаем временную анимацию fade
      final fadeController = AnimationController(
        duration: const Duration(milliseconds: 250),
        vsync: vsync,
      );
      
      final fadeAnimation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: fadeController,
        curve: Curves.easeInOut,
      ));
      
      // Заменяем fade анимацию временно
      final originalFade = _fadeAnimations[itemId];
      _fadeAnimations[itemId] = fadeAnimation;
      
      // Запускаем анимацию
      fadeController.forward().then((_) {
        fadeController.reverse().then((_) {
          // Восстанавливаем оригинальную анимацию
          _fadeAnimations[itemId] = originalFade!;
          fadeController.dispose();
        });
      });
    } else {
      // Создаем новую анимацию
      createAnimationsForItem(
        itemId,
        vsync,
        shouldAnimate: true,
        animationType: AnimationType.reorder,
      );
    }
  }

  // Получение длительности анимации для типа
  Duration _getDurationForAnimationType(AnimationType type) {
    switch (type) {
      case AnimationType.add:
        return const Duration(milliseconds: 400);
      case AnimationType.remove:
        return const Duration(milliseconds: 350);
      case AnimationType.update:
        return const Duration(milliseconds: 300);
      case AnimationType.reorder:
        return const Duration(milliseconds: 250); // Короче для reorder
    }
  }

  // Анимация добавления элемента
  void animateItemAdd(String itemId, TickerProvider vsync) {
    _queueAnimation(ItemAnimation(
      itemId: itemId,
      type: AnimationType.add,
      timestamp: DateTime.now(),
    ));

    createAnimationsForItem(
      itemId,
      vsync,
      shouldAnimate: true,
      animationType: AnimationType.add,
    );
  }

  // Анимация удаления элемента
  Future<void> animateItemRemove(
    String itemId,
    TickerProvider vsync,
    VoidCallback onComplete,
  ) async {
    _queueAnimation(ItemAnimation(
      itemId: itemId,
      type: AnimationType.remove,
      timestamp: DateTime.now(),
    ));

    createAnimationsForItem(
      itemId,
      vsync,
      shouldAnimate: true,
      animationType: AnimationType.remove,
    );

    final controller = _controllers[itemId];
    if (controller != null) {
      await controller.forward();
      onComplete();
      disposeAnimationsForItem(itemId);
    } else {
      onComplete();
    }
  }

  // Анимация изменения элемента
  void animateItemUpdate(
    String itemId,
    TickerProvider vsync,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  ) {
    _queueAnimation(ItemAnimation(
      itemId: itemId,
      type: AnimationType.update,
      timestamp: DateTime.now(),
      oldData: oldData,
      newData: newData,
    ));

    if (!_controllers.containsKey(itemId)) {
      createAnimationsForItem(itemId, vsync);
    }

    // Создаем новую анимацию обновления
    final controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    final pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticInOut,
    ));

    final oldController = _controllers[itemId];
    _scaleAnimations[itemId] = pulseAnimation;

    controller.forward().then((_) {
      controller.reverse().then((_) {
        controller.dispose();
        // Восстанавливаем обычную анимацию
        if (oldController != null) {
          _scaleAnimations[itemId] = Tween<double>(
            begin: 1.0,
            end: 1.0,
          ).animate(oldController);
        } else {
          createAnimationsForItem(itemId, vsync);
        }
      });
    });
  }

  // Получение анимаций для элемента
  Animation<double>? getScaleAnimation(String itemId) =>
      _scaleAnimations[itemId];
  Animation<double>? getFadeAnimation(String itemId) => _fadeAnimations[itemId];
  Animation<Offset>? getSlideAnimation(String itemId) =>
      _slideAnimations[itemId];

  // Добавление анимации в очередь
  void _queueAnimation(ItemAnimation animation) {
    _animationQueue.add(animation);
    if (!_isProcessing) {
      _processAnimationQueue();
    }
  }

  // Обработка очереди анимаций
  void _processAnimationQueue() {
    _isProcessing = true;

    // Группируем анимации по времени для синхронизации
    final now = DateTime.now();
    final recentAnimations = _animationQueue
        .where((anim) => now.difference(anim.timestamp).inMilliseconds < 100)
        .toList();

    if (recentAnimations.isNotEmpty) {
      // Обрабатываем группу анимаций
      for (final animation in recentAnimations) {
        _animationQueue.remove(animation);
      }
    }

    Future.delayed(const Duration(milliseconds: 50), () {
      if (_animationQueue.isNotEmpty) {
        _processAnimationQueue();
      } else {
        _isProcessing = false;
      }
    });
  }

  // Освобождение ресурсов для элемента
  void disposeAnimationsForItem(String itemId) {
    _controllers[itemId]?.dispose();
    _controllers.remove(itemId);
    _scaleAnimations.remove(itemId);
    _fadeAnimations.remove(itemId);
    _slideAnimations.remove(itemId);
  }

  // Освобождение всех ресурсов
  void disposeAll() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _scaleAnimations.clear();
    _fadeAnimations.clear();
    _slideAnimations.clear();
    _animationQueue.clear();
  }

  // Проверка наличия анимации для элемента
  bool hasAnimationForItem(String itemId) {
    return _controllers.containsKey(itemId);
  }

  // Получение статистики анимаций
  Map<String, dynamic> getAnimationStats() {
    return {
      'active_animations': _controllers.length,
      'queued_animations': _animationQueue.length,
      'is_processing': _isProcessing,
    };
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}