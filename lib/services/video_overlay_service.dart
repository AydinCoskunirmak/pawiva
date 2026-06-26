import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class VideoOverlayService {
  static const MethodChannel _channel = MethodChannel('com.pawiva/video_overlay');

  static Future<File?> addOverlayToVideo({
    required String videoPath,
    required String petNames,
    required String activity,
    required String timeValue,
    required String timeRange,
    required List<double> chartValues,
  }) async {
    if (Platform.isIOS) {
      return _addOverlayIOS(
        videoPath: videoPath, petNames: petNames, activity: activity,
        timeValue: timeValue, timeRange: timeRange, chartValues: chartValues,
      );
    } else {
      return _addOverlayAndroid(
        videoPath: videoPath, petNames: petNames, activity: activity,
        timeValue: timeValue, timeRange: timeRange, chartValues: chartValues,
      );
    }
  }

  static Future<File?> _addOverlayIOS({
    required String videoPath, required String petNames, required String activity,
    required String timeValue, required String timeRange, required List<double> chartValues,
  }) async {
    try {
      final String? outputPath = await _channel.invokeMethod('addOverlay', {
        'videoPath': videoPath, 'petNames': petNames, 'activity': activity,
        'timeValue': timeValue, 'timeRange': timeRange, 'chartValues': chartValues,
      });
      if (outputPath != null) return File(outputPath);
      return null;
    } on PlatformException catch (e) {
      print('VideoOverlayService iOS error: ${e.message}');
      return null;
    }
  }

  static Future<File?> _addOverlayAndroid({
    required String videoPath, required String petNames, required String activity,
    required String timeValue, required String timeRange, required List<double> chartValues,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final outputPath = '${dir.path}/pawiva_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final safeNames = petNames.replaceAll("'", "").replaceAll(":", "");
      final safeActivity = activity.replaceAll("'", "").replaceAll(":", "");
      final safeTimeRange = timeRange.replaceAll("'", "").replaceAll(":", "");
      final safeTimeValue = timeValue.replaceAll("'", "").replaceAll(":", "");

      // Font dosyasını app cache'e kopyala
      final fontDest = File(dir.path + '/Nunito-Medium.ttf');
      if (!fontDest.existsSync()) {
        final fontData = await rootBundle.load('assets/fonts/Nunito-Medium.ttf');
        await fontDest.writeAsBytes(fontData.buffer.asUint8List());
      }
      final fontFile = fontDest.path;
      final nanumDest = File(dir.path + '/NanumBrushScript-Regular.ttf');
      if (!nanumDest.existsSync()) {
        final nanumData = await rootBundle.load('assets/fonts/NanumBrushScript-Regular.ttf');
        await nanumDest.writeAsBytes(nanumData.buffer.asUint8List());
      }
      final nanumFile = nanumDest.path;

      // Chart bar'ları drawbox ile (videonun w/h oranına göre - her çözünürlükte tutarlı)
      final chartBoxes = <String>[];
      if (chartValues.isNotEmpty) {
        final maxVal = chartValues.reduce((a, b) => a > b ? a : b);
        const chartLeftR = 0.3;   // w oranı
        const chartTopR = 0.72;   // h oranı
        const chartWidthR = 0.4;  // w oranı
        const chartHeightR = 0.10;// h oranı
        final spacingR = chartWidthR / chartValues.length;
        final barWidthR = spacingR * 0.6;
        for (int i = 0; i < chartValues.length; i++) {
          final normalized = maxVal > 0 ? chartValues[i] / maxVal : 0.0;
          final barHeightR = chartHeightR * normalized;
          // 0 veya çok küçük değerli barları atla (FFmpeg h=0'ı tüm yükseklik sayıyor)
          if (barHeightR < 0.002) continue;
          final leftR = chartLeftR + i * spacingR + (spacingR - barWidthR) / 2;
          final topR = chartTopR + chartHeightR - barHeightR;
          chartBoxes.add(
            "drawbox=x=iw*${leftR.toStringAsFixed(5)}:y=ih*${topR.toStringAsFixed(5)}:"
            "w=iw*${barWidthR.toStringAsFixed(5)}:h=ih*${barHeightR.toStringAsFixed(5)}:"
            "color=0xFF8146:t=fill"
          );
        }
      }
      final chartFilter = chartBoxes.isEmpty ? "" : "${chartBoxes.join(',')},";

      final drawText = [
        "drawtext=fontfile='$fontFile':text='$safeNames':fontcolor=white:fontsize=h*0.035:x=(w-text_w)/2:y=h*0.12:shadowcolor=black:shadowx=2:shadowy=2",
        "drawtext=fontfile='$fontFile':text='$safeActivity':fontcolor=white:fontsize=h*0.032:x=(w-text_w)/2:y=h*0.17:shadowcolor=black:shadowx=2:shadowy=2",
        "drawtext=fontfile='$fontFile':text='$safeTimeRange':fontcolor=white:fontsize=h*0.032:x=(w-text_w)/2:y=h*0.62:shadowcolor=black:shadowx=2:shadowy=2",
        "drawtext=fontfile='$fontFile':text='$safeTimeValue':fontcolor=white:fontsize=h*0.032:x=(w-text_w)/2:y=h*0.66:shadowcolor=black:shadowx=2:shadowy=2",
        "drawtext=fontfile='$nanumFile':text='PAWIVA':fontcolor=white:fontsize=h*0.038:x=(w-text_w)/2:y=h*0.87:shadowcolor=black:shadowx=2:shadowy=2",
      ].join(',');

      final cmd = '-i "$videoPath" -vf "$chartFilter$drawText" '
          '-c:v libx264 -preset ultrafast -pix_fmt yuv420p -c:a copy "$outputPath"';

      final completer = Completer<ReturnCode?>();
      await FFmpegKit.executeAsync(cmd, (session) async {
        final rc = await session.getReturnCode();
        final output = await session.getOutput();
        print('FFmpeg output: $output');
        completer.complete(rc);
      });
      final returnCode = await completer.future;

      if (ReturnCode.isSuccess(returnCode)) {
        return File(outputPath);
      } else {
        print('FFmpeg failed with return code: $returnCode');
        return null;
      }
    } catch (e) {
      print('VideoOverlayService Android error: $e');
      return null;
    }
  }

  static Future<File?> _createChartOverlayPng({
    required Directory dir,
    required List<double> chartValues,
  }) async {
    try {
      // Video boyutuna göre PNG oluştur (1080x1920 varsayım)
      const width = 1080.0;
      const height = 1920.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      if (chartValues.isNotEmpty) {
        final maxVal = chartValues.reduce((a, b) => a > b ? a : b);
        final chartLeft = width * 0.3;
        final chartTop = height * 0.72;
        final chartWidth = width * 0.4;
        final chartHeight = height * 0.10;
        final spacing = chartWidth / chartValues.length;
        final barWidth = spacing * 0.6;

        final barPaint = Paint()
          ..color = const Color(0xFFFF8146)
          ..isAntiAlias = true;

        for (int i = 0; i < chartValues.length; i++) {
          final normalized = maxVal > 0 ? chartValues[i] / maxVal : 0.0;
          final barHeight = chartHeight * normalized;
          final left = chartLeft + i * spacing + (spacing - barWidth) / 2;
          final top = chartTop + chartHeight - barHeight;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(left, top, barWidth, barHeight),
              const Radius.circular(4),
            ),
            barPaint,
          );
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final overlayFile = File('${dir.path}/chart_overlay_${DateTime.now().millisecondsSinceEpoch}.png');
      await overlayFile.writeAsBytes(byteData.buffer.asUint8List());
      return overlayFile;
    } catch (e) {
      print('Chart overlay error: $e');
      return null;
    }
  }
}