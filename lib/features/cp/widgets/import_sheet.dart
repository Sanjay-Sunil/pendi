import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/cp_import.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_input.dart';
import '../providers.dart';

class ImportListForm extends ConsumerStatefulWidget {
  const ImportListForm({super.key});

  @override
  ConsumerState<ImportListForm> createState() => _ImportListFormState();
}

class _ImportListFormState extends ConsumerState<ImportListForm> {
  final _name = TextEditingController();
  final _text = TextEditingController();
  ImportResult _parsed = const ImportResult([], []);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final repo = await ref.read(cpRepoProvider.future);
    final res = await repo.createList(
      _name.text,
      _parsed.problems,
      source: 'pasted',
    );
    if (!mounted) return;
    if (!res.isOk) return setState(() => _error = res.errorOrNull);
    ref.invalidate(cpListsProvider);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Imported ${_parsed.problems.length} problems')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final errs = _parsed.errors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInput(
          label: 'List name',
          controller: _name,
          hint: 'TLE Eliminators · Level 1',
        ),
        const SizedBox(height: 12),
        AppInput(
          label: 'Problems',
          controller: _text,
          maxLines: 8,
          minLines: 5,
          hint:
              'One per line: Codeforces URL, 1950,B or 1950B. JSON also works.',
          onChanged: (t) => setState(() => _parsed = parseProblemList(t)),
        ),
        const SizedBox(height: 8),
        Text(
          '${_parsed.problems.length} problems found'
          '${errs.isEmpty ? '' : ' · ${errs.length} skipped'}',
          style: TextStyle(color: c.muted),
        ),
        for (final e in errs.take(5))
          Text(
            'Line ${e.line}: ${e.reason} (${e.text})',
            style: TextStyle(color: c.danger, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        if (_error != null) Text(_error!, style: TextStyle(color: c.danger)),
        const SizedBox(height: 16),
        AppButton(
          label: 'Import ${_parsed.problems.length} problems',
          expand: true,
          onPressed: _parsed.problems.isEmpty ? null : _create,
        ),
      ],
    );
  }
}
