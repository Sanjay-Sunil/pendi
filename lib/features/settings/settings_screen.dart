import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/env.dart';
import '../../data/export.dart';
import '../../data/providers.dart';
import '../../data/repos/profile_repo.dart';
import '../../domain/dates.dart';
import '../../theme/theme_mode_provider.dart';
import '../../theme/tokens.dart';
import '../../ui/app_button.dart';
import '../../ui/app_card.dart';
import '../../ui/app_input.dart';
import '../../ui/page_scaffold.dart';
import '../../ui/section_label.dart';
import '../auth/providers.dart';

final _profileRepoProvider = FutureProvider<ProfileRepo>(
  (ref) async => ProfileRepo(await ref.watch(dbProvider.future)),
);

const commonZones = [
  'Asia/Kolkata', 'Asia/Dubai', 'Asia/Singapore', 'Asia/Tokyo', //
  'Europe/London',
  'Europe/Berlin',
  'America/New_York',
  'America/Los_Angeles',
  'UTC',
];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _handle = TextEditingController();
  String _zone = activeTimezone;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final p = await (await ref.read(_profileRepoProvider.future)).get();
      if (!mounted) return;
      _handle.text = p.cfHandle ?? '';
      setState(() => _zone = p.timezone);
    });
  }

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _saveProfile() async {
    final res = await (await ref.read(_profileRepoProvider.future))
        .update(timezone: _zone, cfHandle: _handle.text);
    if (res.isOk) activeTimezone = _zone;
    _toast(res.isOk ? 'Saved' : res.errorOrNull!);
  }

  Future<void> _export() async {
    final db = await ref.read(dbProvider.future);
    final json = await exportAll(db, ref.read(clockProvider)());
    final counts = validateExport(
      json,
    ); // never share an export that would not re-import
    final day = todayLocal(ref.read(clockProvider)());
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(json),
            mimeType: 'application/json',
            name: 'pendi-$day.json',
          ),
        ],
        fileNameOverrides: ['pendi-$day.json'],
        subject: 'Pendi export',
      ),
    );
    if (mounted) {
      _toast('Exported ${counts.values.fold<int>(0, (a, b) => a + b)} rows');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(),
      body: PageScaffold(
        title: 'Settings',
        maxWidth: Tokens.maxToday,
        children: [
          const SectionLabel('Theme'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Profile'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: commonZones.contains(_zone) ? _zone : null,
                  decoration: const InputDecoration(labelText: 'Timezone'),
                  items: [
                    for (final z in commonZones)
                      DropdownMenuItem(value: z, child: Text(z)),
                  ],
                  onChanged: (z) => setState(() => _zone = z ?? _zone),
                ),
                const SizedBox(height: 12),
                AppInput(
                  label: 'Codeforces handle',
                  controller: _handle,
                  hint: 'tourist',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Save',
                    small: true,
                    onPressed: _saveProfile,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Data'),
          const SizedBox(height: 8),
          AppButton(
            label: 'Export all data (JSON)',
            variant: ButtonVariant.secondary,
            onPressed: _export,
          ),
          if (!Env.isDemo) ...[
            const SizedBox(height: 24),
            AppButton(
              label: 'Sign out',
              variant: ButtonVariant.danger,
              onPressed: () => ref.read(authRepoProvider).signOut(),
            ),
          ],
        ],
      ),
    );
  }
}
