import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/dates.dart';
import '../../../integrations/sitemap.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_input.dart';
import '../providers.dart';
import 'page_picker.dart';

String _host(String url) =>
    Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? '';

/// Link + days → find pages → pick and reorder → create.
class AddSourceForm extends ConsumerStatefulWidget {
  const AddSourceForm({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  ConsumerState<AddSourceForm> createState() => _AddSourceFormState();
}

class _AddSourceFormState extends ConsumerState<AddSourceForm> {
  late final _url = TextEditingController(text: widget.initialUrl);
  final _title = TextEditingController();
  final _days = TextEditingController(text: '30');
  List<PickablePage>? _pages;
  String? _message;
  bool _pending = false;

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    setState(() {
      _pending = true;
      _message = null;
    });
    final url = _url.text.trim();
    try {
      final found = await ref.read(pageExtractorProvider).extract(url);
      _pages = [for (final p in found) PickablePage(p.title, p.url)];
    } on ExtractError catch (e) {
      if (e.code == ExtractErrorCode.invalidUrl) {
        _message = e.message;
      } else {
        // A page with no section list becomes a single item.
        _pages = [PickablePage(_host(url).isEmpty ? url : _host(url), url)];
        _message = '${e.message}. Added the link as a single page.';
      }
    }
    if (_title.text.isEmpty) _title.text = _host(url);
    if (mounted) setState(() => _pending = false);
  }

  Future<void> _create() async {
    final picked = _pages!.where((p) => p.selected).toList();
    setState(() => _pending = true);
    final repo = await ref.read(readingRepoProvider.future);
    final res = await repo.createSource(
      title: _title.text.isEmpty ? _host(_url.text) : _title.text,
      url: _url.text.trim(),
      kind: picked.length > 1 ? 'course' : 'blog',
      startDate: todayLocal(ref.read(clockProvider)()),
      targetDays: _days.text,
      pages: [for (final p in picked) (title: p.title, url: p.url)],
    );
    if (!mounted) return;
    setState(() => _pending = false);
    if (!res.isOk) {
      setState(() => _message = res.errorOrNull);
      return;
    }
    ref.invalidate(readingOverviewProvider);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Added ${picked.length} page${picked.length == 1 ? '' : 's'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final picked = _pages?.where((p) => p.selected).length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInput(
          label: 'Link',
          controller: _url,
          hint: 'https://course.dev/',
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() => _pages = null),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppInput(
                label: 'Title',
                controller: _title,
                hint: 'Optional',
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 96,
              child: AppInput(
                label: 'Days',
                controller: _days,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              _message!,
              style: TextStyle(color: context.colors.muted),
            ),
          ),
        ],
        if (_pages != null) ...[
          const SizedBox(height: 12),
          PagePicker(
            pages: _pages!,
            onChanged: (p) => setState(() => _pages = p),
          ),
        ],
        const SizedBox(height: 16),
        AppButton(
          expand: true,
          label: _pending
              ? 'Working…'
              : _pages == null
              ? 'Find pages'
              : 'Add $picked pages',
          onPressed: _pending || (_pages != null && picked == 0)
              ? null
              : (_pages == null ? _find : _create),
        ),
      ],
    );
  }
}
