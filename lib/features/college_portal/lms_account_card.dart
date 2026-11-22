import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dates.dart';
import '../../integrations/iiitk/moodle_client.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../ui/app_button.dart';
import '../../ui/app_card.dart';
import '../../ui/app_input.dart';
import 'providers.dart';

/// Settings card for Moodle (LMS): deadlines become college tasks.
class LmsAccountCard extends ConsumerStatefulWidget {
  const LmsAccountCard({super.key});

  @override
  ConsumerState<LmsAccountCard> createState() => _LmsAccountCardState();
}

class _LmsAccountCardState extends ConsumerState<LmsAccountCard> {
  final _host = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final portal = await ref.read(collegePortalProvider.future);
      if (mounted && _host.text.isEmpty) {
        _host.text = lmsHostForEmail(portal.email ?? '');
      }
    });
  }

  @override
  void dispose() {
    _host.dispose();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ref.watch(lmsAccountProvider).value ?? const LmsState();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Moodle (LMS)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Assignment and quiz deadlines become College tasks and Calendar events.',
            style: TextStyle(color: c.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (!s.connected) ...[
            AppInput(
              label: 'LMS address',
              controller: _host,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'LMS username',
              controller: _user,
              hint: 'Your Moodle username',
            ),
            const SizedBox(height: 12),
            Text('LMS password', style: Theme.of(context).textTheme.bodySmall),
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
              label: s.busy ? 'Checking…' : 'Connect Moodle',
              expand: true,
              onPressed: s.busy
                  ? null
                  : () async {
                      final ok = await ref
                          .read(lmsAccountProvider.notifier)
                          .connect(
                            _host.text.trim(),
                            _user.text,
                            _password.text,
                          );
                      if (ok) _password.clear();
                    },
            ),
          ] else ...[
            Text(
              '${s.username} · ${Uri.tryParse(s.host ?? '')?.host ?? ''}',
              style: TextStyle(fontFamily: mono, fontSize: 12, color: c.text),
            ),
            if (s.lastSync != null)
              Text(
                '${s.count} upcoming · synced ${formatTime(s.lastSync!)}',
                style: TextStyle(
                  fontFamily: mono,
                  fontSize: 12,
                  color: c.muted,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                AppButton(
                  label: s.busy ? 'Syncing…' : 'Sync now',
                  small: true,
                  variant: ButtonVariant.secondary,
                  onPressed: s.busy
                      ? null
                      : () => ref.read(lmsAccountProvider.notifier).refresh(),
                ),
                const Spacer(),
                AppButton(
                  label: 'Disconnect',
                  small: true,
                  variant: ButtonVariant.danger,
                  onPressed: () =>
                      ref.read(lmsAccountProvider.notifier).disconnect(),
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
