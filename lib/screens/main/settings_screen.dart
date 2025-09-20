import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';
import '../about_developer.dart';
import '../auth/change_password_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(themeNotifierProvider);
    final localeAsync = ref.watch(localeProvider);

    // Пока локаль не загружена — показываем прелоадер
    final locale = localeAsync.whenOrNull(data: (l) => l);
    if (locale == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool isDarkMode = notifier.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 1,
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ListView(
                  children: [
                    _SingleSection(
                      title: "",
                      children: [
                        _CustomListTile(
                          title: AppLocalizations.of(context)!.about_developer,
                          icon: Icons.assignment_ind_outlined,
                          onTapAction: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AboutDeveloperPage()),
                            );
                          },
                        ),
                      ],
                    ),
                    _SingleSection(
                      title: AppLocalizations.of(context)!.general,
                      children: [
                        _CustomListTile(
                          title: AppLocalizations.of(context)!.dark_mode,
                          icon: CupertinoIcons.moon,
                          trailing: CupertinoSwitch(
                            value: isDarkMode,
                            activeTrackColor: CupertinoColors.activeBlue,
                            onChanged: (bool value) {
                              notifier.toggleTheme(value);
                            },
                          ),
                        ),
                        _CustomListTile(
                          title: locale.languageCode == 'ru'
                              ? 'Язык: Русский'
                              : 'Language: English',
                          icon: Icons.language,
                          onTapAction: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                    AppLocalizations.of(context)!.selectLanguage),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RadioListTile<Locale>(
                                      title: const Text('English'),
                                      value: const Locale('en'),
                                      groupValue: locale,
                                      onChanged: (Locale? value) {
                                        if (value != null) {
                                          ref
                                              .read(localeProvider.notifier)
                                              .setLocale(value);
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                    RadioListTile<Locale>(
                                      title: const Text('Русский'),
                                      value: const Locale('ru'),
                                      groupValue: locale,
                                      onChanged: (Locale? value) {
                                        if (value != null) {
                                          ref
                                              .read(localeProvider.notifier)
                                              .setLocale(value);
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    _SingleSection(
                      title: AppLocalizations.of(context)!.profile,
                      children: [
                        _CustomListTile(
                          title: AppLocalizations.of(context)!.changePassword,
                          icon: Icons.lock_outline,
                          onTapAction: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordPage(),
                              ),
                            );
                          },
                        ),
                        _CustomListTileExit(
                          title: AppLocalizations.of(context)!.exit,
                          icon: Icons.logout,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _AppVersionWidget(packageInfo: _packageInfo),
        ],
      ),
    );
  }
}

 class _AppVersionWidget extends StatelessWidget {
  final PackageInfo packageInfo;

  const _AppVersionWidget({
    Key? key,
    required this.packageInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            '${packageInfo.appName}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '•',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'v${packageInfo.version}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTapAction;

  const _CustomListTile(
      {Key? key,
      required this.title,
      required this.icon,
      this.trailing,
      this.onTapAction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      trailing: trailing ?? const Icon(CupertinoIcons.forward, size: 18),
      onTap: onTapAction,
    );
  }
}

class _CustomListTileExit extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const _CustomListTileExit(
      // ignore: unused_element
      {Key? key,
      required this.title,
      required this.icon,
      // ignore: unused_element, unused_element_parameter
      this.trailing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        AppLocalizations.of(context)!.exit,
        style: TextStyle(color: Colors.redAccent),
      ),
      leading: Icon(icon),
      trailing: trailing,
      onTap: () async {
        try {
          await Supabase.instance.client.auth.signOut();
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/signin',
            (routes) => false,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .errorWhileExiting(e.toString())),
            ),
          );
          print('$e');
        }
      },
    );
  }
}

class _SingleSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SingleSection({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontSize: 16),
          ),
        ),
        Container(
          width: double.infinity,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}