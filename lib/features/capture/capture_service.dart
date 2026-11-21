import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';
import '../../data/models/college.dart';
import '../../data/providers.dart';
import '../../domain/capture.dart';
import '../../domain/dates.dart';
import '../college/providers.dart';
import '../reading/providers.dart';
import '../research/providers.dart';
import '../today/providers.dart';

/// Routes a capture to the right place. Returns a confirmation message.
Future<Result<String>> capture(Ref ref, String input) async {
  final p = parseCapture(input);
  if (p.body.isEmpty) return const Err('Type something first');
  final Result<String> res;
  switch (p.kind) {
    case CaptureKind.inbox:
      final r = await (await ref.read(inboxRepoProvider.future)).add(p.body);
      res = r.isOk ? const Ok('Saved to inbox') : Err(r.errorOrNull!);
    case CaptureKind.researchTask:
      final r = await (await ref.read(researchRepoProvider.future))
          .addTask(p.body);
      res = r.isOk ? const Ok('Research task added') : Err(r.errorOrNull!);
    case CaptureKind.collegeTask:
      final r = await (await ref.read(collegeRepoProvider.future))
          .addTask(title: p.body, kind: CollegeKind.other);
      res = r.isOk ? const Ok('College task added') : Err(r.errorOrNull!);
    case CaptureKind.readingLink:
      final host = Uri.tryParse(p.body)?.host ?? '';
      final r = await (await ref.read(readingRepoProvider.future)).createSource(
        title: host.isEmpty ? p.body : host,
        url: p.body,
        kind: 'blog',
        startDate: todayLocal(ref.read(clockProvider)()),
        targetDays: 3,
        pages: [(title: host.isEmpty ? p.body : host, url: p.body)],
      );
      res = r.isOk ? const Ok('Link added to reading') : Err(r.errorOrNull!);
  }
  ref
    ..invalidate(inboxProvider)
    ..invalidate(researchTasksProvider)
    ..invalidate(collegeTasksProvider)
    ..invalidate(readingOverviewProvider)
    ..invalidate(todayProvider);
  return res;
}

/// Exposes [capture] to widgets.
final captureProvider = Provider<Future<Result<String>> Function(String)>(
  (ref) =>
      (input) => capture(ref, input),
);
