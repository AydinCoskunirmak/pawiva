import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:pawiva/models/pet_profile.dart';
import 'package:pawiva/models/timer_log.dart';
import 'package:pawiva/services/notification_service.dart';
import 'package:pawiva/l10n/app_localizations.dart';
import 'statistics_page.dart';
import 'edit_menu.dart';

class TimerPage extends StatefulWidget {
  final List<PetProfile> profiles;
  const TimerPage({super.key, required this.profiles});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<StatisticsViewState> _statsKey = GlobalKey();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Timer and selection state moved here to ensure persistence across PageView swipes
  bool _isRunning = false;
  int _seconds = 0;
  Timer? _timer;
  final Set<int> _selectedPetIndices = {};
  String? _selectedActivity;
  List<TimerLog> _timerLogs = [];
  bool _statsActivitySelected = false;
  bool _isEditMenuOpen = false;
  bool _isSharePhotoMode = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await NotificationService().initialize();
    await NotificationService().requestPermissions();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? logsJson = prefs.getString('timer_logs');
    if (logsJson != null) {
      final List<dynamic> decoded = jsonDecode(logsJson);
      setState(() {
        _timerLogs = decoded.map((item) => TimerLog.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveLog(TimerLog log) async {
    setState(() {
      _timerLogs.add(log);
    });
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_timerLogs.map((l) => l.toJson()).toList());
    await prefs.setString('timer_logs', encoded);
  }

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      if (_selectedPetIndices.isNotEmpty && _selectedActivity != null) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _analytics.logEvent(
      name: 'timer_start',
      parameters: {
        'activity': _selectedActivity ?? 'unknown',
        'pet_count': _selectedPetIndices.length,
      },
    );
    NotificationService.onStopRequested = () {
      if (mounted) {
        _stopTimer();
      }
    };
    NotificationService().startActivityNotifications(_selectedActivity!);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _analytics.logEvent(
      name: 'timer_stop',
      parameters: {
        'activity': _selectedActivity ?? 'unknown',
        'duration_seconds': _seconds,
      },
    );
    NotificationService().stopActivityNotifications();
    if (_seconds > 0) {
      final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final List<String> selectedPetNames = _selectedPetIndices
          .map((idx) => widget.profiles[idx].name)
          .toList();

      final log = TimerLog(
        sessionId: sessionId,
        petNames: selectedPetNames,
        activity: _selectedActivity ?? "unknown",
        durationSeconds: _seconds,
        startTime: DateTime.now().subtract(Duration(seconds: _seconds)),
      );
      _saveLog(log);
    }
    setState(() {
      _isRunning = false;
      _seconds = 0;
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = screenHeight / 852;
    final double scale = (scaleW + scaleH) / 2;

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      extendBody: false,
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          // Main Content
          AbsorbPointer(
            absorbing: _isEditMenuOpen,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 63 * scaleH),
                      child: Column(
                        children: [
                        // Header
                        Stack(
                          children: [
                            Container(
                              height: 93 * scaleH,
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildHeaderButton(l10n.timer, 0, scale),
                                  Container(
                                    width: 1,
                                    height: 19 * scale,
                                    color: const Color(0xFFFF8146),
                                  ),
                                  _buildHeaderButton(l10n.statistics, 1, scale),
                                ],
                              ),
                            ),
                            if (_isSharePhotoMode)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                          ],
                        ),
                          // Middle Area (PageView)
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const ClampingScrollPhysics(),
                              onPageChanged: (index) {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              children: [
                                TimerView(
                                  profiles: widget.profiles,
                                  selectedPetIndices: _selectedPetIndices,
                                  selectedActivity: _selectedActivity,
                                  isRunning: _isRunning,
                                  displayTime: _formatTime(_seconds),
                                  onPetTap: (idx) {
                                    if (_isRunning) return;
                                    setState(() {
                                      if (_selectedPetIndices.contains(idx)) {
                                        _selectedPetIndices.remove(idx);
                                      } else {
                                        _selectedPetIndices.add(idx);
                                      }
                                    });
                                  },
                                  onActivityTap: (activity) {
                                    if (_isRunning || _selectedPetIndices.isEmpty) return;
                                    setState(() {
                                      if (_selectedActivity == activity) {
                                        _selectedActivity = null;
                                      } else {
                                        _selectedActivity = activity;
                                      }
                                    });
                                  },
                                  onToggleTimer: _toggleTimer,
                                ),
                                StatisticsView(
                                  key: _statsKey,
                                  logs: _timerLogs,
                                  profiles: widget.profiles,
                                  onActivitySelected: (isSelected) {
                                    setState(() {
                                      _statsActivitySelected = isSelected;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                          blurRadius: 4 * scale,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        if (!_isSharePhotoMode) ...[
                          Positioned(
                            left: 62.5 * scale,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _isEditMenuOpen = true);
                                },
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 24 * scale,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 306.5 * scale,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  if (_selectedIndex == 1 && _statsActivitySelected) {
                                    setState(() => _isSharePhotoMode = true);
                                    _statsKey.currentState?.enterSharePhotoMode();
                                  }
                                },
                                child: Opacity(
                                  opacity: (_selectedIndex == 1 && _statsActivitySelected) ? 1.0 : 0.2,
                                  child: Icon(
                                    Icons.ios_share,
                                    size: 24 * scale,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Positioned.fill(
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _isSharePhotoMode = false);
                                  _statsKey.currentState?.exitSharePhotoMode();
                                },
                                child: Icon(
                                  Icons.arrow_back,
                                  size: 24 * scale,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          EditMenuOverlay(
            isOpen: _isEditMenuOpen,
            onClose: () => setState(() => _isEditMenuOpen = false),
            profiles: widget.profiles,
            onProfilesChanged: (updated) {
              setState(() {
                widget.profiles.clear();
                widget.profiles.addAll(updated);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(String title, int index, double scale) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 160 * scale,
        height: 50 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8146) : Colors.transparent,
          borderRadius: BorderRadius.circular(15 * scale),
        ),
        child: Text(
          title,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: GoogleFonts.nunito(
            fontSize: 26 * scale,
            fontWeight: FontWeight.w400,
            color: isSelected
                ? Colors.black
                : Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class TimerView extends StatelessWidget {
  final List<PetProfile> profiles;
  final Set<int> selectedPetIndices;
  final String? selectedActivity;
  final bool isRunning;
  final String displayTime;
  final Function(int) onPetTap;
  final Function(String) onActivityTap;
  final VoidCallback onToggleTimer;

  const TimerView({
    super.key,
    required this.profiles,
    required this.selectedPetIndices,
    required this.selectedActivity,
    required this.isRunning,
    required this.displayTime,
    required this.onPetTap,
    required this.onActivityTap,
    required this.onToggleTimer,
  });

  static const List<String> _activities = [
    "walk with paws",
    "cuddle and love",
    "playtime for paws",
    "snuggle nap"
  ];

  @override
  Widget build(BuildContext context) {
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;
    final l10n = AppLocalizations.of(context);

    final List<String> localizedActivities = [
      l10n.walkWithPaws,
      l10n.cuddleAndLove,
      l10n.playtimeForPaws,
      l10n.snuggleNap
    ];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Choose your pet banner
          Container(
            width: double.infinity,
            height: 50 * scale,
            margin: EdgeInsets.symmetric(horizontal: 0 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFFAE3C6),
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            alignment: Alignment.center,
            child: Text(
              l10n.chooseYourPet,
              style: GoogleFonts.nunito(
                fontSize: 24 * scale,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 10 * scaleH),
          // Pet Profile Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: profiles.asMap().entries.map((entry) {
                int idx = entry.key;
                PetProfile pet = entry.value;
                bool isSelected = selectedPetIndices.contains(idx);
                return GestureDetector(
                  onTap: () => onPetTap(idx),
                  child: Opacity(
                    opacity: isSelected ? 1.0 : 0.5,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                      child: Column(
                        children: [
                          Container(
                            width: 50 * scale,
                            height: 50 * scale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18 * scale),
                              border: Border.all(color: Colors.black, width: 1 * scale),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18 * scale),
                              child: pet.image != null
                                  ? Image.file(pet.image!, fit: BoxFit.cover)
                                  : Center(
                                      child: Icon(Icons.pets, size: 24 * scale),
                                    ),
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            pet.name,
                            style: GoogleFonts.nunito(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 10 * scaleH),
          // Pick activity banner
          Container(
            width: double.infinity,
            height: 50 * scale,
            decoration: BoxDecoration(
              color: const Color(0xFFFAE3C6),
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                l10n.pickActivity,
                style: GoogleFonts.nunito(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 10 * scaleH),
          // Activity Buttons
          ...localizedActivities.asMap().entries.map((entry) {
            int idx = entry.key;
            String activityLabel = entry.value;
            String activityKey = _activities[idx];
            bool isSelected = selectedActivity == activityKey;
            return Column(
              children: [
                GestureDetector(
                  onTap: () => onActivityTap(activityKey),
                  child: Container(
                    width: 380 * scale,
                    height: 40 * scale,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF8146) : Colors.white,
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      activityLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w400,
                        color: isSelected
                            ? Colors.black
                            : Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                if (idx < localizedActivities.length - 1)
                  Container(
                    width: 200 * scale,
                    height: 1,
                    margin: EdgeInsets.symmetric(vertical: 4 * scaleH),
                    color: const Color(0xFFFF8146),
                  ),
              ],
            );
          }),
          const Spacer(),
          // Timer Display
          Text(
            displayTime,
            style: GoogleFonts.nunito(
              fontSize: 64 * scale,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          // Start/Stop Button
          GestureDetector(
            onTap: onToggleTimer,
            child: Text(
              isRunning ? l10n.stop : l10n.start,
              style: GoogleFonts.staatliches(
                fontSize: 32 * scale,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 20 * scaleH),
        ],
      ),
    );
  }
}
