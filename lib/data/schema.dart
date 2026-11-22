/// Runtime copy of SQL defaults, unique keys and cascades from
/// `supabase/migrations/0001_init.sql`, used by the demo adapter.
library;

const tables = [
  'profiles',
  'reading_sources',
  'reading_items',
  'cp_lists',
  'cp_problems',
  'cp_daily', //
  'hackathons',
  'hackathon_milestones',
  'hackathon_tasks',
  'research_projects',
  'research_logs',
  'research_tasks',
  'research_papers',
  'research_ideas',
  'research_experiments',
  'courses',
  'college_tasks',
  'gcal_events_cache',
  'inbox',
  'habits',
  'habit_logs',
  'daily_notes',
];

const columnDefaults = <String, Map<String, Object?>>{
  'profiles': {
    'timezone': 'Asia/Kolkata',
    'cf_handle': null,
    'gcal_calendar_id': null,
  },
  'reading_sources': {'kind': 'course', 'status': 'active'},
  'reading_items': {'status': 'todo', 'done_at': null, 'note': null},
  'cp_lists': {'source': null, 'active': false},
  'cp_problems': {
    'name': null,
    'rating': null,
    'status': 'todo',
    'solved_at': null,
    'note': null,
  },
  'cp_daily': {},
  'hackathons': {
    'url': null,
    'status': 'active',
    'theme': null,
    'team': null,
    'notes': null,
  },
  'hackathon_milestones': {
    'due_at': null,
    'done': false,
    'kind': null,
    'gcal_event_id': null,
  },
  'hackathon_tasks': {'due_at': null, 'done': false},
  'research_projects': {'org': null, 'mentor': null, 'active': true},
  'research_logs': {'body': ''},
  'research_tasks': {
    'assigned_by': null,
    'due_at': null,
    'status': 'todo',
    'priority': 2,
    'done_at': null, //
  },
  'research_papers': {
    'url': null,
    'status': 'to_read',
    'summary': null,
    'done_at': null,
  },
  'research_ideas': {'status': 'parked'},
  'research_experiments': {'hypothesis': null, 'result': null},
  'courses': {
    'code': null,
    'attendance_attended': 0,
    'attendance_total': 0,
    'min_pct': 75,
  },
  'college_tasks': {
    'course_id': null,
    'kind': 'other',
    'due_at': null,
    'done': false,
    'done_at': null, //
    'gcal_event_id': null,
    'external_id': null,
  },
  'gcal_events_cache': {'ends_at': null, 'all_day': false},
  'inbox': {'resolved': false},
  'habits': {'target_per_week': 7},
  'habit_logs': {},
  'daily_notes': {'reflection': '', 'top3': <String>[]},
};

const uniqueKeys = <String, List<List<String>>>{
  'profiles': [
    ['user_id'],
  ],
  'reading_items': [
    ['source_id', 'url'],
  ],
  'cp_problems': [
    ['list_id', 'contest_id', 'idx'],
  ],
  'cp_daily': [
    ['day', 'problem_id'],
  ],
  'research_logs': [
    ['project_id', 'day'],
  ],
  'gcal_events_cache': [
    ['gcal_event_id'],
  ],
  'habit_logs': [
    ['habit_id', 'day'],
  ],
  'daily_notes': [
    ['day'],
  ],
};

/// parent table → [(child table, fk column)] for `on delete cascade`.
const cascades = <String, List<(String, String)>>{
  'reading_sources': [('reading_items', 'source_id')],
  'cp_lists': [('cp_problems', 'list_id')],
  'cp_problems': [('cp_daily', 'problem_id')],
  'hackathons': [
    ('hackathon_milestones', 'hackathon_id'),
    ('hackathon_tasks', 'hackathon_id'),
  ],
  'research_projects': [
    ('research_logs', 'project_id'), ('research_tasks', 'project_id'), //
    ('research_papers', 'project_id'), ('research_ideas', 'project_id'),
    ('research_experiments', 'project_id'),
  ],
  'habits': [('habit_logs', 'habit_id')],
};
