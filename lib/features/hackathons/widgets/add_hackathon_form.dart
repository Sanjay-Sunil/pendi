import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_input.dart';
import '../providers.dart';

class AddHackathonForm extends ConsumerStatefulWidget {
  const AddHackathonForm({super.key});

  @override
  ConsumerState<AddHackathonForm> createState() => _AddHackathonFormState();
}

class _AddHackathonFormState extends ConsumerState<AddHackathonForm> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _theme = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _theme.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = await ref.read(hackathonRepoProvider.future);
    final res = await repo.create(
      name: _name.text,
      url: _url.text,
      theme: _theme.text,
    );
    if (!mounted) return;
    if (!res.isOk) return setState(() => _error = res.errorOrNull);
    ref.invalidate(hackathonsProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInput(
          label: 'Name',
          controller: _name,
          hint: 'Smart India Hackathon',
          autofocus: true,
        ),
        const SizedBox(height: 12),
        AppInput(
          label: 'Link',
          controller: _url,
          hint: 'Optional',
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        AppInput(label: 'Theme / track', controller: _theme, hint: 'Optional'),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: context.colors.danger)),
        ],
        const SizedBox(height: 16),
        AppButton(label: 'Add hackathon', expand: true, onPressed: _save),
      ],
    );
  }
}
