import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../auth/domain/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(context.loc('language')),
                    trailing: DropdownButton<Locale>(
                      underline: const SizedBox(),
                      value: settings.locale,
                      items: [
                        DropdownMenuItem(value: const Locale('ar'), child: Text(context.loc('arabic'))),
                        DropdownMenuItem(value: const Locale('en'), child: Text(context.loc('english'))),
                      ],
                      onChanged: (val) {
                        if (val != null) ref.read(settingsProvider.notifier).setLocale(val);
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: Text(context.loc('theme')),
                    trailing: DropdownButton<ThemeMode>(
                      underline: const SizedBox(),
                      value: settings.themeMode,
                      items: [
                        DropdownMenuItem(value: ThemeMode.system, child: Text(context.loc('theme'))),
                        DropdownMenuItem(value: ThemeMode.light, child: Text(context.loc('lightTheme'))),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text(context.loc('darkTheme'))),
                      ],
                      onChanged: (val) {
                        if (val != null) ref.read(settingsProvider.notifier).toggleTheme(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(context.loc('logout'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}
