class TimerLog {
  final String sessionId;
  final List<String> petNames;
  final String activity;
  final int durationSeconds;
  final DateTime startTime;

  TimerLog({
    required this.sessionId,
    required this.petNames,
    required this.activity,
    required this.durationSeconds,
    required this.startTime,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'petNames': petNames,
        'activity': activity,
        'durationSeconds': durationSeconds,
        'startTime': startTime.toIso8601String(),
      };

  factory TimerLog.fromJson(Map<String, dynamic> json) => TimerLog(
        sessionId: json['sessionId'] ?? '',
        petNames: List<String>.from(json['petNames']),
        activity: json['activity'],
        durationSeconds: json['durationSeconds'],
        startTime: DateTime.parse(json['startTime']),
      );
}
