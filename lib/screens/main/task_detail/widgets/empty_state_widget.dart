import 'package:flutter/material.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';

/// Виджет для отображения пустого состояния (когда нет элементов)
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback? onAddItem;  // Теперь опциональный - null если нет прав

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