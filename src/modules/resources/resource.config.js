export const resourceConfig = {
  habits: {
    table: 'habits',
    fields: [
      'title',
      'description',
      'category',
      'type',
      'difficulty',
      'target_value',
      'unit',
      'frequency',
      'reminder_time',
      'color',
      'icon',
      'is_active'
    ]
  },
  'habit-logs': {
    table: 'habit_logs',
    fields: ['habit_id', 'log_date', 'value', 'status', 'mood', 'notes']
  },
  'bad-habits': {
    table: 'bad_habits',
    fields: ['title', 'description', 'trigger_notes', 'severity', 'replacement_habit', 'is_active']
  },
  'bad-habit-logs': {
    table: 'bad_habit_logs',
    fields: ['bad_habit_id', 'log_date', 'urge_level', 'relapsed', 'trigger', 'mood', 'notes']
  },
  expenses: {
    table: 'expenses',
    fields: ['category', 'amount', 'currency', 'spent_at', 'merchant', 'payment_method', 'notes', 'is_recurring']
  },
  income: {
    table: 'income',
    fields: ['source', 'amount', 'currency', 'received_at', 'notes']
  },
  budgets: {
    table: 'budgets',
    fields: ['category', 'amount', 'currency', 'period', 'starts_on', 'ends_on', 'alert_threshold']
  },
  'savings-goals': {
    table: 'savings_goals',
    fields: ['title', 'target_amount', 'current_amount', 'currency', 'target_date', 'priority', 'notes']
  },
  'study/subjects': {
    table: 'study_subjects',
    fields: ['name', 'code', 'program', 'semester', 'color', 'target_hours', 'exam_date', 'notes']
  },
  'study/topics': {
    table: 'study_topics',
    fields: ['subject_id', 'title', 'unit', 'difficulty', 'status', 'progress', 'last_revised_at', 'notes']
  },
  'study/sessions': {
    table: 'study_sessions',
    fields: ['subject_id', 'topic_id', 'started_at', 'ended_at', 'duration_minutes', 'focus_score', 'mode', 'notes']
  },
  exams: {
    table: 'exams',
    fields: ['subject_id', 'title', 'exam_date', 'type', 'syllabus_scope', 'target_score', 'actual_score', 'notes']
  },
  tasks: {
    table: 'tasks',
    fields: [
      'title',
      'description',
      'priority',
      'status',
      'category',
      'due_at',
      'recurrence_rule',
      'repeat_until_complete',
      'parent_task_id',
      'estimate_minutes',
      'completed_at'
    ]
  },
  reminders: {
    table: 'reminders',
    fields: ['title', 'body', 'remind_at', 'channel', 'recurrence_rule', 'snoozed_until', 'status', 'linked_type', 'linked_id']
  },
  'productivity-logs': {
    table: 'productivity_logs',
    fields: ['log_date', 'deep_work_minutes', 'distraction_minutes', 'tasks_completed', 'focus_score', 'notes']
  },
  goals: {
    table: 'goals',
    fields: ['title', 'description', 'domain', 'target_date', 'status', 'progress', 'priority']
  },
  achievements: {
    table: 'achievements',
    fields: ['code', 'title', 'description', 'domain', 'unlocked_at', 'xp_reward', 'metadata']
  },
  rewards: {
    table: 'rewards',
    fields: ['title', 'description', 'cost_coins', 'type', 'is_claimed', 'claimed_at']
  },
  avatars: {
    table: 'avatars',
    fields: ['name', 'style', 'level_required', 'asset_url', 'is_unlocked', 'equipped_at']
  },
  challenges: {
    table: 'challenges',
    fields: ['title', 'description', 'domain', 'difficulty', 'starts_at', 'ends_at', 'xp_reward', 'coin_reward', 'status']
  },
  'challenge-progress': {
    table: 'challenge_progress',
    fields: ['challenge_id', 'progress', 'status', 'last_check_in_at', 'completed_at', 'notes']
  },
  moods: {
    table: 'moods',
    fields: ['mood_date', 'score', 'energy', 'stress', 'sleep_quality', 'notes']
  },
  'analytics/logs': {
    table: 'analytics',
    fields: ['metric_key', 'metric_value', 'metric_date', 'domain', 'metadata']
  },
  notifications: {
    table: 'notifications',
    fields: ['title', 'body', 'type', 'payload', 'scheduled_at', 'sent_at', 'read_at', 'status']
  },
  'exercise-routines': {
    table: 'exercise_routines',
    fields: ['title', 'description', 'target_muscles', 'difficulty', 'estimated_minutes', 'calories_estimate', 'notes']
  },
  exercises: {
    table: 'exercises',
    fields: ['routine_id', 'name', 'sets', 'reps', 'rest_seconds', 'target_muscle', 'calories', 'notes']
  },
  'workout-logs': {
    table: 'workout_logs',
    fields: ['routine_id', 'started_at', 'ended_at', 'duration_minutes', 'calories_burned', 'intensity', 'notes']
  },
  'syllabus-units': {
    table: 'syllabus_units',
    fields: ['subject_id', 'title', 'unit_order', 'progress', 'notes', 'attachment_url']
  },
  'syllabus-topics': {
    table: 'syllabus_topics',
    fields: ['unit_id', 'title', 'topic_order', 'progress', 'status', 'notes']
  },
  'dashboard-preferences': {
    table: 'dashboard_preferences',
    fields: ['widget_key', 'layout', 'is_visible', 'sort_order', 'settings']
  },
  'ai/chat-history': {
    table: 'AI_chat_history',
    fields: ['conversation_id', 'role', 'content', 'provider', 'model', 'metadata']
  },
  settings: {
    table: 'settings',
    fields: ['setting_key', 'setting_value']
  }
};

export const getResource = (slug) => resourceConfig[slug];

