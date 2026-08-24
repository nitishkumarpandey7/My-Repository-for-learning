CREATE DATABASE IF NOT EXISTS `Nitish_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `Nitish_db`;

CREATE TABLE IF NOT EXISTS users (
  id CHAR(36) PRIMARY KEY,
  firebase_uid VARCHAR(128) UNIQUE NULL,
  email VARCHAR(190) UNIQUE NULL,
  phone VARCHAR(32) UNIQUE NULL,
  password_hash VARCHAR(255) NULL,
  display_name VARCHAR(120) NULL,
  role ENUM('user', 'guest', 'admin') NOT NULL DEFAULT 'user',
  auth_provider ENUM('local', 'firebase', 'google', 'phone', 'guest') NOT NULL DEFAULT 'local',
  email_verified TINYINT(1) NOT NULL DEFAULT 0,
  status ENUM('active', 'soft_deleted', 'pending_delete', 'deleted') NOT NULL DEFAULT 'active',
  deletion_requested_at DATETIME NULL,
  deletion_grace_until DATETIME NULL,
  deletion_reason VARCHAR(500) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_status (status),
  INDEX idx_users_firebase_uid (firebase_uid)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_profiles (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL UNIQUE,
  full_name VARCHAR(120) NULL,
  avatar_url VARCHAR(500) NULL,
  timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Calcutta',
  date_of_birth DATE NULL,
  country VARCHAR(80) NULL,
  onboarding_completed TINYINT(1) NOT NULL DEFAULT 0,
  analytics_opt_in TINYINT(1) NOT NULL DEFAULT 1,
  notification_opt_in TINYINT(1) NOT NULL DEFAULT 1,
  consent_version VARCHAR(40) NULL,
  consented_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_profiles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS habits (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  description TEXT NULL,
  category VARCHAR(80) NULL,
  type ENUM('build', 'maintain') NOT NULL DEFAULT 'build',
  difficulty ENUM('easy', 'medium', 'hard', 'elite') NOT NULL DEFAULT 'medium',
  target_value DECIMAL(10,2) NOT NULL DEFAULT 1,
  unit VARCHAR(40) NULL,
  frequency VARCHAR(80) NOT NULL DEFAULT 'daily',
  reminder_time TIME NULL,
  color VARCHAR(20) NULL,
  icon VARCHAR(80) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_habits_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_habits_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS habit_logs (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  habit_id CHAR(36) NOT NULL,
  log_date DATE NOT NULL,
  value DECIMAL(10,2) NOT NULL DEFAULT 1,
  status ENUM('completed', 'missed', 'skipped', 'partial') NOT NULL DEFAULT 'completed',
  mood VARCHAR(60) NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_habit_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_habit_logs_habit FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE,
  UNIQUE KEY uniq_habit_day (user_id, habit_id, log_date),
  INDEX idx_habit_logs_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS bad_habits (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  description TEXT NULL,
  trigger_notes TEXT NULL,
  severity ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
  replacement_habit VARCHAR(160) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_bad_habits_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_bad_habits_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS bad_habit_logs (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  bad_habit_id CHAR(36) NOT NULL,
  log_date DATE NOT NULL,
  urge_level TINYINT NOT NULL DEFAULT 0,
  relapsed TINYINT(1) NOT NULL DEFAULT 0,
  `trigger` VARCHAR(255) NULL,
  mood VARCHAR(60) NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_bad_habit_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_bad_habit_logs_bad_habit FOREIGN KEY (bad_habit_id) REFERENCES bad_habits(id) ON DELETE CASCADE,
  INDEX idx_bad_habit_logs_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS expenses (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  category VARCHAR(80) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'INR',
  spent_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  merchant VARCHAR(160) NULL,
  payment_method VARCHAR(80) NULL,
  notes TEXT NULL,
  is_recurring TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_expenses_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_expenses_user_spent (user_id, spent_at),
  INDEX idx_expenses_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS income (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  source VARCHAR(120) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'INR',
  received_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_income_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_income_user_received (user_id, received_at),
  INDEX idx_income_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS budgets (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  category VARCHAR(80) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'INR',
  period ENUM('weekly', 'monthly', 'quarterly', 'yearly') NOT NULL DEFAULT 'monthly',
  starts_on DATE NOT NULL,
  ends_on DATE NULL,
  alert_threshold DECIMAL(5,2) NOT NULL DEFAULT 80.00,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_budgets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_budgets_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS savings_goals (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  target_amount DECIMAL(12,2) NOT NULL,
  current_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  currency CHAR(3) NOT NULL DEFAULT 'INR',
  target_date DATE NULL,
  priority ENUM('low', 'medium', 'high') NOT NULL DEFAULT 'medium',
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_savings_goals_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_savings_goals_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS study_subjects (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  name VARCHAR(160) NOT NULL,
  code VARCHAR(40) NULL,
  program VARCHAR(120) NULL,
  semester VARCHAR(40) NULL,
  color VARCHAR(20) NULL,
  target_hours DECIMAL(8,2) NOT NULL DEFAULT 0,
  exam_date DATE NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_study_subjects_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_study_subjects_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS study_topics (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  subject_id CHAR(36) NOT NULL,
  title VARCHAR(180) NOT NULL,
  unit VARCHAR(80) NULL,
  difficulty ENUM('easy', 'medium', 'hard') NOT NULL DEFAULT 'medium',
  status ENUM('not_started', 'learning', 'revision', 'mastered') NOT NULL DEFAULT 'not_started',
  progress DECIMAL(5,2) NOT NULL DEFAULT 0,
  last_revised_at DATETIME NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_study_topics_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_study_topics_subject FOREIGN KEY (subject_id) REFERENCES study_subjects(id) ON DELETE CASCADE,
  INDEX idx_study_topics_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS study_sessions (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  subject_id CHAR(36) NULL,
  topic_id CHAR(36) NULL,
  started_at DATETIME NOT NULL,
  ended_at DATETIME NULL,
  duration_minutes INT NOT NULL DEFAULT 0,
  focus_score DECIMAL(5,2) NOT NULL DEFAULT 0,
  mode ENUM('pomodoro', 'deep_work', 'revision', 'mock_test', 'reading') NOT NULL DEFAULT 'pomodoro',
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_study_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_study_sessions_subject FOREIGN KEY (subject_id) REFERENCES study_subjects(id) ON DELETE SET NULL,
  CONSTRAINT fk_study_sessions_topic FOREIGN KEY (topic_id) REFERENCES study_topics(id) ON DELETE SET NULL,
  INDEX idx_study_sessions_user_started (user_id, started_at),
  INDEX idx_study_sessions_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exams (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  subject_id CHAR(36) NULL,
  title VARCHAR(180) NOT NULL,
  exam_date DATETIME NOT NULL,
  type VARCHAR(80) NOT NULL DEFAULT 'exam',
  syllabus_scope JSON NULL,
  target_score DECIMAL(6,2) NULL,
  actual_score DECIMAL(6,2) NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_exams_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_exams_subject FOREIGN KEY (subject_id) REFERENCES study_subjects(id) ON DELETE SET NULL,
  INDEX idx_exams_user_date (user_id, exam_date),
  INDEX idx_exams_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tasks (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  parent_task_id CHAR(36) NULL,
  title VARCHAR(180) NOT NULL,
  description TEXT NULL,
  priority ENUM('low', 'medium', 'high', 'urgent') NOT NULL DEFAULT 'medium',
  status ENUM('todo', 'in_progress', 'waiting', 'done', 'cancelled') NOT NULL DEFAULT 'todo',
  category VARCHAR(80) NULL,
  due_at DATETIME NULL,
  recurrence_rule VARCHAR(255) NULL,
  repeat_until_complete TINYINT(1) NOT NULL DEFAULT 0,
  estimate_minutes INT NULL,
  completed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_tasks_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_tasks_parent FOREIGN KEY (parent_task_id) REFERENCES tasks(id) ON DELETE SET NULL,
  INDEX idx_tasks_user_due (user_id, due_at),
  INDEX idx_tasks_user_status (user_id, status),
  INDEX idx_tasks_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reminders (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  body VARCHAR(500) NULL,
  remind_at DATETIME NOT NULL,
  channel ENUM('push', 'email', 'in_app') NOT NULL DEFAULT 'push',
  recurrence_rule VARCHAR(255) NULL,
  snoozed_until DATETIME NULL,
  status ENUM('scheduled', 'sent', 'snoozed', 'cancelled') NOT NULL DEFAULT 'scheduled',
  linked_type VARCHAR(60) NULL,
  linked_id CHAR(36) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_reminders_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_reminders_user_time (user_id, remind_at),
  INDEX idx_reminders_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS productivity_logs (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  log_date DATE NOT NULL,
  deep_work_minutes INT NOT NULL DEFAULT 0,
  distraction_minutes INT NOT NULL DEFAULT 0,
  tasks_completed INT NOT NULL DEFAULT 0,
  focus_score DECIMAL(5,2) NOT NULL DEFAULT 0,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_productivity_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uniq_productivity_day (user_id, log_date),
  INDEX idx_productivity_logs_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS goals (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(180) NOT NULL,
  description TEXT NULL,
  domain VARCHAR(60) NOT NULL DEFAULT 'life',
  target_date DATE NULL,
  status ENUM('active', 'paused', 'completed', 'cancelled') NOT NULL DEFAULT 'active',
  progress DECIMAL(5,2) NOT NULL DEFAULT 0,
  priority ENUM('low', 'medium', 'high') NOT NULL DEFAULT 'medium',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_goals_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_goals_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS achievements (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  code VARCHAR(120) NOT NULL,
  title VARCHAR(160) NOT NULL,
  description VARCHAR(500) NULL,
  domain VARCHAR(60) NOT NULL DEFAULT 'life',
  unlocked_at DATETIME NULL,
  xp_reward INT NOT NULL DEFAULT 0,
  metadata JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_achievements_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uniq_achievement_user_code (user_id, code),
  INDEX idx_achievements_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rewards (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  description VARCHAR(500) NULL,
  cost_coins INT NOT NULL DEFAULT 0,
  type VARCHAR(60) NOT NULL DEFAULT 'custom',
  is_claimed TINYINT(1) NOT NULL DEFAULT 0,
  claimed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_rewards_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_rewards_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS XP_logs (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  points INT NOT NULL,
  reason VARCHAR(160) NOT NULL,
  domain VARCHAR(60) NOT NULL DEFAULT 'life',
  reference_id CHAR(36) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_xp_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_xp_logs_user_created (user_id, created_at),
  INDEX idx_xp_logs_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS avatars (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  name VARCHAR(120) NOT NULL,
  style VARCHAR(80) NOT NULL DEFAULT 'futuristic',
  level_required INT NOT NULL DEFAULT 1,
  asset_url VARCHAR(500) NULL,
  is_unlocked TINYINT(1) NOT NULL DEFAULT 0,
  equipped_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_avatars_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_avatars_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS challenges (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(180) NOT NULL,
  description TEXT NULL,
  domain VARCHAR(60) NOT NULL,
  difficulty ENUM('easy', 'medium', 'hard', 'elite') NOT NULL DEFAULT 'medium',
  starts_at DATETIME NOT NULL,
  ends_at DATETIME NULL,
  xp_reward INT NOT NULL DEFAULT 0,
  coin_reward INT NOT NULL DEFAULT 0,
  status ENUM('draft', 'active', 'completed', 'failed', 'cancelled') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_challenges_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_challenges_user_status (user_id, status),
  INDEX idx_challenges_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS challenge_progress (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  challenge_id CHAR(36) NOT NULL,
  progress DECIMAL(5,2) NOT NULL DEFAULT 0,
  status ENUM('active', 'completed', 'failed') NOT NULL DEFAULT 'active',
  last_check_in_at DATETIME NULL,
  completed_at DATETIME NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_challenge_progress_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_challenge_progress_challenge FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE,
  UNIQUE KEY uniq_challenge_progress (user_id, challenge_id),
  INDEX idx_challenge_progress_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS moods (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  mood_date DATE NOT NULL,
  score TINYINT NOT NULL DEFAULT 5,
  energy TINYINT NOT NULL DEFAULT 5,
  stress TINYINT NOT NULL DEFAULT 5,
  sleep_quality TINYINT NOT NULL DEFAULT 5,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_moods_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uniq_mood_day (user_id, mood_date),
  INDEX idx_moods_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS analytics (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  metric_key VARCHAR(120) NOT NULL,
  metric_value DECIMAL(14,4) NOT NULL DEFAULT 0,
  metric_date DATE NOT NULL,
  domain VARCHAR(60) NOT NULL DEFAULT 'life',
  metadata JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_analytics_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_analytics_user_metric (user_id, metric_key, metric_date),
  INDEX idx_analytics_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  body VARCHAR(500) NULL,
  type VARCHAR(60) NOT NULL DEFAULT 'general',
  payload JSON NULL,
  scheduled_at DATETIME NULL,
  sent_at DATETIME NULL,
  read_at DATETIME NULL,
  status ENUM('queued', 'scheduled', 'sent', 'read', 'failed') NOT NULL DEFAULT 'queued',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_notifications_user_status (user_id, status),
  INDEX idx_notifications_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exercise_routines (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(180) NOT NULL,
  description TEXT NULL,
  target_muscles JSON NULL,
  difficulty ENUM('easy', 'medium', 'hard', 'elite') NOT NULL DEFAULT 'medium',
  estimated_minutes INT NOT NULL DEFAULT 30,
  calories_estimate INT NOT NULL DEFAULT 0,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_exercise_routines_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_exercise_routines_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exercises (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  routine_id CHAR(36) NULL,
  name VARCHAR(180) NOT NULL,
  sets INT NOT NULL DEFAULT 3,
  reps VARCHAR(40) NOT NULL DEFAULT '10',
  rest_seconds INT NOT NULL DEFAULT 60,
  target_muscle VARCHAR(80) NULL,
  calories INT NOT NULL DEFAULT 0,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_exercises_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_exercises_routine FOREIGN KEY (routine_id) REFERENCES exercise_routines(id) ON DELETE SET NULL,
  INDEX idx_exercises_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS workout_logs (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  routine_id CHAR(36) NULL,
  started_at DATETIME NOT NULL,
  ended_at DATETIME NULL,
  duration_minutes INT NOT NULL DEFAULT 0,
  calories_burned INT NOT NULL DEFAULT 0,
  intensity ENUM('light', 'moderate', 'hard', 'max') NOT NULL DEFAULT 'moderate',
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_workout_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_workout_logs_routine FOREIGN KEY (routine_id) REFERENCES exercise_routines(id) ON DELETE SET NULL,
  INDEX idx_workout_logs_user_started (user_id, started_at),
  INDEX idx_workout_logs_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS syllabus_units (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  subject_id CHAR(36) NOT NULL,
  title VARCHAR(180) NOT NULL,
  unit_order INT NOT NULL DEFAULT 0,
  progress DECIMAL(5,2) NOT NULL DEFAULT 0,
  notes TEXT NULL,
  attachment_url VARCHAR(500) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_syllabus_units_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_syllabus_units_subject FOREIGN KEY (subject_id) REFERENCES study_subjects(id) ON DELETE CASCADE,
  INDEX idx_syllabus_units_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS syllabus_topics (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  unit_id CHAR(36) NOT NULL,
  title VARCHAR(180) NOT NULL,
  topic_order INT NOT NULL DEFAULT 0,
  progress DECIMAL(5,2) NOT NULL DEFAULT 0,
  status ENUM('not_started', 'learning', 'revision', 'mastered') NOT NULL DEFAULT 'not_started',
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_syllabus_topics_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_syllabus_topics_unit FOREIGN KEY (unit_id) REFERENCES syllabus_units(id) ON DELETE CASCADE,
  INDEX idx_syllabus_topics_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dashboard_preferences (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  widget_key VARCHAR(80) NOT NULL,
  layout JSON NULL,
  is_visible TINYINT(1) NOT NULL DEFAULT 1,
  sort_order INT NOT NULL DEFAULT 0,
  settings JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_dashboard_preferences_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uniq_dashboard_widget (user_id, widget_key),
  INDEX idx_dashboard_preferences_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS AI_chat_history (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  conversation_id CHAR(36) NOT NULL,
  role ENUM('system', 'user', 'assistant') NOT NULL,
  content MEDIUMTEXT NOT NULL,
  provider VARCHAR(60) NULL,
  model VARCHAR(120) NULL,
  metadata JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ai_chat_history_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_ai_chat_history_conversation (user_id, conversation_id, created_at),
  INDEX idx_ai_chat_history_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS login_history (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  ip_address VARCHAR(80) NULL,
  user_agent VARCHAR(500) NULL,
  device_label VARCHAR(160) NULL,
  success TINYINT(1) NOT NULL DEFAULT 1,
  suspicious TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_login_history_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_login_history_user_created (user_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS devices (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  device_id VARCHAR(120) NOT NULL,
  platform VARCHAR(80) NULL,
  model VARCHAR(120) NULL,
  app_version VARCHAR(40) NULL,
  fcm_token VARCHAR(512) NULL,
  trusted TINYINT(1) NOT NULL DEFAULT 1,
  biometric_enabled TINYINT(1) NOT NULL DEFAULT 0,
  last_seen_at DATETIME NULL,
  revoked_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_devices_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uniq_user_device (user_id, device_id),
  INDEX idx_devices_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS settings (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  setting_key VARCHAR(120) NOT NULL,
  setting_value JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uniq_user_setting (user_id, setting_key),
  INDEX idx_settings_user_updated (user_id, updated_at)
) ENGINE=InnoDB;

