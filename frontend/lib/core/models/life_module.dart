import 'package:flutter/material.dart';

class LifeModule {
  const LifeModule({
    required this.title,
    required this.route,
    required this.domain,
    required this.icon,
    required this.color,
    required this.metric,
    required this.subtitle,
  });

  final String title;
  final String route;
  final String domain;
  final IconData icon;
  final Color color;
  final String metric;
  final String subtitle;
}

const lifeModules = [
  LifeModule(
    title: 'Habits',
    route: '/modules/habits',
    domain: 'Habit Tracker',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFFFB000),
    metric: '7 day streak',
    subtitle: 'Build rituals, streaks, heatmaps, and recovery plans.',
  ),
  LifeModule(
    title: 'Recovery',
    route: '/modules/recovery',
    domain: 'Bad Habit Recovery',
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFF54D17A),
    metric: '3 urges logged',
    subtitle: 'Track triggers, relapses, moods, and emergency coaching.',
  ),
  LifeModule(
    title: 'Finance',
    route: '/modules/finance',
    domain: 'Expense and Budgeting',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF00BCD4),
    metric: '82% budget health',
    subtitle: 'Budgets, savings goals, recurring bills, and alerts.',
  ),
  LifeModule(
    title: 'Study',
    route: '/modules/study',
    domain: 'Exam Command Center',
    icon: Icons.school_rounded,
    color: Color(0xFF8B5CF6),
    metric: '9.5h this week',
    subtitle: 'Syllabus, PYQs, mock tests, Pomodoro, and weak topics.',
  ),
  LifeModule(
    title: 'Tasks',
    route: '/modules/tasks',
    domain: 'Planner',
    icon: Icons.task_alt_rounded,
    color: Color(0xFF4E8CFF),
    metric: '12 open',
    subtitle: 'Daily, weekly, timeline, recurring, and smart reminders.',
  ),
  LifeModule(
    title: 'Fitness',
    route: '/modules/fitness',
    domain: 'Workout Builder',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFFF6B6B),
    metric: '4 workouts',
    subtitle: 'Routines, sets, reps, rest timers, and walking quests.',
  ),
  LifeModule(
    title: 'Games',
    route: '/modules/games',
    domain: 'Gamification',
    icon: Icons.emoji_events_rounded,
    color: Color(0xFFFFC857),
    metric: 'Level 8',
    subtitle: 'XP, coins, gems, missions, battles, avatars, and rewards.',
  ),
  LifeModule(
    title: 'Analytics',
    route: '/modules/analytics',
    domain: 'Reports',
    icon: Icons.query_stats_rounded,
    color: Color(0xFF2DD4BF),
    metric: 'Life score 78',
    subtitle: 'Reports, burnout risk, discipline score, and heatmaps.',
  ),
];

