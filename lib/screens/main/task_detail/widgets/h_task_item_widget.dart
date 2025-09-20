import 'package:flutter/material.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';

/// Виджет для отображения элемента задачи с учетом прав доступа
class TaskItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool isFirst;
  final bool inDrag;
  final VoidCallback? onToggleEditing; // Может быть null если нет прав
  final VoidCallback? onSave; // Может быть null если нет прав
  final VoidCallback? onShowOptions; // Может быть null если нет прав
  final String Function(String?) formatDeadline;
  final bool Function(String?) isDeadlineExpired;
  final Color Function(String?) getDeadlineColor;
  final Function(bool?)? onCheckChanged; // Может быть null если нет прав на редактирование
  final Map<String, dynamic>? assignedUser;
  final Color Function(String) getAvatarColor;

  const TaskItemWidget({
    Key? key,
    required this.item,
    required this.isEditing,
    required this.isSaving,
    this.controller,
    this.focusNode,
    this.isFirst = false,
    required this.inDrag,
    this.onToggleEditing,
    this.onSave,
    this.onShowOptions,
    required this.formatDeadline,
    required this.isDeadlineExpired,
    required this.getDeadlineColor,
    this.onCheckChanged,
    this.assignedUser,
    required this.getAvatarColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Определяем, есть ли у пользователя права редактирования
    final bool canEdit = onToggleEditing != null;

    // ignore: unused_local_variable
    final String itemId = item['id'];
    final String type = item['type'] as String;
    final bool hasDeadline = item['deadline'] != null;
    final bool isTemporary = item['isTemporary'] == true;

    // Определяем цвет фона элемента в зависимости от дедлайна
    Color containerColor = Theme.of(context).cardColor;
    Color borderColor = Colors.transparent;

    if (hasDeadline) {
      final deadlineColor = getDeadlineColor(item['deadline']);
      // Используем основной цвет с низкой непрозрачностью для фона
      containerColor = deadlineColor.withOpacity(0.05);
      // И тот же цвет но с большей непрозрачностью для границы
      borderColor = deadlineColor.withOpacity(0.3);
    }

    // Подготовка виджета элемента в зависимости от типа и состояния редактирования
    Widget itemWidget;

    // Обновленная функция для создания виджета аватара пользователя
    Widget _buildAssignedUserAvatar() {
      if (assignedUser == null) {
        return SizedBox.shrink();
      }

      final userId = assignedUser!['id'];
      // Используем логин вместо имени и фамилии
      final login = assignedUser!['login'] ?? '';

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
            if (assignedUser!['avatar_url'] != null)
              CircleAvatar(
                radius: 10,
                backgroundImage: NetworkImage(assignedUser!['avatar_url']),
              )
            else
              CircleAvatar(
                radius: 10,
                backgroundColor: getAvatarColor(userId),
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
              login.isEmpty ? 'User' : login, // Отображаем логин
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
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterTextHint,
          suffixIcon: isSaving
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
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        maxLines: null,
        autofocus: true,
      );
    }

    // Определение виджета в зависимости от типа и состояния
    if (isEditing) {
      itemWidget = AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(4.0),
        child: buildEditingField(),
      );
    } else {
      switch (type) {
        case 'header':
          itemWidget = AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: isFirst
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
                  item['content'],
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
          break;

        case 'note':
          itemWidget = Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: Text(
              item['content'],
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          );
          break;

        case 'checklist':
          itemWidget = Row(
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: item['checked'] ?? false,
                  activeColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: onCheckChanged,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['content'],
                  style: TextStyle(
                    fontSize: 16.0,
                    decoration: (item['checked'] ?? false)
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: (item['checked'] ?? false)
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSaving)
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
          break;

        default:
          itemWidget = Text(
            item['content'],
            style: const TextStyle(fontSize: 16.0),
          );
      }
    }

    // Создание виджета с условной обработкой жестов в зависимости от прав
    Widget itemContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Добавляем строку с дедлайном и назначенным пользователем
        if ((hasDeadline || assignedUser != null) && !isEditing)
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
                        color: getDeadlineColor(item['deadline']),
                      ),
                      SizedBox(width: 4),
                      Text(
                        formatDeadline(item['deadline']),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDeadlineExpired(item['deadline'])
                              ? Colors.red
                              : getDeadlineColor(item['deadline']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox.shrink(),

                // Назначенный пользователь
                if (assignedUser != null) _buildAssignedUserAvatar(),
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
            top: isFirst && !hasDeadline ? 4.0 : 0.0,
            bottom: 4.0,
          ),
          decoration: BoxDecoration(
            color: isTemporary
                ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                : inDrag
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
                    : containerColor,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(inDrag ? 0.2 : 0.05),
                blurRadius: inDrag ? 8 : 2,
                offset: Offset(0, inDrag ? 4 : 1),
              ),
            ],
            border: hasDeadline ? Border.all(color: borderColor, width: 1.5) : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Основное содержимое элемента
                  itemWidget,
                ],
              ),
            ),
          ),
        ),
      ],
    );

    // Простое отображение без дополнительных оберток
    // drag_and_drop_lists сам управляет перетаскиванием
    if (type == 'checklist' && onCheckChanged != null && !canEdit) {
      // Для чеклиста без прав редактирования все еще разрешаем отмечать
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          onCheckChanged!(!item['checked']);
        },
        child: itemContent,
      );
    } else {
      // Для всех остальных случаев - просто отображаем содержимое
      return itemContent;
    }
  }
}






// import 'package:flutter/material.dart';
// import 'package:PoinTo/gen_l10n/app_localizations.dart';
// //import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
// import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';

// /// Виджет для отображения элемента задачи с учетом прав доступа
// class TaskItemWidget extends StatelessWidget {
//   final Map<String, dynamic> item;
//   final Animation<double> itemAnimation;
//   final bool isEditing;
//   final bool isSaving;
//   final TextEditingController? controller;
//   final FocusNode? focusNode;
//   final bool isFirst;
//   final bool inDrag;
//   final Animation<double> dragAnimation;
//   final VoidCallback? onToggleEditing; // Может быть null если нет прав
//   final VoidCallback? onSave; // Может быть null если нет прав
//   final VoidCallback? onShowOptions; // Может быть null если нет прав
//   final VoidCallback? onLongPressStart; // Может быть null если нет прав
//   final Function(LongPressMoveUpdateDetails)?
//       onLongPressMove; // Может быть null если нет прав
//   final String Function(String?) formatDeadline;
//   final bool Function(String?) isDeadlineExpired;
//   final Color Function(String?) getDeadlineColor;
//   final Function(bool?)?
//       onCheckChanged; // Может быть null если нет прав на редактирование
//   final Map<String, dynamic>? assignedUser;
//   final Color Function(String) getAvatarColor;

//   const TaskItemWidget({
//     Key? key,
//     required this.item,
//     required this.itemAnimation,
//     required this.isEditing,
//     required this.isSaving,
//     this.controller,
//     this.focusNode,
//     this.isFirst = false,
//     required this.inDrag,
//     required this.dragAnimation,
//     this.onToggleEditing,
//     this.onSave,
//     this.onShowOptions,
//     this.onLongPressStart,
//     this.onLongPressMove,
//     required this.formatDeadline,
//     required this.isDeadlineExpired,
//     required this.getDeadlineColor,
//     this.onCheckChanged,
//     this.assignedUser,
//     required this.getAvatarColor,
//   }) : super(key: key);

  

//   @override
//   Widget build(BuildContext context) {
//     // Определяем, есть ли у пользователя права редактирования
//     final bool canEdit = onToggleEditing != null;

//     // ignore: unused_local_variable
//     final String itemId = item['id'];
//     final String type = item['type'] as String;
//     final bool hasDeadline = item['deadline'] != null;
//     final bool isTemporary = item['isTemporary'] == true;

//     // Определяем цвет фона элемента в зависимости от дедлайна
//     Color containerColor = Theme.of(context).cardColor;
//     Color borderColor = Colors.transparent;

//     if (hasDeadline) {
//       final deadlineColor = getDeadlineColor(item['deadline']);
//       // Используем основной цвет с низкой непрозрачностью для фона
//       // ignore: deprecated_member_use
//       containerColor = deadlineColor.withOpacity(0.05);
//       // И тот же цвет но с большей непрозрачностью для границы
//       // ignore: deprecated_member_use
//       borderColor = deadlineColor.withOpacity(0.3);
//     }

//     // Подготовка виджета элемента в зависимости от типа и состояния редактирования
//     Widget itemWidget;

//     // Обновленная функция для создания виджета аватара пользователя
//     Widget _buildAssignedUserAvatar() {
//       if (assignedUser == null) {
//         return SizedBox.shrink();
//       }

//       final userId = assignedUser!['id'];
//       // Используем логин вместо имени и фамилии
//       final login = assignedUser!['login'] ?? '';

//       return Container(
//         padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.surface,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 1,
//               offset: Offset(0, 1),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (assignedUser!['avatar_url'] != null)
//               CircleAvatar(
//                 radius: 10,
//                 backgroundImage: NetworkImage(assignedUser!['avatar_url']),
//               )
//             else
//               CircleAvatar(
//                 radius: 10,
//                 backgroundColor: getAvatarColor(userId),
//                 child: Text(
//                   login.isNotEmpty ? login[0].toUpperCase() : '',
//                   style: TextStyle(
//                     fontSize: 8,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             SizedBox(width: 4),
//             Text(
//               login.isEmpty ? 'User' : login, // Отображаем логин
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w500,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       );
//     }

//     // Функция для создания TextField в режиме редактирования
//     Widget buildEditingField() {
//       return TextField(
//         controller: controller,
//         focusNode: focusNode,
//         decoration: InputDecoration(
//           hintText: AppLocalizations.of(context)!
//               .enterTextHint, // Убираем кнопку сохранения, показываем только индикатор загрузки при необходимости
//           suffixIcon: isSaving
//               ? Container(
//                   width: 24,
//                   height: 24,
//                   padding: EdgeInsets.all(8.0),
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//               : null,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide:
//                 BorderSide(color: Theme.of(context).colorScheme.primary),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(
//                 // ignore: deprecated_member_use
//                 color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(
//                 color: Theme.of(context).colorScheme.primary, width: 2),
//           ),
//         ),
//         maxLines: null,
//         autofocus: true,
//       );
//     }

//     // Определение виджета в зависимости от типа и состояния
//     if (isEditing) {
//       itemWidget = AnimatedContainer(
//         duration: Duration(milliseconds: 200),
//         curve: Curves.easeInOut,
//         padding: EdgeInsets.all(4.0),
//         child: buildEditingField(),
//       );
//     } else {
//       // Остальной код виджета без изменений
//       switch (type) {
//         case 'header':
//           itemWidget = AnimatedPadding(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//             padding: isFirst
//                 ? const EdgeInsets.only(top: 16.0)
//                 : const EdgeInsets.only(top: 24.0),
//             child: Container(
//               padding: const EdgeInsets.all(8.0),
//               decoration: BoxDecoration(
//                 // ignore: deprecated_member_use
//                 color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8.0),
//               ),
//               child: Center(
//                 child: Text(
//                   item['content'],
//                   style: TextStyle(
//                     fontSize: 22.0,
//                     fontWeight: FontWeight.bold,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//           );
//           break;

//         case 'note':
//           itemWidget = Container(
//             padding: const EdgeInsets.all(8.0),
//             alignment: Alignment.center,
//             child: Text(
//               item['content'],
//               style: TextStyle(fontSize: 16.0),
//               textAlign: TextAlign.center,
//             ),
//           );
//           break;

//         case 'checklist':
//           itemWidget = Row(
//             children: [
//               Transform.scale(
//                 scale: 1.2,
//                 child: Checkbox(
//                   value: item['checked'] ?? false,
//                   activeColor: Theme.of(context).colorScheme.primary,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   onChanged: onCheckChanged,
//                 ),
//               ),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   item['content'],
//                   style: TextStyle(
//                     fontSize: 16.0,
//                     decoration: (item['checked'] ?? false)
//                         ? TextDecoration.lineThrough
//                         : TextDecoration.none,
//                     color: (item['checked'] ?? false)
//                         // ignore: deprecated_member_use
//                         ? Theme.of(context)
//                             .colorScheme
//                             .onSurface
//                             .withOpacity(0.6)
//                         : Theme.of(context).colorScheme.onSurface,
//                   ),
//                 ),
//               ),
//               if (isSaving)
//                 Padding(
//                   padding: const EdgeInsets.only(right: 8.0),
//                   child: SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                 ),
//             ],
//           );
//           break;

//         default:
//           itemWidget = Text(
//             item['content'],
//             style: const TextStyle(fontSize: 16.0),
//           );
//       }
//     }

//     // Создание виджета с условной обработкой жестов в зависимости от прав
//     Widget itemContent = Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         // Добавляем строку с дедлайном и назначенным пользователем
//         if ((hasDeadline || assignedUser != null) && !isEditing)
//           Padding(
//             padding: const EdgeInsets.only(
//                 top: 8.0, bottom: 4.0, left: 16.0, right: 16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 if (hasDeadline)
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.calendar_today,
//                         size: 12,
//                         color: getDeadlineColor(item['deadline']),
//                       ),
//                       SizedBox(width: 4),
//                       Text(
//                         formatDeadline(item['deadline']),
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: isDeadlineExpired(item['deadline'])
//                               ? Colors.red
//                               : getDeadlineColor(item['deadline']),
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   )
//                 else
//                   SizedBox.shrink(),

//                 // Назначенный пользователь
//                 if (assignedUser != null) _buildAssignedUserAvatar(),
//               ],
//             ),
//           ),

//         // Основной контейнер элемента
//         AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeInOut,
//           margin: EdgeInsets.only(
//             left: 8.0,
//             right: 8.0,
//             top: isFirst && !hasDeadline
//                 ? 4.0
//                 : 0.0, // Убираем верхний отступ, если есть дедлайн
//             bottom: 4.0,
//           ),
//           decoration: BoxDecoration(
//             color: isTemporary
//                 // ignore: deprecated_member_use
//                 ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
//                 : inDrag
//                     // ignore: deprecated_member_use
//                     ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
//                     : containerColor, // Используем рассчитанный цвет фона
//             borderRadius: BorderRadius.circular(8.0),
//             boxShadow: [
//               BoxShadow(
//                 // ignore: deprecated_member_use
//                 color: Colors.black.withOpacity(inDrag ? 0.2 : 0.05),
//                 blurRadius: inDrag ? 8 : 2,
//                 offset: Offset(0, inDrag ? 4 : 1),
//               ),
//             ],
//             // Добавляем рамку, если есть дедлайн
//             border:
//                 hasDeadline ? Border.all(color: borderColor, width: 1.5) : null,
//           ),
//           child: Material(
//             color: Colors.transparent,
//             elevation: dragAnimation.value * 8,
//             borderRadius: BorderRadius.circular(8.0),
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Основное содержимое элемента
//                   itemWidget,
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );

//     // Обертываем в Handle только если есть права редактирования
//     if (canEdit) {
//       return Handle(
//         delay: const Duration(milliseconds: 100),
//         vibrate: true,
//         child: GestureDetector(
//           behavior: HitTestBehavior.opaque,
//           onTap: onToggleEditing,
//           onLongPress: onLongPressStart,
//           onLongPressMoveUpdate: onLongPressMove,
//           onLongPressEnd:
//               onShowOptions != null ? (_) => onShowOptions!() : null,
//           child: itemContent,
//         ),
//       );
//     } else {
//       // Без прав редактирования - просто отображаем содержимое
//       // Для чеклиста все еще разрешаем отмечать как выполненное
//       return GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: type == 'checklist' && onCheckChanged != null
//             ? () {
//                 // Инвертируем текущее состояние при тапе
//                 onCheckChanged!(!item['checked']);
//               }
//             : null,
//         child: itemContent,
//       );
//     }
//   }
// }