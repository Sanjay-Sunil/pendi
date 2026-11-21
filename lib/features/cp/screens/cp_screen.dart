import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/page_scaffold.dart';
import '../providers.dart';
import '../widgets/lists_section.dart';

class CpScreen extends ConsumerWidget {
  const CpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: 'CP',
      label: 'Practice',
      onRefresh: () => ref.refresh(cpListsProvider.future),
      children: const [ListsSection()],
    );
  }
}
