import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pawiva/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class SharePhotoPage extends StatefulWidget {
  final List<String> petNames;
  final String activity;
  final String timeRange; // "daily", "weekly", "monthly"
  final int totalSeconds;
  final Map<int, double> chartData;
  final int totalChartBars;
  final File? initialPhoto;
  final File? initialVideo;

  const SharePhotoPage({
    super.key,
    required this.petNames,
    required this.activity,
    required this.timeRange,
    required this.totalSeconds,
    required this.chartData,
    required this.totalChartBars,
    this.initialPhoto,
    this.initialVideo,
  });

  @override
  State<SharePhotoPage> createState() => _SharePhotoPageState();
}

class _SharePhotoPageState extends State<SharePhotoPage> {
  late File _selectedPhoto;
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isCapturing = false;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedPhoto = widget.initialPhoto ?? File('');
    if (widget.initialVideo != null) {
      _initVideo(widget.initialVideo!);
    }
  }

  Future<void> _initVideo(File videoFile) async {
    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    controller.setLooping(true);
    controller.play();
    setState(() {
      _selectedVideo = videoFile;
      _videoController = controller;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildStrokeText(String text, TextStyle style, double scale) {
    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5 * scale
              ..color = Colors.white,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 63 * scaleH,
            child: SafeArea(
              bottom: false,
              child: _buildPreviewState(scale, l10n),
            ),
          ),
          // Footer pinned to bottom
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

  Widget _buildPreviewState(double scale, AppLocalizations l10n)  {
    String statsValue;
    if (widget.timeRange == "daily") {
      statsValue = _formatTime(widget.totalSeconds, l10n);
    } else {
      int avgSeconds = widget.totalSeconds ~/ (widget.timeRange == "weekly" ? 7 : widget.totalChartBars);
      statsValue = "${_formatTime(avgSeconds, l10n)}${l10n.perDay}";
    }

    double buttonWidth = (324 * scale - 8 * scale) / 2;

    return Column(
      children: [
        SizedBox(height: 12 * scale),
        Expanded(
          child: Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                width: 323 * scale,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15 * scale),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15 * scale),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double frameHeight = constraints.maxHeight;
                      String translatedTimeRange;
                      if (widget.timeRange == "daily") {
                        translatedTimeRange = l10n.dailyFull;
                      } else if (widget.timeRange == "weekly") {
                        translatedTimeRange = l10n.weeklyFull;
                      } else if (widget.timeRange == "monthly") {
                        translatedTimeRange = l10n.monthlyFull;
                      } else {
                        translatedTimeRange = widget.timeRange;
                      }

                      return Stack(
                        children: [
                          _selectedVideo != null &&
                              _videoController != null &&
                              _videoController!.value.isInitialized &&
                              !_isCapturing
                              ? VideoPlayer(_videoController!)
                              : Image.file(
                            _selectedPhoto,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: frameHeight * 0.12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _buildStrokeText(
                                widget.petNames.join(", "),
                                GoogleFonts.nunito(fontSize: 20 * scale, fontWeight: FontWeight.w400),
                                scale,
                              ),
                            ),
                          ),
                          Positioned(
                            top: frameHeight * 0.17,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _buildStrokeText(
                                widget.activity,
                                GoogleFonts.nunito(fontSize: 20 * scale, fontWeight: FontWeight.w400),
                                scale,
                              ),
                            ),
                          ),
                          Positioned(
                            top: frameHeight * 0.62,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _buildStrokeText(
                                translatedTimeRange,
                                GoogleFonts.nunito(fontSize: 20 * scale, fontWeight: FontWeight.w400),
                                scale,
                              ),
                            ),
                          ),
                          Positioned(
                            top: frameHeight * 0.66,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _buildStrokeText(
                                statsValue,
                                GoogleFonts.nunito(fontSize: 20 * scale, fontWeight: FontWeight.w400),
                                scale,
                              ),
                            ),
                          ),
                          Positioned(
                            top: frameHeight * 0.70,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SizedBox(
                                width: 124 * scale,
                                height: 100 * scale,
                                child: BarChart(
                                  BarChartData(
                                    barGroups: _getBarGroups(scale),
                                    backgroundColor: Colors.transparent,
                                    gridData: const FlGridData(show: false),
                                    titlesData: const FlTitlesData(show: false),
                                    borderData: FlBorderData(show: false),
                                    barTouchData: BarTouchData(enabled: false),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: frameHeight * 0.87,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _buildStrokeText(
                                "PAWIVA",
                                GoogleFonts.nanumBrushScript(fontSize: 20 * scale, fontWeight: FontWeight.w400),
                                scale,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCustomButton(
              onTap: _showPickerOptions,
              width: buttonWidth,
              scale: scale,
              icon: Icons.edit_outlined,
              label: "${l10n.change}",
            ),
            SizedBox(width: 8 * scale),
            _buildCustomButton(
              onTap: _sharePhoto,
              width: buttonWidth,
              scale: scale,
              icon: Icons.ios_share,
              label: l10n.share,
            ),
          ],
        ),
        SizedBox(height: 12 * scale),
      ],
    );
  }

  Widget _buildCustomButton({
    required VoidCallback onTap,
    required double width,
    required double scale,
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 47 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFFAE3C6),
          borderRadius: BorderRadius.circular(14 * scale),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18 * scale, color: Colors.black),
            SizedBox(width: 4 * scale),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(double scale) {
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < widget.totalChartBars; i++) {
      double value = widget.chartData[i] ?? 0.0;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: const Color(0xFFFF8146),
              width: (124 * scale) / (widget.totalChartBars * 2),
              borderRadius: BorderRadius.circular(2 * scale),
            ),
          ],
        ),
      );
    }
    return groups;
  }

  void _showPickerOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage();
            },
            child: const Text("Photo"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickVideo();
            },
            child: const Text("Video"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _videoController?.dispose();
      setState(() {
        _selectedPhoto = File(image.path);
        _selectedVideo = null;
        _videoController = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _videoController?.dispose();
      final videoFile = File(video.path);
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      controller.setLooping(true);
      controller.play();
      setState(() {
        _selectedVideo = videoFile;
        _videoController = controller;
      });
    }
  }
  Future<void> _sharePhoto() async {
    final l10n = AppLocalizations.of(context);
    try {
      setState(() => _isCapturing = true);
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('RepaintBoundary not found');
        setState(() => _isCapturing = false);
        return;
      }

      final double targetWidth = 1080;
      final double currentWidth = boundary.size.width;
      final double pixelRatio = targetWidth / currentWidth;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      setState(() => _isCapturing = false);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pawiva_share.png');
      await file.writeAsBytes(bytes);

      List<XFile> files = [XFile(file.path)];
      if (_selectedVideo != null) {
        files.add(XFile(_selectedVideo!.path));
      }

      await Share.shareXFiles(
        files,
        text: l10n.checkOutActivity,
        sharePositionOrigin: Rect.fromCenter(
          center: MediaQuery.of(context).size.center(Offset.zero),
          width: 200,
          height: 200,
        ),
      );
    } catch (e) {
      debugPrint('Share error: $e');
      setState(() => _isCapturing = false);
    }
  }

  String _formatTime(int totalSeconds, AppLocalizations l10n) {
    if (totalSeconds < 60) return "${totalSeconds}${l10n.unitS}";
    int minutes = totalSeconds ~/ 60;
    if (minutes < 60) return "${minutes}${l10n.unitMin}";
    int hours = minutes ~/ 60;
    int remainingMins = minutes % 60;
    return remainingMins > 0
        ? "${hours}${l10n.unitH} ${remainingMins}${l10n.unitMin}"
        : "${hours}${l10n.unitH}";
  }
}