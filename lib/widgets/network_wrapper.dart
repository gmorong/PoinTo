// lib/widgets/network_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pointo/services/network_service.dart';
import 'package:pointo/widgets/network_error_screen.dart';

class NetworkWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const NetworkWrapper({
    Key? key,
    required this.child,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, _) {
        if (networkService.hasError) {
          return NetworkErrorScreen(
            onRetry: onRetry,
            // ИСПРАВЛЕНО: добавлена проверка на null
            customMessage: networkService.errorMessage ?? 'Произошла ошибка',
          );
        }
        
        return child;
      },
    );
  }
}