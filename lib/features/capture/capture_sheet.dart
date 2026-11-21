import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/capture.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../ui/app_button.dart';
import '../../ui/app_sheet.dart';
import 'capture_service.dart';

String _hint(CaptureKind k) => switch (k) {
  CaptureKind.inbox => 'Goes to inbox',
  CaptureKind.researchTask => 'Research task',
  CaptureKind.collegeTask => 'College task',
  CaptureKind.readingLink => 'Reading link (3 days)',
};

class CaptureForm extends ConsumerStatefulWidget {
  const CaptureForm({super.key});

  @override
  ConsumerState<CaptureForm> createState() => _CaptureFormState();
}

class _CaptureFormState extends ConsumerState<CaptureForm> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final res = await ref.read(captureProvider)(_ctrl.text);
    if (!mounted) return;
    if (!res.isOk) return setState(() => _error = res.errorOrNull);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(res.valueOrNull!)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final kind = parseCapture(_ctrl.text).kind;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Capture',
          child: TextField(
            key: const Key('capture-field'),
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.send,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Note, or r: / c: / l: …',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_hint(kind)} · r: research  c: college  l: link',
          style: TextStyle(fontFamily: mono, fontSize: 11, color: c.muted),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: c.danger)),
        const SizedBox(height: 12),
        AppButton(label: 'Save', expand: true, onPressed: _submit),
      ],
    );
  }
}

class CaptureFab extends StatelessWidget {
  const CaptureFab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FloatingActionButton(
      tooltip: 'Quick capture',
      backgroundColor: c.accent,
      foregroundColor: c.accentFg,
      elevation: 0,
      highlightElevation: 0,
      onPressed: () => showAppSheet<void>(
        context,
        title: 'Capture',
        child: const CaptureForm(),
      ),
      child: const Icon(LucideIcons.plus),
    );
  }
}
