import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// Универсальный wrapper для адаптивной ширины
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool centerOnDesktop;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.maxWidth,
    this.centerOnDesktop = true,
  }) : super(key: key);

  static bool get isDesktop => 
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Определяем максимальную ширину
    double effectiveMaxWidth;
    
    if (maxWidth != null) {
      effectiveMaxWidth = maxWidth!;
    } else if (isDesktop) {
      // Для десктопа: не больше 800px или 60% экрана
      effectiveMaxWidth = (screenWidth * 0.6).clamp(400.0, 800.0);
    } else {
      // Для мобильных: используем всю ширину
      effectiveMaxWidth = screenWidth;
    }

    // Если контент помещается без ограничений - возвращаем как есть
    if (screenWidth <= effectiveMaxWidth) {
      return child;
    }

    // Иначе центрируем и ограничиваем ширину
    return Center(
      child: Container(
        width: effectiveMaxWidth,
        child: child,
      ),
    );
  }
}

// Еще более простой вариант - Mixin для любого StatefulWidget
mixin ResponsiveMixin<T extends StatefulWidget> on State<T> {
  static bool get isDesktop => 
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  // Получить адаптивную ширину
  double getResponsiveWidth(BuildContext context, {double? maxWidth}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (maxWidth != null) {
      return maxWidth;
    }
    
    if (isDesktop) {
      return (screenWidth * 0.6).clamp(400.0, 800.0);
    }
    
    return screenWidth;
  }

  // Получить адаптивные отступы
  EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop) {
      final screenWidth = MediaQuery.of(context).size.width;
      final contentWidth = getResponsiveWidth(context);
      final horizontalPadding = (screenWidth - contentWidth) / 2;
      
      return EdgeInsets.symmetric(
        horizontal: horizontalPadding.clamp(0.0, double.infinity),
        vertical: 16.0,
      );
    }
    
    return const EdgeInsets.all(8.0);
  }
}

// Простое использование в любом экране:
class ExampleScreen extends StatefulWidget {
  @override
  _ExampleScreenState createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> with ResponsiveMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: getResponsivePadding(context),
        child: Container(
          width: getResponsiveWidth(context),
          child: Column(
            children: [
              // Ваш контент здесь
              Text("Этот контент будет адаптивным!"),
            ],
          ),
        ),
      ),
    );
  }
}