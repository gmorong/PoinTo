// ignore_for_file: unused_field

import 'package:flutter/material.dart';

class PersistentBottomBarScaffold extends StatefulWidget {
  final List<PersistentTabItem> items;

  const PersistentBottomBarScaffold({Key? key, required this.items})
      : super(key: key);

  @override
  _PersistentBottomBarScaffoldState createState() =>
      _PersistentBottomBarScaffoldState();
}

class _PersistentBottomBarScaffoldState
    extends State<PersistentBottomBarScaffold> {
  int _selectedTab = 1;

  DateTime? _lastTapTime;

  // Создаем страницы как виджеты без навигатора
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Инициализируем страницы напрямую
    _pages = widget.items.map((item) => item.tab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: widget.items.map((page) {
          // Каждому экземпляру навигатора нужен свой уникальный ключ
          return Navigator(
            key: page.navigatorkey ??
                GlobalKey<NavigatorState>(
                    debugLabel: 'nav-${widget.items.indexOf(page)}'),
            onGenerateInitialRoutes: (navigator, initialRoute) {
              // Создаем новый экземпляр экрана для каждого навигатора
              return [
                MaterialPageRoute(
                    builder: (context) => page.tab,
                    settings: const RouteSettings(name: '/'))
              ];
            },
          );
        }).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) {
          final now = DateTime.now();

          if (_selectedTab == index) {
            if (_lastTapTime != null &&
                now.difference(_lastTapTime!) < Duration(seconds: 2)) {
              // ДВОЙНОЙ ТАП по текущему табу
              final navKey = widget.items[index].navigatorkey;
              if (navKey?.currentState != null) {
                navKey!.currentState!.popUntil((route) => route.isFirst);
              }
            }
            _lastTapTime = now;
          } else {
            setState(() {
              _selectedTab = index;
            });
            _lastTapTime = now;
          }
        },
        items: widget.items
            .map((item) => BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Icon(item.icon),
                  ),
                  label: item.title,
                ))
            .toList(),
      ),
    );
  }
}

/// Model class that holds the tab info for the [PersistentBottomBarScaffold]
class PersistentTabItem {
  final Widget tab;
  final GlobalKey<NavigatorState>? navigatorkey;
  final String title;
  final IconData icon;

  PersistentTabItem(
      {required this.tab,
      this.navigatorkey,
      required this.title,
      required this.icon});
}
