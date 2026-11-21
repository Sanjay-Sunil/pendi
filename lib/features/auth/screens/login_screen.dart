import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/wordmark.dart';
import '../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _pending = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await ref.read(authRepoProvider).signIn();
    } catch (e) {
      if (mounted) setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(Tokens.pagePadPhone),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Wordmark(height: 40),
                  const SizedBox(height: 24),
                  Text(
                    'A calm start to every day.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reading, practice, work, and classes in one quiet place.',
                    style: TextStyle(color: c.muted),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: _pending ? 'Signing in…' : 'Continue with Google',
                    onPressed: _pending ? null : _signIn,
                    expand: true,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(_error!, style: TextStyle(color: c.danger)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
