import 'package:flutter/material.dart';
import '../widgets/app_bar/persistent_bottom_bar_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/main/settings_screen.dart';
import '../screens/main/task_screen.dart';
import '../screens/main/profile_screen.dart';

final GlobalKey<NavigatorState> navigatorKeyMain = GlobalKey<NavigatorState>();

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');
  final _tasksNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'tasks');
  final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');
  
  @override
  Widget build(BuildContext context) {
    return PersistentBottomBarScaffold(
      items: [
        PersistentTabItem(
          tab: SettingsPage(),
          icon: Icons.settings,
          title: '',
          navigatorkey: _settingsNavigatorKey,
        ),
        PersistentTabItem(
          tab: TaskListScreen(),
          icon: Icons.home,
          title: '',
          navigatorkey: _tasksNavigatorKey,
        ),
        PersistentTabItem(
          tab: ProfilePage(),
          icon: Icons.person,
          title: '',
          navigatorkey: _profileNavigatorKey,
        ),
      ],
    );
  }
}