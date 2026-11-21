import 'package:flutter/material.dart';

import 'daily_log.dart';
import 'task_inbox.dart';

class ResearchHub extends StatelessWidget {
  const ResearchHub({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [TaskInbox(), SizedBox(height: 32), DailyLog()],
    );
  }
}
