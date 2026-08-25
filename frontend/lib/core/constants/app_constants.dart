class AppConstants {
  static const appName = 'LifeOS X';
  static const apiBaseUrl = String.fromEnvironment(
    'LIFEOS_API_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const aiPrompts = [
    'Plan my day around deep work, fitness, and study',
    'Analyze my spending and suggest a no-spend challenge',
    'Create a recovery plan after a relapse',
    'Detect burnout risk from my week',
    'Build an IGNOU MCA revision plan',
  ];
}

