import 'package:flutter/material.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';

/// Виджет для отображения элемента задачи с учетом прав доступа
class TaskItemWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final Animation<double> itemAnimation;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool isFirst;
  final bool inDrag;
  final Animation<double> dragAnimation;
  final VoidCallback? onToggleEditing; // Может быть null если нет прав
  final VoidCallback? onSave; // Может быть null если нет прав
  final VoidCallback? onShowOptions; // Может быть null если нет прав
  final VoidCallback? onLongPressStart; // Может быть null если нет прав
  final Function(LongPressMoveUpdateDetails)?
      onLongPressMove; // Может быть null если нет прав
  final String Function(String?) formatDeadline;
  final bool Function(String?) isDeadlineExpired;
  final Color Function(String?) getDeadlineColor;
  final Function(bool?)?
      onCheckChanged; // Может быть null если нет прав на редактирование
  final Map<String, dynamic>? assignedUser;
  final Color Function(String) getAvatarColor;

  const TaskItemWidget({
    Key? key,
    required this.item,
    required this.itemAnimation,
    required this.isEditing,
    required this.isSaving,
    this.controller,
    this.focusNode,
    this.isFirst = false,
    required this.inDrag,
    required this.dragAnimation,
    this.onToggleEditing,
    this.onSave,
    this.onShowOptions,
    this.onLongPressStart,
    this.onLongPressMove,
    required this.formatDeadline,
    required this.isDeadlineExpired,
    required this.getDeadlineColor,
    this.onCheckChanged,
    this.assignedUser,
    required this.getAvatarColor,
  }) : super(key: key);

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget> {
  @override
  Widget build(BuildContext context) {
    // Определяем, есть ли у пользователя права редактирования
    final bool canEdit = widget.onToggleEditing != null;

    // ignore: unused_local_variable
    final String itemId = widget.item['id'];
    final String type = widget.item['type'] as String;
    final bool hasDeadline = widget.item['deadline'] != null;
    final bool isTemporary = widget.item['isTemporary'] == true;

    // Определяем цвет фона элемента в зависимости от дедлайна
    Color containerColor = Theme.of(context).cardColor;
    Color borderColor = Colors.transparent;

    if (hasDeadline) {
      final deadlineColor = widget.getDeadlineColor(widget.item['deadline']);
      containerColor = deadlineColor.withOpacity(0.05);
      borderColor = deadlineColor.withOpacity(0.3);
    }

    // Функция для создания виджета аватара пользователя
    Widget buildAssignedUserAvatar() {
      if (widget.assignedUser == null) {
        return SizedBox.shrink();
      }

      final userId = widget.assignedUser!['id'];
      final login = widget.assignedUser!['login'] ?? '';

      return Container(
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
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.assignedUser!['avatar_url'] != null)
              CircleAvatar(
                radius: 10,
                backgroundImage: NetworkImage(widget.assignedUser!['avatar_url']),
              )
            else
              CircleAvatar(
                radius: 10,
                backgroundColor: widget.getAvatarColor(userId),
                child: Text(
                  login.isNotEmpty ? login[0].toUpperCase() : '',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            SizedBox(width: 4),
            Text(
              login.isEmpty ? 'User' : login,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // Функция для создания TextField в режиме редактирования
    Widget buildEditingField() {
      return TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterTextHint,
          suffixIcon: widget.isSaving
              ? Container(
                  width: 24,
                  height: 24,
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        maxLines: null,
        autofocus: true,
      );
    }

    // Создание основного контента элемента
    Widget buildItemContent() {
      if (widget.isEditing) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(4.0),
          child: buildEditingField(),
        );
      }

      switch (type) {
        case 'header':
          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: widget.isFirst
                ? const EdgeInsets.only(top: 16.0)
                : const EdgeInsets.only(top: 24.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  widget.item['content'],
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );

        case 'note':
          return Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: Text(
              widget.item['content'],
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          );

        case 'checklist':
          return Row(
            children: [
              // Отдельный контейнер для чекбокса с собственным GestureDetector
              Container(
                width: 40, // Увеличиваем область нажатия
                height: 40,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: widget.onCheckChanged != null
                      ? () => widget.onCheckChanged!(!(widget.item['checked'] ?? false))
                      : null,
                  child: Transform.scale(
                    scale: 1.2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: (widget.item['checked'] ?? false)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          width: 2,
                        ),
                        color: (widget.item['checked'] ?? false)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: (widget.item['checked'] ?? false)
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.item['content'],
                  style: TextStyle(
                    fontSize: 16.0,
                    decoration: (widget.item['checked'] ?? false)
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: (widget.item['checked'] ?? false)
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (widget.isSaving)
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
          return Text(
            widget.item['content'],
            style: const TextStyle(fontSize: 16.0),
          );
      }
    }

    // Создание полного контента элемента
    Widget itemContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Строка с дедлайном и назначенным пользователем
        if ((hasDeadline || widget.assignedUser != null) && !widget.isEditing)
          Padding(
            padding: const EdgeInsets.only(
                top: 8.0, bottom: 4.0, left: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasDeadline)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: widget.getDeadlineColor(widget.item['deadline']),
                      ),
                      SizedBox(width: 4),
                      Text(
                        widget.formatDeadline(widget.item['deadline']),
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDeadlineExpired(widget.item['deadline'])
                              ? Colors.red
                              : widget.getDeadlineColor(widget.item['deadline']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox.shrink(),

                // Назначенный пользователь
                if (widget.assignedUser != null) buildAssignedUserAvatar(),
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
            top: widget.isFirst && !hasDeadline ? 4.0 : 0.0,
            bottom: 4.0,
          ),
          decoration: BoxDecoration(
            color: isTemporary
                ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                : widget.inDrag
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
                    : containerColor,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.inDrag ? 0.2 : 0.05),
                blurRadius: widget.inDrag ? 8 : 2,
                offset: Offset(0, widget.inDrag ? 4 : 1),
              ),
            ],
            border:
                hasDeadline ? Border.all(color: borderColor, width: 1.5) : null,
          ),
          child: Material(
            color: Colors.transparent,
            elevation: widget.dragAnimation.value * 8,
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: buildItemContent(),
            ),
          ),
        ),
      ],
    );

    // ПРОСТОЕ РЕШЕНИЕ: Убираем весь кастомный GestureDetector, используем только стандартные события
    if (canEdit) {
      // Для чеклистов оборачиваем только текстовую часть
      if (type == 'checklist') {
        return Stack(
          children: [
            itemContent,
            // Только для текстовой области чеклиста
            Positioned(
              left: 40,
              right: 0, 
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: widget.onToggleEditing,
                onLongPress: widget.onShowOptions,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        );
      } else {
        // Для остальных элементов - простой GestureDetector поверх всего
        return GestureDetector(
          onTap: widget.onToggleEditing,
          onLongPress: widget.onShowOptions,
          child: itemContent,
        );
      }
    } else {
      // Для элементов без прав редактирования
      return itemContent;
    }
  }
}