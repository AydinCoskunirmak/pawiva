import 'package:flutter/material.dart';

class ReminderModel {
  final int id;
  final String petName;
  final String activity;
  final TimeOfDay time;
  final List<int> weekdays; // 1=Mon..7=Sun, empty=one-time
  final bool isToday;
  final bool isTomorrow;

  ReminderModel({
    required this.id,
    required this.petName,
    required this.activity,
    required this.time,
    required this.weekdays,
    required this.isToday,
    required this.isTomorrow,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'petName': petName,
    'activity': activity,
    'hour': time.hour,
    'minute': time.minute,
    'weekdays': weekdays,
    'isToday': isToday,
    'isTomorrow': isTomorrow,
  };

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
    id: json['id'],
    petName: json['petName'],
    activity: json['activity'],
    time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    weekdays: List<int>.from(json['weekdays']),
    isToday: json['isToday'],
    isTomorrow: json['isTomorrow'],
  );
}
