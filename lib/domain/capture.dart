enum CaptureKind { inbox, researchTask, collegeTask, readingLink }

typedef ParsedCapture = ({CaptureKind kind, String body});

/// `r: …` research task, `c: …` college task, `l: <url>` reading link, else inbox.
ParsedCapture parseCapture(String input) {
  final text = input.trim();
  final m = RegExp(
    r'^([rcl])\s*:\s*(.*)$',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(text);
  if (m == null) return (kind: CaptureKind.inbox, body: text);
  final body = m.group(2)!.trim();
  return switch (m.group(1)!.toLowerCase()) {
    'r' => (kind: CaptureKind.researchTask, body: body),
    'c' => (kind: CaptureKind.collegeTask, body: body),
    _ => (kind: CaptureKind.readingLink, body: body),
  };
}
