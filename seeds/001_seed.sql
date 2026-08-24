USE `Nitish_db`;

INSERT INTO users
  (id, email, password_hash, display_name, role, auth_provider, email_verified, status, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000001', 'demo@lifeosx.local', '$2b$12$rxm.Ux17PjRGmilrj34aZ.XCDggqr9wumumtYhrcXTA5e6QLvts66', 'LifeOS Demo', 'user', 'local', 1, 'active', NOW(), NOW())
ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash), display_name = VALUES(display_name), updated_at = NOW();

INSERT INTO user_profiles
  (id, user_id, full_name, timezone, onboarding_completed, analytics_opt_in, notification_opt_in, consent_version, consented_at, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', 'LifeOS Demo', 'Asia/Calcutta', 1, 1, 1, '2026-05', NOW(), NOW(), NOW())
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name), updated_at = NOW();

INSERT INTO habits
  (id, user_id, title, description, category, difficulty, target_value, unit, frequency, color, icon, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000010', '00000000-0000-4000-8000-000000000001', 'Morning deep work', 'One focused study or build block before distractions.', 'productivity', 'medium', 1, 'block', 'daily', '#00E5FF', 'bolt', NOW(), NOW()),
  ('00000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-000000000001', 'Walk 6000 steps', 'Daily movement quest.', 'fitness', 'easy', 6000, 'steps', 'daily', '#64FFDA', 'directions_walk', NOW(), NOW())
ON DUPLICATE KEY UPDATE title = VALUES(title), updated_at = NOW();

INSERT INTO study_subjects
  (id, user_id, name, code, program, semester, color, target_hours, notes, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000020', '00000000-0000-4000-8000-000000000001', 'IGNOU MCA - Advanced DBMS', 'MCS-043', 'IGNOU MCA', 'Custom', '#FFB86C', 40, 'Customizable syllabus starter.', NOW(), NOW())
ON DUPLICATE KEY UPDATE name = VALUES(name), updated_at = NOW();

INSERT INTO tasks
  (id, user_id, title, description, priority, status, category, due_at, estimate_minutes, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000030', '00000000-0000-4000-8000-000000000001', 'Plan this week', 'Review habits, budget, study blocks, and recovery time.', 'high', 'todo', 'planning', NOW() + INTERVAL 1 DAY, 30, NOW(), NOW())
ON DUPLICATE KEY UPDATE title = VALUES(title), updated_at = NOW();

INSERT INTO budgets
  (id, user_id, category, amount, currency, period, starts_on, alert_threshold, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000040', '00000000-0000-4000-8000-000000000001', 'junk food', 1500, 'INR', 'monthly', CURRENT_DATE(), 75, NOW(), NOW())
ON DUPLICATE KEY UPDATE amount = VALUES(amount), updated_at = NOW();

INSERT INTO challenges
  (id, user_id, title, description, domain, difficulty, starts_at, ends_at, xp_reward, coin_reward, status, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000050', '00000000-0000-4000-8000-000000000001', 'No-Spend Focus Day', 'Avoid impulse spending for one day and log every urge.', 'finance', 'medium', NOW(), NOW() + INTERVAL 1 DAY, 120, 30, 'active', NOW(), NOW())
ON DUPLICATE KEY UPDATE title = VALUES(title), updated_at = NOW();
