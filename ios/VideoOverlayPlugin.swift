import Flutter
import UIKit
import AVFoundation
import CoreImage

public class VideoOverlayPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.pawiva/video_overlay", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(VideoOverlayPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "addOverlay",
          let args = call.arguments as? [String: Any],
          let videoPath = args["videoPath"] as? String,
          let petNames = args["petNames"] as? String,
          let activity = args["activity"] as? String,
          let timeValue = args["timeValue"] as? String,
          let timeRange = args["timeRange"] as? String,
          let chartValues = args["chartValues"] as? [Double]
    else {
      result(FlutterMethodNotImplemented)
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      self.processVideo(videoPath: videoPath, petNames: petNames, activity: activity,
                        timeValue: timeValue, timeRange: timeRange, chartValues: chartValues, result: result)
    }
  }

  private func processVideo(videoPath: String, petNames: String, activity: String,
                            timeValue: String, timeRange: String, chartValues: [Double],
                            result: @escaping FlutterResult) {
    let videoURL = URL(fileURLWithPath: videoPath)
    let asset = AVURLAsset(url: videoURL)

    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      DispatchQueue.main.async { result(FlutterError(code: "NO_VIDEO", message: "No video track", details: nil)) }
      return
    }

    let naturalSize = videoTrack.naturalSize
    let transform = videoTrack.preferredTransform
    let tSize = naturalSize.applying(transform)
    let videoSize = CGSize(width: abs(tSize.width), height: abs(tSize.height))

    let overlayImage = createOverlayImage(size: videoSize, petNames: petNames, activity: activity,
                                          timeValue: timeValue, timeRange: timeRange, chartValues: chartValues)
    guard let overlayCG = overlayImage.cgImage else {
      DispatchQueue.main.async { result(FlutterError(code: "OVERLAY_ERROR", message: "Cannot create overlay", details: nil)) }
      return
    }
    let overlayCI = CIImage(cgImage: overlayCG)

    let filter = CIFilter(name: "CISourceOverCompositing")!
    let videoComp = AVMutableVideoComposition(asset: asset) { request in
      let source = request.sourceImage.clampedToExtent()
      filter.setValue(overlayCI, forKey: kCIInputImageKey)
      filter.setValue(source, forKey: kCIInputBackgroundImageKey)
      let output = filter.outputImage!.cropped(to: request.sourceImage.extent)
      request.finish(with: output, context: nil)
    }
    videoComp.renderSize = videoSize
    videoComp.frameDuration = CMTime(value: 1, timescale: 30)

    let outputURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("pawiva_\(Int(Date().timeIntervalSince1970)).mp4")
    try? FileManager.default.removeItem(at: outputURL)

    guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
      DispatchQueue.main.async { result(FlutterError(code: "EXPORT_ERROR", message: "Cannot create export", details: nil)) }
      return
    }
    export.outputURL = outputURL
    export.outputFileType = .mp4
    export.videoComposition = videoComp

    export.exportAsynchronously {
      DispatchQueue.main.async {
        if export.status == .completed {
          result(outputURL.path)
        } else {
          result(FlutterError(code: "EXPORT_FAILED",
            message: export.error?.localizedDescription ?? "Export failed", details: nil))
        }
      }
    }
  }

  private func createOverlayImage(size: CGSize, petNames: String, activity: String,
                                   timeValue: String, timeRange: String, chartValues: [Double]) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
    defer { UIGraphicsEndImageContext() }
    guard let ctx = UIGraphicsGetCurrentContext() else { return UIImage() }

    let shadow = NSShadow()
    shadow.shadowColor = UIColor.black.withAlphaComponent(0.8)
    shadow.shadowBlurRadius = 3
    shadow.shadowOffset = CGSize(width: 0, height: 1)

    let nunitoBig = UIFont(name: "Nunito-Medium", size: size.width * 0.055) ?? UIFont.boldSystemFont(ofSize: size.width * 0.055)
    let nunitoMed = UIFont(name: "Nunito-Medium", size: size.width * 0.055) ?? UIFont.boldSystemFont(ofSize: size.width * 0.055)
    let nunitoSmall = UIFont(name: "Nunito-Medium", size: size.width * 0.055) ?? UIFont.systemFont(ofSize: size.width * 0.055)
    let nanumFont = UIFont(name: "NanumBrush", size: size.width * 0.055) ?? UIFont.systemFont(ofSize: size.width * 0.055)

    let bigAttrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.white,
      .font: nunitoBig,
      .shadow: shadow
    ]
    let medAttrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.white,
      .font: nunitoMed,
      .shadow: shadow
    ]
    let smallAttrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.white,
      .font: nunitoSmall,
      .shadow: shadow
    ]
    let pawAttrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.white,
      .font: nanumFont,
      .shadow: shadow
    ]

    drawCenteredText(petNames, in: CGRect(x: 0, y: size.height * 0.12, width: size.width, height: size.width * 0.08), attrs: bigAttrs)
    drawCenteredText(activity, in: CGRect(x: 0, y: size.height * 0.17, width: size.width, height: size.width * 0.07), attrs: medAttrs)
    drawCenteredText(timeRange, in: CGRect(x: 0, y: size.height * 0.62, width: size.width, height: size.width * 0.06), attrs: smallAttrs)
    drawCenteredText(timeValue, in: CGRect(x: 0, y: size.height * 0.66, width: size.width, height: size.width * 0.06), attrs: smallAttrs)
    drawChart(ctx: ctx, values: chartValues, frame: CGRect(x: size.width * 0.3, y: size.height * 0.70, width: size.width * 0.4, height: size.height * 0.10))
    drawCenteredText("PAWIVA", in: CGRect(x: 0, y: size.height * 0.87, width: size.width, height: size.width * 0.05), attrs: pawAttrs)

    return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
  }

  private func drawCenteredText(_ text: String, in rect: CGRect, attrs: [NSAttributedString.Key: Any]) {
    let str = NSAttributedString(string: text, attributes: attrs)
    let strSize = str.size()
    let x = rect.minX + (rect.width - strSize.width) / 2
    let y = rect.minY + (rect.height - strSize.height) / 2
    str.draw(at: CGPoint(x: x, y: y))
  }

  private func drawChart(ctx: CGContext, values: [Double], frame: CGRect) {
    guard let maxVal = values.max(), maxVal > 0 else { return }
    let spacing = frame.width / CGFloat(values.count)
    let barWidth = spacing * 0.6
    ctx.setFillColor(UIColor(red: 1.0, green: 0.506, blue: 0.275, alpha: 1.0).cgColor)
    for (i, v) in values.enumerated() {
      let barHeight = frame.height * CGFloat(v / maxVal)
      let x = frame.minX + CGFloat(i) * spacing + (spacing - barWidth) / 2
      let y = frame.maxY - barHeight
      let path = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: barWidth, height: barHeight), cornerRadius: 2)
      ctx.addPath(path.cgPath)
      ctx.fillPath()
    }
  }
}
