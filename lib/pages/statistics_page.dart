import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:math' show pi, max, min;
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pawiva/models/timer_log.dart';
import 'package:pawiva/models/pet_profile.dart';
import 'package:pawiva/pages/share_photo_page.dart';
import 'package:pawiva/l10n/app_localizations.dart';

class StatisticsView extends StatefulWidget {
  final List<TimerLog> logs;
  final List<PetProfile> profiles;
  final Function(bool) onActivitySelected;

  const StatisticsView({
    super.key,
    required this.logs,
    required this.profiles,
    required this.onActivitySelected,
  });

  @override
  State<StatisticsView> createState() => StatisticsViewState();
}

class StatisticsViewState extends State<StatisticsView> {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final Set<int> _selectedPetIndices = {};
  String? _selectedActivity;
  String _timeRange = "daily"; // "daily" | "weekly" | "monthly"
  int? _touchedBarIndex;
  bool _isSharePhotoMode = false;
  int _currentDayOffset = 0; // 0 = today, -1 = yesterday, etc.
  int _currentWeekOffset = 0; // 0 = current week, -1 = prev week, etc.
  int _currentMonthOffset = 0; // 0 = current month, -1 = previous month, etc.

  late DateTime _chartStartDate;
  final ScrollController _horizontalScrollController = ScrollController();

  static const List<String> _activities = [
    "walk with paws",
    "cuddle and love",
    "playtime for paws",
    "snuggle nap",
    "all activities"
  ];

  @override
  void initState() {
    super.initState();
    _initDates();
    _horizontalScrollController.addListener(_onScroll);
    _scrollToToday();
  }

  void _onScroll() {
    if (_touchedBarIndex != null) {
      setState(() {});
    }
  }

  void _initDates() {
    if (widget.logs.isNotEmpty) {
      _chartStartDate = widget.logs
          .map((l) => l.startTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);
    } else {
      _chartStartDate = DateTime.now();
    }
    _chartStartDate =
        DateTime(_chartStartDate.year, _chartStartDate.month, _chartStartDate.day);
  }

  @override
  void dispose() {
    _horizontalScrollController.removeListener(_onScroll);
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (_timeRange == "daily" || _timeRange == "weekly" || _timeRange == "monthly") return; // No scroll

    WidgetsBinding.instance.addPostFrameCallback((unusedA) {
      if (_horizontalScrollController.hasClients) {
        final double scaleW = MediaQuery.of(context).size.width / 393;
        final double scaleH = MediaQuery.of(context).size.height / 852;
        final double scale = (scaleW + scaleH) / 2;

        double offset = 0;
        // Legacy monthly scroll - no longer needed with new behavior
        /*
        if (_timeRange == "monthly") {
          int weeks = now.difference(_chartStartDate).inDays ~/ 7;
          offset = weeks * 40 * scale;
        }
        */

        double screenWidth = MediaQuery.of(context).size.width;
        double target = offset - (screenWidth / 2) + (40 * scale);
        if (target < 0) target = 0;
        if (target > _horizontalScrollController.position.maxScrollExtent) {
          target = _horizontalScrollController.position.maxScrollExtent;
        }

        _horizontalScrollController.jumpTo(target);
      }
    });
  }

  _WeeklyWindow _getWeeklyWindow() {
    DateTime today = DateTime.now();
    DateTime todayDate = DateTime(today.year, today.month, today.day);

    if (_currentWeekOffset == 0) {
      // Default: last 7 days
      DateTime windowStart = todayDate.subtract(Duration(days: 6));
      DateTime windowEnd = todayDate;
      return _WeeklyWindow(windowStart, windowEnd, 7, false);
    } else if (_currentWeekOffset == 1) {
      // Current calendar week: Monday to Sunday
      int weekday = todayDate.weekday; // 1=Mon, 7=Sun
      DateTime monday = todayDate.subtract(Duration(days: weekday - 1));
      DateTime sunday = monday.add(Duration(days: 6));
      int days = 7;
      return _WeeklyWindow(monday, sunday, days, false);
    } else if (_currentWeekOffset < 0) {
      // Past calendar weeks: Monday to Sunday
      int weekday = todayDate.weekday;
      DateTime currentMonday = todayDate.subtract(Duration(days: weekday - 1));
      DateTime monday = currentMonday.add(Duration(days: _currentWeekOffset * 7));
      DateTime sunday = monday.add(Duration(days: 6));
      int days = 7;
      return _WeeklyWindow(monday, sunday, days, false);
    }

    return _WeeklyWindow(
        todayDate.subtract(Duration(days: 6)), todayDate, 7, false);
  }

  _MonthlyWindow _getMonthlyWindow() {
    DateTime today = DateTime.now();
    DateTime todayDate = DateTime(today.year, today.month, today.day);

    if (_currentMonthOffset == 0) {
      // Default: last 30 days
      DateTime windowStart = todayDate.subtract(Duration(days: 29));
      DateTime windowEnd = todayDate;
      return _MonthlyWindow(windowStart, windowEnd, 30);
    } else if (_currentMonthOffset == 1) {
      // Current calendar month
      DateTime firstOfMonth = DateTime(today.year, today.month, 1);
      DateTime lastOfMonth = DateTime(today.year, today.month + 1, 0);
      int days = lastOfMonth.difference(firstOfMonth).inDays + 1;
      return _MonthlyWindow(firstOfMonth, lastOfMonth, days);
    } else if (_currentMonthOffset < 0) {
      // Past calendar months
      DateTime firstOfMonth = DateTime(today.year, today.month + _currentMonthOffset, 1);
      DateTime lastOfMonth = DateTime(today.year, today.month + _currentMonthOffset + 1, 0);
      int days = lastOfMonth.difference(firstOfMonth).inDays + 1;
      return _MonthlyWindow(firstOfMonth, lastOfMonth, days);
    }

    return _MonthlyWindow(
        todayDate.subtract(Duration(days: 29)), todayDate, 30);
  }

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
      l10n.snuggleNap,
    ];

    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildBanner(l10n.chooseYourPet, scale),
              SizedBox(height: 10 * scaleH),
              _buildPetRow(scale),
              SizedBox(height: 10 * scaleH),
              _buildBanner(l10n.checkProgress, scale),
              SizedBox(height: 10 * scaleH),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...localizedActivities.asMap().entries.map((entry) {
                        int idx = entry.key;
                        String activity = entry.value;
                        String internalKey = _activities[idx];
                        bool isSelected = _selectedActivity == internalKey;
                        return Column(
                          children: [
                            _buildActivityButton(activity, internalKey, isSelected, scale),
                            if (isSelected) _buildChartArea(scale, scaleH),
                            if (!isSelected)
                              Container(
                                width: 200 * scale,
                                height: 1,
                                margin: EdgeInsets.symmetric(vertical: 4 * scaleH),
                                color: const Color(0xFFFF8146),
                              ),
                          ],
                        );
                      }),
                      Builder(builder: (context) {
                        String activity = l10n.allActivities;
                        String internalKey = "all activities";
                        bool isSelected = _selectedActivity == internalKey;
                        return Column(
                          children: [
                            _buildActivityButton(activity, internalKey, isSelected, scale),
                            if (isSelected) _buildChartArea(scale, scaleH),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isSharePhotoMode) ...[
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40 * scaleH,
            child: Center(
              child: GestureDetector(
                onTap: _pickImageAndNavigate,
                child: Container(
                  width: 324 * scale,
                  height: 47 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAE3C6),
                    borderRadius: BorderRadius.circular(14 * scale),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "+ ${l10n.addPhoto}",
                    style: GoogleFonts.nunito(
                      fontSize: 24 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void enterSharePhotoMode() {
    setState(() {
      _isSharePhotoMode = true;
    });
    _analytics.logEvent(
      name: 'share_mode_entered',
      parameters: {
        'activity': _selectedActivity ?? 'unknown',
        'time_range': _timeRange,
      },
    );
  }

  void exitSharePhotoMode() {
    setState(() {
      _isSharePhotoMode = false;
    });
  }

  Future<void> _pickImageAndNavigate() async {
    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (_selectedActivity == null || _selectedPetIndices.isEmpty) return;

      final filteredLogs = _getFilteredLogs();
      final groupedData = _groupLogs(filteredLogs);

      int totalBars;
      if (_timeRange == "daily") {
        totalBars = 24;
      } else if (_timeRange == "weekly") {
        totalBars = _getWeeklyWindow().days;
      } else {
        totalBars = _getMonthlyWindow().days;
      }

      final totalSeconds =
          filteredLogs.fold<int>(0, (sum, log) => sum + log.durationSeconds);
      final selectedPetNames =
          _selectedPetIndices.map((i) => widget.profiles[i].name).toList();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            String translatedActivity;
            if (_selectedActivity == "walk with paws") {
              translatedActivity = l10n.walkWithPaws;
            } else if (_selectedActivity == "cuddle and love") {
              translatedActivity = l10n.cuddleAndLove;
            } else if (_selectedActivity == "playtime for paws") {
              translatedActivity = l10n.playtimeForPaws;
            } else if (_selectedActivity == "snuggle nap") {
              translatedActivity = l10n.snuggleNap;
            } else {
              translatedActivity = l10n.allActivities;
            }

            return SharePhotoPage(
              petNames: selectedPetNames,
              activity: translatedActivity,
              timeRange: _timeRange,
              totalSeconds: totalSeconds,
              chartData: groupedData,
              totalChartBars: totalBars,
              initialPhoto: File(image.path),
            );
          },
        ),
      );
    }
  }

  void navigateToSharePhoto() {
    enterSharePhotoMode();
  }

  Widget _buildBanner(String text, double scale) {
    return Container(
      width: double.infinity,
      height: 50 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFFAE3C6),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 24 * scale,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildPetRow(double scale) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.profiles.asMap().entries.map((entry) {
          int idx = entry.key;
          PetProfile pet = entry.value;
          bool isSelected = _selectedPetIndices.contains(idx);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (_selectedPetIndices.contains(idx)) {
                  _selectedPetIndices.remove(idx);
                } else {
                  _selectedPetIndices.add(idx);
                }
              });
            },
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
                            : Center(child: Icon(Icons.pets, size: 24 * scale)),
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      pet.name,
                      style: GoogleFonts.nunito(
                        fontSize: 14 * scale,
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
    );
  }

  Widget _buildActivityButton(String activityLabel, String activityKey, bool isSelected, double scale) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedActivity == activityKey) {
            _selectedActivity = null;
          } else {
            _selectedActivity = activityKey;
            _currentDayOffset = 0;
            _currentWeekOffset = 0;
            _currentMonthOffset = 0;
            _touchedBarIndex = null;
            _scrollToToday();
            _analytics.logEvent(
              name: 'activity_viewed',
              parameters: {
                'activity': activityKey,
                'time_range': _timeRange,
              },
            );
          }
        });
        widget.onActivitySelected(_selectedActivity != null);
      },
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
            color: isSelected ? Colors.black : Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildChartArea(double scale, double scaleH) {
    final l10n = AppLocalizations.of(context);
    if (_selectedPetIndices.isEmpty) {
      return Container(
        height: 281 * scale,
        alignment: Alignment.center,
        child: Text(
          l10n.chooseYourPet, // or a specific "select a pet" translation if available
          style: GoogleFonts.nunito(
            fontSize: 16 * scale,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final filteredLogs = _getFilteredLogs();
    final groupedData = _groupLogs(filteredLogs);
    double maxVal = groupedData.values.isEmpty
        ? 0
        : groupedData.values.reduce((a, b) => a > b ? a : b);

    int totalBars;
    double barWidth;

    if (_timeRange == "daily") {
      totalBars = 24;
      barWidth = (MediaQuery.of(context).size.width - 32 * scale) / 24;
    } else if (_timeRange == "weekly") {
      final window = _getWeeklyWindow();
      totalBars = window.days;
      barWidth = (MediaQuery.of(context).size.width - 32 * scale) / totalBars;
    } else {
      final window = _getMonthlyWindow();
      totalBars = window.days;
      barWidth = (MediaQuery.of(context).size.width - 32 * scale) / totalBars;
    }

    return Container(
      height: 281 * scale,
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Visibility(
                    visible: _touchedBarIndex == null,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: _buildSummaryBlock(groupedData, scale),
                  ),
                  _buildTimeRangeSelector(scale),
                ],
              ),
              SizedBox(height: 5 * scaleH),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      // swipe right = go back
                      setState(() {
                        if (_timeRange == "daily") {
                          DateTime prevDay = DateTime.now().add(Duration(days: _currentDayOffset - 1));
                          if (!prevDay.isBefore(_chartStartDate)) {
                            _currentDayOffset--;
                          }
                        } else if (_timeRange == "weekly") {
                          // Allow going to previous weeks until _chartStartDate's week
                          DateTime today = DateTime.now();
                          int weekday = today.weekday;
                          DateTime currentMonday = DateTime(today.year, today.month, today.day)
                              .subtract(Duration(days: weekday - 1));
                          DateTime prevWeekMonday = currentMonday
                              .add(Duration(days: (_currentWeekOffset - 1) * 7));
                          DateTime chartStartWeekMonday = _chartStartDate
                              .subtract(Duration(days: _chartStartDate.weekday - 1));
                          if (!prevWeekMonday.isBefore(chartStartWeekMonday)) {
                            _currentWeekOffset--;
                          }
                        } else {
                          // monthly swipe right (backward)
                          DateTime today = DateTime.now();
                          DateTime prevMonthStart = DateTime(
                              today.year, today.month + _currentMonthOffset - 1, 1);
                          DateTime chartStartMonth = DateTime(
                              _chartStartDate.year, _chartStartDate.month, 1);
                          if (!prevMonthStart.isBefore(chartStartMonth)) {
                            _currentMonthOffset--;
                          }
                        }
                        _touchedBarIndex = null;
                      });
                    } else if (details.primaryVelocity! < 0) {
                      // swipe left = go forward
                      setState(() {
                        if (_timeRange == "daily") {
                          if (_currentDayOffset < 0) _currentDayOffset++;
                        } else if (_timeRange == "weekly") {
                          if (_currentWeekOffset < 1) {
                            _currentWeekOffset++;
                          }
                        } else {
                          // monthly swipe left (forward)
                          if (_currentMonthOffset < 1) {
                            _currentMonthOffset++;
                          }
                        }
                        _touchedBarIndex = null;
                      });
                    }
                  },
                  child: _buildChart(groupedData, totalBars, maxVal, scale, false),
                ),
              ),
            ],
          ),
          if (_touchedBarIndex != null)
            _buildFloatingTooltipAndGuide(scale, groupedData, barWidth, maxVal, scaleH),
        ],
      ),
    );
  }

  Widget _buildChart(Map<int, double> groupedData, int totalBars, double maxVal,
      double scale, bool isScrollable) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2 == 0 ? 10 : maxVal * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (unusedA, response) {
            if (response != null && response.spot != null) {
              setState(() {
                _touchedBarIndex = response.spot!.touchedBarGroupIndex;
              });
            } else {
              setState(() {
                _touchedBarIndex = null;
              });
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (unusedA) => Colors.transparent,
            getTooltipItem: (unusedA, unusedB, unusedC, unusedD) => null,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => _getBottomTitles(value, meta, scale),
              reservedSize: 40 * scale,
              interval: 1,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.black.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _getBarGroups(groupedData, totalBars, scale),
      ),
    );
  }

  Widget _buildFloatingTooltipAndGuide(double scale, Map<int, double> groupedData,
      double barWidth, double maxVal, double scaleH) {
    final l10n = AppLocalizations.of(context);
    if (_touchedBarIndex == null || !groupedData.containsKey(_touchedBarIndex)) {
      return const SizedBox.shrink();
    }

    double scrollOffset = 0;
    double barCenterX;
    double chartContentWidth = MediaQuery.of(context).size.width - 32 * scale;
    int totalBars;
    if (_timeRange == "daily") {
      totalBars = 24;
    } else if (_timeRange == "weekly") {
      totalBars = _getWeeklyWindow().days;
    } else {
      totalBars = _getMonthlyWindow().days;
    }
    barCenterX = (_touchedBarIndex! + 0.5) * (chartContentWidth / totalBars);

    double tooltipX = barCenterX - scrollOffset;

    double approxTooltipWidth = 100 * scale;
    double screenPadding = 16 * scale;
    double screenWidth = MediaQuery.of(context).size.width - 2 * screenPadding;

    double clampedX = tooltipX - (approxTooltipWidth / 2);
    clampedX = max(0, min(clampedX, screenWidth - approxTooltipWidth));

    String value = _formatTime(groupedData[_touchedBarIndex!]!.toInt());
    String subLabel = _getTooltipSublabel(_touchedBarIndex!);

    double chartAreaHeight = 281 * scale - 60 * scale - 5 * scaleH - 40 * scale;
    double barHeight = maxVal == 0
        ? 0
        : (groupedData[_touchedBarIndex!]! / (maxVal * 1.2)) * chartAreaHeight;
    double lineBottom = 60 * scale + 5 * scaleH + (chartAreaHeight - barHeight);

    return Stack(
      children: [
        Positioned(
          left: tooltipX,
          top: 40 * scale,
          bottom: 281 * scale - lineBottom,
          child: Container(
            width: 1 * scale,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ),
        Positioned(
          left: clampedX,
          top: 0,
          child: Container(
            width: approxTooltipWidth,
            padding: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.total,
                    style: GoogleFonts.nunito(
                        fontSize: 10 * scale, color: Colors.black.withValues(alpha: 0.5))),
                Text(value,
                    style: GoogleFonts.nunito(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Text(subLabel,
                    style: GoogleFonts.nunito(
                        fontSize: 10 * scale, color: Colors.black.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBlock(Map<int, double> groupedData, double scale) {
    final l10n = AppLocalizations.of(context);

    String label;
    double displayValue;
    double totalSeconds = groupedData.values.fold(0, (sum, val) => sum + val);

    if (_timeRange == "daily") {
      label = l10n.total;
      displayValue = totalSeconds;
    } else if (_timeRange == "weekly") {
      bool isRolling = (_currentWeekOffset == 0);
      label = isRolling ? l10n.total : l10n.average;
      final window = _getWeeklyWindow();
      displayValue = isRolling
          ? totalSeconds
          : (window.days == 0 ? 0 : totalSeconds / window.days);
    } else {
      // Monthly
      bool isRolling = (_currentMonthOffset == 0);
      label = isRolling ? l10n.total : l10n.average;
      final window = _getMonthlyWindow();
      displayValue = isRolling
          ? totalSeconds
          : (window.days == 0 ? 0 : totalSeconds / window.days);
    }

    String value = _formatTime(displayValue.toInt());
    String subLabel;

    if (_timeRange == "daily") {
      DateTime selectedDay = DateTime.now().add(Duration(days: _currentDayOffset));
      if (_currentDayOffset == 0) {
        subLabel = l10n.today;
      } else if (_currentDayOffset == -1) {
        subLabel = l10n.yesterday;
      } else {
        subLabel = DateFormat("EEE, d MMM yy").format(selectedDay);
      }
    } else if (_timeRange == "weekly") {
      final window = _getWeeklyWindow();
      String startDay = window.start.day.toString();
      String endDay = window.end.day.toString();
      String monthEnd = _getMonthName(window.end.month, l10n);
      String yearEnd = DateFormat('yy').format(window.end);

      if (window.start.month == window.end.month) {
        subLabel = "$startDay - $endDay $monthEnd $yearEnd";
      } else {
        String monthStart = _getMonthName(window.start.month, l10n);
        subLabel = "$startDay $monthStart - $endDay $monthEnd $yearEnd";
      }
    } else {
      // Monthly mode
      final window = _getMonthlyWindow();
      String startStr = "${window.start.day} ${_getMonthName(window.start.month, l10n)}";
      String endStr = "${window.end.day} ${_getMonthName(window.end.month, l10n)} ${DateFormat('yy').format(window.end)}";
      subLabel = "$startStr - $endStr";
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 72 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.nunito(
                  fontSize: 10 * scale, color: Colors.black.withValues(alpha: 0.5))),
          Text(value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.nunito(
                  fontSize: 20 * scale, fontWeight: FontWeight.bold, color: Colors.black)),
          Text(subLabel,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.nunito(
                  fontSize: 14 * scale, color: Colors.black.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(double scale) {
    final l10n = AppLocalizations.of(context);
    List<String> ranges = ["daily", "weekly", "monthly"];
    Map<String, String> rangeLabels = {
      "daily": l10n.daily,
      "weekly": l10n.weekly,
      "monthly": l10n.monthly,
    };
    return Container(
      height: 32 * scale,
      padding: EdgeInsets.all(2 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ranges.asMap().entries.map((entry) {
          int idx = entry.key;
          String range = entry.value;
          bool isSelected = _timeRange == range;
          return Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _timeRange = range;
                  _touchedBarIndex = null;
                  _currentDayOffset = 0;
                  _currentWeekOffset = 0;
                  _currentMonthOffset = 0;
                  _scrollToToday();
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16 * scale),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    rangeLabels[range] ?? range,
                    style: GoogleFonts.nunito(
                      fontSize: 14 * scale,
                      color: Colors.black.withValues(alpha: isSelected ? 1.0 : 0.5),
                    ),
                  ),
                ),
              ),
              if (idx < ranges.length - 1)
                Container(
                  width: 1,
                  height: 16 * scale,
                  color: const Color(0xFFFF8146),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<TimerLog> _getFilteredLogs() {
    Set<String> selectedNames =
        _selectedPetIndices.map((i) => widget.profiles[i].name).toSet();

    DateTime rangeStart, rangeEnd;

    if (_timeRange == "daily") {
      DateTime selectedDay = DateTime.now().add(Duration(days: _currentDayOffset));
      rangeStart =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 0, 0, 0);
      rangeEnd =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 23, 59, 59);
    } else if (_timeRange == "weekly") {
      final window = _getWeeklyWindow();
      rangeStart =
          DateTime(window.start.year, window.start.month, window.start.day, 0, 0, 0);
      rangeEnd = DateTime(window.end.year, window.end.month, window.end.day, 23, 59, 59);
    } else {
      final window = _getMonthlyWindow();
      rangeStart =
          DateTime(window.start.year, window.start.month, window.start.day, 0, 0, 0);
      rangeEnd = DateTime(window.end.year, window.end.month, window.end.day, 23, 59, 59);
    }

    return widget.logs.where((log) {
      bool petMatch = selectedNames.every((name) => log.petNames.contains(name));
      bool activityMatch =
          _selectedActivity == "all activities" || log.activity == _selectedActivity;
      bool dateMatch =
          log.startTime.isAfter(rangeStart) && log.startTime.isBefore(rangeEnd);
      return petMatch && activityMatch && dateMatch;
    }).toList();
  }

  Map<int, double> _groupLogs(List<TimerLog> logs) {
    Map<int, double> data = {};

    DateTime? windowStart;
    if (_timeRange == "weekly") {
      windowStart = _getWeeklyWindow().start;
    } else if (_timeRange == "monthly") {
      windowStart = _getMonthlyWindow().start;
    }

    for (var log in logs) {
      int index;
      if (_timeRange == "daily") {
        index = log.startTime.hour;
      } else if (_timeRange == "weekly") {
        index = log.startTime.difference(windowStart!).inDays;
      } else {
        index = log.startTime.difference(windowStart!).inDays;
      }
      if (index >= 0) {
        data[index] = (data[index] ?? 0) + log.durationSeconds;
      }
    }
    return data;
  }

  List<BarChartGroupData> _getBarGroups(
      Map<int, double> data, int totalBars, double scale) {
    double rodWidth;
    double chartContentWidth = MediaQuery.of(context).size.width - 32 * scale;
    rodWidth = (chartContentWidth / totalBars) * 0.7;

    return List.generate(totalBars, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: data[i] ?? 0,
            color: const Color(0xFFFF8146),
            width: rodWidth,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4 * scale)),
          ),
        ],
      );
    });
  }

  Widget _getBottomTitles(double value, TitleMeta meta, double scale) {
    final l10n = AppLocalizations.of(context);
    int val = value.toInt();
    if (val < 0) return const SizedBox();

    if (_timeRange == "daily") {
      String text = val.toString().padLeft(2, '0');
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4 * scale,
        child: Transform.rotate(
          angle: -pi / 2,
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 10 * scale,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    } else if (_timeRange == "weekly") {
      final window = _getWeeklyWindow();
      DateTime date = window.start.add(Duration(days: val));
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4 * scale,
        child: Text(
          _getDayName(date.weekday, l10n),
          style: GoogleFonts.nunito(
            fontSize: 10 * scale,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
      );
    } else {
      // Monthly
      final window = _getMonthlyWindow();
      DateTime date = window.start.add(Duration(days: val));
      int day = date.day;
      bool show = day == 1 || (day >= 2 && (day - 2) % 7 == 0);

      if (show) {
        return SideTitleWidget(
          axisSide: meta.axisSide,
          space: 4 * scale,
          child: Text(
            day.toString(),
            style: GoogleFonts.nunito(
              fontSize: 10 * scale,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        );
      } else {
        return const SizedBox();
      }
    }
  }

  String _getTooltipSublabel(int index) {
    final l10n = AppLocalizations.of(context);
    if (_timeRange == "daily") {
      DateTime selectedDay = DateTime.now().add(Duration(days: _currentDayOffset));
      return "${selectedDay.day} ${_getMonthName(selectedDay.month, l10n)} ${index.toString().padLeft(2, '0')}:00";
    } else if (_timeRange == "weekly") {
      final window = _getWeeklyWindow();
      DateTime date = window.start.add(Duration(days: index));
      return "${date.day} ${_getMonthName(date.month, l10n)}";
    } else {
      final window = _getMonthlyWindow();
      DateTime date = window.start.add(Duration(days: index));
      return "${date.day} ${_getMonthName(date.month, l10n)}";
    }
  }

  String _formatTime(int totalSeconds) {
    final l10n = AppLocalizations.of(context);
    if (totalSeconds < 60) return "$totalSeconds${l10n.unitS}";
    int minutes = totalSeconds ~/ 60;
    if (minutes < 60) return "$minutes${l10n.unitMin}";
    int hours = minutes ~/ 60;
    int remainingMins = minutes % 60;
    return remainingMins > 0 ? "$hours${l10n.unitH} $remainingMins${l10n.unitMin}" : "$hours${l10n.unitH}";
  }

  String _getDayName(int weekday, AppLocalizations l10n) {
    return [
      l10n.dayMon,
      l10n.dayTue,
      l10n.dayWed,
      l10n.dayThu,
      l10n.dayFri,
      l10n.daySat,
      l10n.daySun
    ][weekday - 1];
  }

  String _getMonthName(int month, AppLocalizations l10n) {
    return [
      "",
      l10n.month1,
      l10n.month2,
      l10n.month3,
      l10n.month4,
      l10n.month5,
      l10n.month6,
      l10n.month7,
      l10n.month8,
      l10n.month9,
      l10n.month10,
      l10n.month11,
      l10n.month12
    ][month];
  }
}

class _WeeklyWindow {
  final DateTime start;
  final DateTime end;
  final int days;
  final bool isFirstWeekMode;
  _WeeklyWindow(this.start, this.end, this.days, this.isFirstWeekMode);
}

class _MonthlyWindow {
  final DateTime start;
  final DateTime end;
  final int days;
  _MonthlyWindow(this.start, this.end, this.days);
}
