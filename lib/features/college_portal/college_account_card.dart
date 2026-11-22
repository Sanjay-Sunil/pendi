import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../ui/app_button.dart';
import '../../ui/app_card.dart';
import '../../ui/app_input.dart';
import 'providers.dart';

/// Settings card for the IIIT Kottayam attendance portal login.
class CollegeAccountCard extends ConsumerStatefulWidget {
  const CollegeAccountCard({super.key});

  @override
  ConsumerState<CollegeAccountCard> createState() => _CollegeAccountCardState();
}

class _CollegeAccountCardState extends ConsumerState<CollegeAccountCard> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ok = await ref
        .read(collegePortalProvider.notifier)
        .connect(_email.text, _password.text);
    if (ok) _password.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ref.watch(collegePortalProvider).value ?? const PortalState();
    final muted = TextStyle(color: c.muted, fontSize: 13);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'IIIT Kottayam attendance portal',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Your login is stored only on this phone, encrypted.',
            style: muted,
          ),
          const SizedBox(height: 12),
          if (!s.connected) ...[
            AppInput(
              label: 'College email',
              controller: _email,
              hint: 'name@iiitkottayam.ac.in',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            Text(
              'Portal password',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _password,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(hintText: 'Password'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: s.busy ? 'Checking…' : 'Connect',
              expand: true,
              onPressed: s.busy ? null : _connect,
            ),
          ] else ...[
            Text(
              'Connected as ${s.email}',
              style: TextStyle(fontFamily: mono, fontSize: 12, color: c.text),
            ),
            if (s.summary != null) ...[
              const SizedBox(height: 8),
              for (final course in s.summary!.courses)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${course.code} · ${course.present}/${course.total}',
                    style: TextStyle(
                      fontFamily: mono,
                      fontSize: 12,
                      color: c.muted,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                AppButton(
                  label: s.busy ? 'Syncing…' : 'Sync now',
                  small: true,
                  variant: ButtonVariant.secondary,
                  onPressed: s.busy
                      ? null
                      : () =>
                            ref.read(collegePortalProvider.notifier).refresh(),
                ),
                const Spacer(),
                AppButton(
                  label: 'Disconnect',
                  small: true,
                  variant: ButtonVariant.danger,
                  onPressed: () =>
                      ref.read(collegePortalProvider.notifier).disconnect(),
                ),
              ],
            ),
          ],
          if (s.error != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(s.error!, style: TextStyle(color: c.danger)),
            ),
          ],
        ],
      ),
    );
  }
}
