import 'package:flutter/material.dart';
import './animation_manager.dart';

class AnimatedTaskItemWidget extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> item;
  final bool isEditing;
  final Widget child;
  final AnimationType? animationType;
  final VoidCallback? onAnimationComplete;

  const AnimatedTaskItemWidget({
    Key? key,
    required this.itemId,
    required this.item,
    required this.isEditing,
    required this.child,
    this.animationType,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AnimatedTaskItemWidget> createState() => _AnimatedTaskItemWidgetState();
}

class _AnimatedTaskItemWidgetState extends State<AnimatedTaskItemWidget>
    with TickerProviderStateMixin {
  late TaskItemAnimationManager _animationManager;
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;
  bool _didChangeDependencies = false;

  @override
  void initState() {
    super.initState();
    _animationManager = TaskItemAnimationManager();

    // Контроллер для эффекта подсветки при изменении
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Создаем анимации для элемента, если их нет
    if (!_animationManager.hasAnimationForItem(widget.itemId)) {
      _animationManager.createAnimationsForItem(
        widget.itemId,
        this,
        shouldAnimate: widget.animationType == AnimationType.add,
        animationType: widget.animationType ?? AnimationType.add,
      );
    }

    final controller = _animationManager.getController(widget.itemId);
    controller?.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (widget.onAnimationComplete != null) {
          widget.onAnimationComplete!();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Инициализируем анимацию подсветки только после того, как контекст готов
    if (!_didChangeDependencies) {
      _highlightAnimation = ColorTween(
        begin: Colors.transparent,
        end: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ).animate(CurvedAnimation(
        parent: _highlightController,
        curve: Curves.easeInOut,
      ));
      _didChangeDependencies = true;
    }
  }

  @override
  void didUpdateWidget(AnimatedTaskItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Проверяем изменения в элементе
    if (_hasItemChanged(oldWidget.item, widget.item)) {
      _triggerHighlightEffect();

      // Запускаем анимацию обновления через менеджер
      _animationManager.animateItemUpdate(
        widget.itemId,
        this,
        oldWidget.item,
        widget.item,
      );
    }

    // Обрабатываем тип анимации
    if (oldWidget.animationType != widget.animationType &&
        widget.animationType != null) {
      switch (widget.animationType!) {
        case AnimationType.add:
          _animationManager.animateItemAdd(widget.itemId, this);
          break;
        case AnimationType.remove:
          _animationManager.animateItemRemove(
            widget.itemId,
            this,
            widget.onAnimationComplete ?? () {},
          );
          break;
        case AnimationType.update:
          _animationManager.animateItemUpdate(
            widget.itemId,
            this,
            oldWidget.item,
            widget.item,
          );
          break;
        case AnimationType.reorder:
          // Анимация перестановки обрабатывается отдельно
          break;
      }
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    _animationManager.dispose();
    super.dispose();
  }

  bool _hasItemChanged(
      Map<String, dynamic> oldItem, Map<String, dynamic> newItem) {
    return oldItem['content'] != newItem['content'] ||
        oldItem['checked'] != newItem['checked'] ||
        oldItem['type'] != newItem['type'] ||
        oldItem['deadline'] != newItem['deadline'] ||
        oldItem['assigned_to'] != newItem['assigned_to'];
  }

  void _triggerHighlightEffect() {
    if (_didChangeDependencies) {
      _highlightController.forward().then((_) {
        _highlightController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = _animationManager.getScaleAnimation(widget.itemId);
    final fadeAnimation = _animationManager.getFadeAnimation(widget.itemId);
    final slideAnimation = _animationManager.getSlideAnimation(widget.itemId);

    if (scaleAnimation == null ||
        fadeAnimation == null ||
        slideAnimation == null) {
      // Fallback: возвращаем обычный виджет
      return widget.child;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        scaleAnimation,
        fadeAnimation,
        slideAnimation,
        if (_didChangeDependencies) _highlightAnimation,
      ]),
      builder: (context, child) {
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _didChangeDependencies
                      ? _highlightAnimation.value
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Вспомогательный виджет для анимации появления/исчезновения элементов списка
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;
  final VoidCallback? onRemoved;

  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.animation,
    this.onRemoved,
  }) : super(key: key);

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> {
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: widget.animation,
        curve: Curves.easeOut,
      )),
      child: FadeTransition(
        opacity: widget.animation,
        child: widget.child,
      ),
    );
  }
}

// Виджет для анимации изменения контента элемента
class AnimatedContentChange extends StatefulWidget {
  final String content;
  final Duration duration;
  final Widget Function(String content) builder;

  const AnimatedContentChange({
    Key? key,
    required this.content,
    required this.builder,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<AnimatedContentChange> createState() => _AnimatedContentChangeState();
}

class _AnimatedContentChangeState extends State<AnimatedContentChange>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  // ignore: unused_field
  String? _oldContent;
  String? _currentContent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _currentContent = widget.content;
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedContentChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.content != widget.content) {
      _oldContent = oldWidget.content;
      _currentContent = widget.content;

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: widget.builder(_currentContent ?? ''),
        );
      },
    );
  }
}

// Виджет для плавной анимации изменения цвета/стиля
class AnimatedStyleTransition extends StatefulWidget {
  final Widget child;
  final TextStyle style;
  final Duration duration;

  const AnimatedStyleTransition({
    Key? key,
    required this.child,
    required this.style,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<AnimatedStyleTransition> createState() =>
      _AnimatedStyleTransitionState();
}

class _AnimatedStyleTransitionState extends State<AnimatedStyleTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  TextStyle? _fromStyle;
  TextStyle? _toStyle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _toStyle = widget.style;
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedStyleTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.style != widget.style) {
      _fromStyle = oldWidget.style;
      _toStyle = widget.style;

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentStyle = _fromStyle != null
            ? TextStyle.lerp(_fromStyle, _toStyle, _controller.value)
            : _toStyle;

        return AnimatedDefaultTextStyle(
          style: currentStyle ?? const TextStyle(),
          duration: const Duration(milliseconds: 0),
          child: widget.child,
        );
      },
    );
  }
}