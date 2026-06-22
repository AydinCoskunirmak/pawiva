import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawiva/models/pet_profile.dart';
import 'package:pawiva/models/reminder_model.dart';
import 'package:pawiva/services/notification_service.dart';
import '../l10n/app_localizations.dart';

class AlertPage extends StatefulWidget {
  final List<PetProfile> profiles;
  const AlertPage({super.key, required this.profiles});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  String? _selectedActivity;
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedRepeat;
  List<ReminderModel> _reminders = [];

  String _getTranslatedActivity(String key, AppLocalizations l10n) {
    switch (key) {
      case "walk with paws": return l10n.walkWithPaws;
      case "cuddle and love": return l10n.cuddleAndLove;
      case "playtime for paws": return l10n.playtimeForPaws;
      case "snuggle nap": return l10n.snuggleNap;
      default: return key;
    }
  }

  String _getTranslatedRepeat(String key, AppLocalizations l10n) {
    switch (key) {
      case "today": return l10n.today;
      case "everyday": return l10n.everyday;
      case "every monday": return l10n.everyMonday;
      case "every tuesday": return l10n.everyTuesday;
      case "every wednesday": return l10n.everyWednesday;
      case "every thursday": return l10n.everyThursday;
      case "every friday": return l10n.everyFriday;
      case "every saturday": return l10n.everySaturday;
      case "every sunday": return l10n.everySunday;
      default: return key;
    }
  }

  static const List<String> _activities = [
    "walk with paws",
    "cuddle and love",
    "playtime for paws",
    "snuggle nap"
  ];

  static const List<String> _repeatOptions = [
    "today", "everyday", "every monday", "every tuesday", 
    "every wednesday", "every thursday", "every friday", 
    "every saturday", "every sunday"
  ];

  @override
  void initState() {
    super.initState();
    _loadReminders().then((_) => _cleanExpiredReminders());
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remindersJson = prefs.getString('reminders');
    if (remindersJson != null) {
      final List<dynamic> decoded = jsonDecode(remindersJson);
      setState(() {
        _reminders = decoded.map((item) => ReminderModel.fromJson(item)).toList();
      });
    }
  }
  Future<void> _cleanExpiredReminders() async {
    final now = DateTime.now();
    final List<ReminderModel> expired = [];

    for (var reminder in _reminders) {
      if (reminder.isToday) {
        final DateTime scheduled = DateTime(
          now.year, now.month, now.day,
          reminder.time.hour, reminder.time.minute,
        );
        if (scheduled.isBefore(now)) {
          expired.add(reminder);
          await NotificationService().cancelReminder(reminder.id);
        }
      }
    }

    if (expired.isNotEmpty) {
      setState(() {
        _reminders.removeWhere((r) => expired.contains(r));
      });
      _saveReminders();
    }
  }
  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_reminders.map((r) => r.toJson()).toList());
    await prefs.setString('reminders', encoded);
  }

  void _addReminder() {
    if (_selectedActivity == null || _selectedRepeat == null) return;

    bool isToday = _selectedRepeat == "today";
    List<int> weekdays = [];
    if (_selectedRepeat == "everyday") {
      weekdays = [1, 2, 3, 4, 5, 6, 7];
    } else if (_selectedRepeat != "today") {
      final day = _selectedRepeat!.split(" ").last;
      switch (day) {
        case "monday": weekdays = [1]; break;
        case "tuesday": weekdays = [2]; break;
        case "wednesday": weekdays = [3]; break;
        case "thursday": weekdays = [4]; break;
        case "friday": weekdays = [5]; break;
        case "saturday": weekdays = [6]; break;
        case "sunday": weekdays = [7]; break;
      }
    }

    final newReminder = ReminderModel(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      petName: '',  // pet seçimi kaldırıldı
      activity: _selectedActivity!,
      time: _selectedTime,
      weekdays: weekdays,
      isToday: isToday,
      isTomorrow: false,
    );

    NotificationService().scheduleReminder(newReminder);
    setState(() {
      _reminders.add(newReminder);
      _resetForm();
    });
    _saveReminders();
  }

  void _deleteReminder(ReminderModel reminder) {
    NotificationService().cancelReminder(reminder.id);
    setState(() {
      _reminders.removeWhere((r) => r.id == reminder.id);
    });
    _saveReminders();
  }

  void _resetForm() {
    _selectedActivity = null;
    _selectedTime = TimeOfDay.now();
    _selectedRepeat = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;

    bool isFormValid = _selectedActivity != null && _selectedRepeat != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  height: 40 * scale,
                  margin: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAE3C6),
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.reminders,
                    style: GoogleFonts.nunito(
                      fontSize: 24 * scale,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 100 * scaleH, left: 16 * scale, right: 16 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel(l10n.selectActivity, scale),
                        _buildActivitySelection(scale, l10n),
                        SizedBox(height: 16 * scaleH),
                        _buildSectionLabel(l10n.selectTime, scale),
                        _buildTimeSelection(scale),
                        SizedBox(height: 16 * scaleH),
                        _buildSectionLabel(l10n.repeat, scale),
                        _buildRepeatSelection(scale, l10n),
                        SizedBox(height: 32 * scaleH),
                        Center(
                          child: GestureDetector(
                            onTap: isFormValid ? _addReminder : null,
                            child: Opacity(
                              opacity: isFormValid ? 1.0 : 0.3,
                              child: Container(
                                width: 200 * scale,
                                height: 40 * scale,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAE3C6),
                                  borderRadius: BorderRadius.circular(15 * scale),
                                  border: Border.all(color: Colors.black, width: 1 * scale),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  l10n.addReminder,
                                  style: GoogleFonts.nunito(
                                    fontSize: 20 * scale,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_reminders.isNotEmpty) ...[
                          SizedBox(height: 32 * scaleH),
                          ..._reminders.map((r) => _buildReminderItem(r, scale, l10n)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 63 * scaleH,
              decoration: BoxDecoration(
                color: const Color(0xFFFAE3C6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x40000000),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back,
                    size: 24 * scale,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w400,
          color: Colors.black.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildActivitySelection(double scale, AppLocalizations l10n) {
    return Column(
      children: _activities.asMap().entries.map((entry) {
        int idx = entry.key;
        String activityKey = entry.value;
        bool isSelected = _selectedActivity == activityKey;
        return Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedActivity = activityKey),
              child: Container(
                width: 380 * scale,
                height: 40 * scale,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF8146) : Colors.white,
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getTranslatedActivity(activityKey, l10n),
                  style: GoogleFonts.nunito(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w400,
                    color: isSelected ? Colors.black : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            if (idx < _activities.length - 1)
              Container(
                width: 200 * scale,
                height: 1,
                margin: EdgeInsets.symmetric(vertical: 4 * scale),
                color: const Color(0xFFFF8146),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTimeSelection(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hours picker
        SizedBox(
          width: 80 * scale,
          height: 120 * scale,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: _selectedTime.hour,
            ),
            itemExtent: 40 * scale,
            onSelectedItemChanged: (int index) {
              setState(() {
                _selectedTime = TimeOfDay(
                  hour: index,
                  minute: _selectedTime.minute,
                );
              });
            },
            children: List.generate(24, (i) => Center(
              child: Text(
                i.toString().padLeft(2, '0'),
                style: GoogleFonts.nunito(
                  fontSize: 24 * scale,
                  color: Colors.black,
                ),
              ),
            )),
          ),
        ),
        Text(":", style: GoogleFonts.nunito(
          fontSize: 24 * scale, color: Colors.black)),
        // Minutes picker
        SizedBox(
          width: 80 * scale,
          height: 120 * scale,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: _selectedTime.minute,
            ),
            itemExtent: 40 * scale,
            onSelectedItemChanged: (int index) {
              setState(() {
                _selectedTime = TimeOfDay(
                  hour: _selectedTime.hour,
                  minute: index,
                );
              });
            },
            children: List.generate(60, (i) => Center(
              child: Text(
                i.toString().padLeft(2, '0'),
                style: GoogleFonts.nunito(
                  fontSize: 24 * scale,
                  color: Colors.black,
                ),
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatSelection(double scale, AppLocalizations l10n) {
    return Wrap(
      spacing: 8 * scale,
      runSpacing: 8 * scale,
      children: _repeatOptions.map((option) {
        bool isSelected = _selectedRepeat == option;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRepeat = option;
            });
          },
          child: Container(
            height: 32 * scale,
            padding: EdgeInsets.symmetric(horizontal: 12 * scale),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFAE3C6) : Colors.white,
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(color: Colors.black, width: 1 * scale),
            ),
            alignment: Alignment.center,
            child: Text(
              _getTranslatedRepeat(option, l10n),
              style: GoogleFonts.nunito(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w400,
                color: isSelected ? Colors.black : Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReminderItem(ReminderModel reminder, double scale, AppLocalizations l10n) {
    String repeatInfo = "";
    if (reminder.isToday) {
      repeatInfo = l10n.today;
    } else if (reminder.weekdays.length == 7) {
      repeatInfo = l10n.everyday;
    } else if (reminder.weekdays.length == 1) {
      final days = [
        l10n.everyMonday,
        l10n.everyTuesday,
        l10n.everyWednesday,
        l10n.everyThursday,
        l10n.everyFriday,
        l10n.everySaturday,
        l10n.everySunday
      ];
      repeatInfo = days[reminder.weekdays.first - 1];
    } else {
      final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      repeatInfo = reminder.weekdays.map((d) => days[d - 1]).join(", ");
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12 * scale),
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFFAE3C6),
        borderRadius: BorderRadius.circular(15 * scale),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_getTranslatedActivity(reminder.activity, l10n)}",
                  style: GoogleFonts.nunito(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${reminder.time.format(context)} | $repeatInfo",
                  style: GoogleFonts.nunito(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteReminder(reminder),
            child: Icon(Icons.delete_outline, color: Colors.black, size: 24 * scale),
          ),
        ],
      ),
    );
  }
}
