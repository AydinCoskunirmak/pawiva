import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pawiva/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:pawiva/services/video_overlay_service.dart';

class SharePhotoPage extends StatefulWidget {
  final List<String> petNames;
  final String activity;
  final String timeRange;
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
  bool _isProcessingVideo = false;
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
          // Video işlenirken loading overlay
          if (_isProcessingVideo)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFFFF8146),
                      ),
                      SizedBox(height: 16 * scale),
                      Text(
                        l10n.processingVideo,
                        style: GoogleFonts.nunito(
                          fontSize: 16 * scale,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewState(double scale, AppLocalizations l10n) {
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
                              : (_selectedPhoto.path.isNotEmpty
                              ? Image.file(
                            _selectedPhoto,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                              : Container(color: Colors.grey[200])),
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
                          // Video badge
                          if (_selectedVideo != null)
                            Positioned(
                              top: 8 * scale,
                              right: 8 * scale,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8 * scale),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam, color: Colors.white, size: 12 * scale),
                                    SizedBox(width: 4 * scale),
                                    Text(
                                      'VIDEO',
                                      style: GoogleFonts.nunito(
                                        fontSize: 10 * scale,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
              label: l10n.change,
            ),
            SizedBox(width: 8 * scale),
            _buildCustomButton(
              onTap: _isProcessingVideo ? () {} : _shareContent,
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
    final l10n = AppLocalizations.of(context);
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scale)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo, color: const Color(0xFFFF8146), size: 24 * scale),
                title: Text(l10n.addPhoto, style: GoogleFonts.nunito(fontSize: 16 * scale)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam, color: const Color(0xFFFF8146), size: 24 * scale),
                title: Text(l10n.addVideo, style: GoogleFonts.nunito(fontSize: 16 * scale)),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
            ],
          ),
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
    final result = await FilePicker.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      final videoFile = File(result.files.single.path!);
      _videoController?.dispose();
      await _initVideo(videoFile);
    }
  }

  Future<void> _shareContent() async {
    if (_selectedVideo != null) {
      await _shareVideo();
    } else {
      await _sharePhoto();
    }
  }

  Future<void> _shareVideo() async {
    final l10n = AppLocalizations.of(context);

    setState(() => _isProcessingVideo = true);

    try {
      // Chart değerlerini normalize et
      final maxVal = widget.chartData.values.isEmpty
          ? 1.0
          : widget.chartData.values.reduce((a, b) => a > b ? a : b);
      final chartValues = List.generate(widget.totalChartBars, (i) {
        final val = widget.chartData[i] ?? 0.0;
        return maxVal > 0 ? val / maxVal : 0.0;
      });

      String statsValue;
      if (widget.timeRange == "daily") {
        statsValue = _formatTime(widget.totalSeconds, l10n);
      } else {
        int avgSeconds = widget.totalSeconds ~/ (widget.timeRange == "weekly" ? 7 : widget.totalChartBars);
        statsValue = "${_formatTime(avgSeconds, l10n)}${l10n.perDay}";
      }

      String translatedTimeRange;
      if (widget.timeRange == "daily") {
        translatedTimeRange = l10n.dailyFull;
      } else if (widget.timeRange == "weekly") {
        translatedTimeRange = l10n.weeklyFull;
      } else {
        translatedTimeRange = l10n.monthlyFull;
      }

      debugPrint('Video path: ' + _selectedVideo!.path);
      debugPrint('Video exists: ' + _selectedVideo!.existsSync().toString());
      final outputFile = await VideoOverlayService.addOverlayToVideo(
        videoPath: _selectedVideo!.path,
        petNames: widget.petNames.join(", "),
        activity: widget.activity,
        timeValue: statsValue,
        timeRange: translatedTimeRange,
        chartValues: chartValues,
      );

      setState(() => _isProcessingVideo = false);
      debugPrint('Output path: ' + (outputFile?.path ?? 'NULL'));
      debugPrint('File exists: ' + (outputFile?.existsSync().toString() ?? 'false'));

      if (outputFile == null) {
        _showError(l10n.videoProcessError);
        return;
      }

      await Share.shareXFiles(
        [XFile(outputFile.path)],
        text: l10n.checkOutActivity,
        sharePositionOrigin: Rect.fromCenter(
          center: MediaQuery.of(context).size.center(Offset.zero),
          width: 200,
          height: 200,
        ),
      );
    } catch (e) {
      setState(() => _isProcessingVideo = false);
      _showError(l10n.videoProcessError);
      debugPrint('Video share error: $e');
      debugPrint('Error details: ${e.toString()}');
    }
  }

  Future<void> _sharePhoto() async {
    final l10n = AppLocalizations.of(context);
    try {
      setState(() => _isCapturing = true);
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
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

      await Share.shareXFiles(
        [XFile(file.path)],
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.nunito()),
        backgroundColor: const Color(0xFFFF8146),
      ),
    );
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