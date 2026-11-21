import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../ui/app_button.dart';
import '../../../ui/app_sheet.dart';
import 'daily_log.dart';
import 'library.dart';
import 'task_inbox.dart';
import 'weekly_summary_sheet.dart';

class ResearchHub extends StatelessWidget {
  const ResearchHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: 'Weekly summary',
            icon: LucideIcons.fileText,
            small: true,
            variant: ButtonVariant.ghost,
            onPressed: () => showAppSheet<void>(
              context,
              title: 'This week',
              child: const WeeklySummaryView(),
            ),
          ),
        ),
        const TaskInbox(),
        const SizedBox(height: 32),
        const DailyLog(),
        const SizedBox(height: 32),
        const LibrarySection(),
      ],
    );
  }
}
