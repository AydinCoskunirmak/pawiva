import Flutter
import UIKit
import AVFoundation
import CoreImage
import CoreGraphics

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

    // Overlay bitmap oluştur
    let overlayImage = createOverlayImage(size: videoSize, petNames: petNames, activity: activity,
                                          timeValue: timeValue, timeRange: timeRange, chartValues: chartValues)
    guard let overlayCI = CIImage(image: overlayImage) else {
      DispatchQueue.main.async { result(FlutterError(code: "OVERLAY_ERROR", message: "Cannot create overlay", details: nil)) }
      return
    }

    // Composition
    let comp = AVMutableComposition()
    guard let vTrack = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
      DispatchQueue.main.async { result(FlutterError(code: "COMP_ERROR", message: "Composition error", details: nil)) }
      return
    }
    try? vTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)

    if let aTrack = asset.tracks(withMediaType: .audio).first,
       let aCompTrack = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
      try? aCompTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: aTrack, at: .zero)
    }

    // Core Image filter ile overlay
    let filter = CIFilter(name: "CISourceOverCompositing")!
    let videoComp = AVMutableVideoComposition(asset: comp) { request in
      let source = request.sourceImage.clampedToExtent()
      filter.setValue(overlayCI, forKey: kCIInputImageKey)
      filter.setValue(source, forKey: kCIInputBackgroundImageKey)
      let output = filter.outputImage!.cropped(to: request.sourceImage.extent)
      request.finish(with: output, context: nil)
    }
    videoComp.renderSize = videoSize
    videoComp.frameDuration = CMTime(value: 1, timescale: 30)

    // Export
    let outputURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("pawiva_\(Int(Date().timeIntervalSince1970)).mov")

    guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080) else {
      DispatchQueue.main.async { result(FlutterError(code: "EXPORT_ERROR", message: "Cannot create export", details: nil)) }
      return
    }
    export.outputURL = outputURL
    export.outputFileType = .mov
    // export.videoComposition = videoComp
    export.exportAsynchronously {
      DispatchQueue.main.async {
        if export.status == .completed {
          // Galerie kaydet - debug için
          UISaveVideoAtPathToSavedPhotosAlbum(outputURL.path, nil, nil, nil)
          result(outputURL.path)
        } else {
          result(FlutterError(code: "EXPORT_FAILED", message: export.error?.localizedDescription ?? "Failed", details: nil))
        }
      }
    }
  }

  private func createOverlayImage(size: CGSize, petNames: String, activity: String,
                                   timeValue: String, timeRange: String, chartValues: [Double]) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
    let ctx = UIGraphicsGetCurrentContext()!


    let shadow = NSShadow()
    shadow.shadowColor = UIColor.black
    shadow.shadowBlurRadius = 3
    shadow.shadowOffset = CGSize(width: 0, height: 1)

    let attrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.white,
      .font: UIFont.boldSystemFont(ofSize: size.width * 0.06),
      .shadow: shadow
    ]
    let smallAttrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.white,
      .font: UIFont.boldSystemFont(ofSize: size.width * 0.045),
      .shadow: shadow
    ]
    let tinyAttrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.white,
      .font: UIFont.systemFont(ofSize: size.width * 0.04),
      .shadow: shadow
    ]

    // Pet ismi - üstte (UIKit y=0 üstte)
    drawCenteredText(petNames, in: CGRect(x: 0, y: size.height * 0.10, width: size.width, height: size.width * 0.08), attrs: attrs)
    drawCenteredText(activity, in: CGRect(x: 0, y: size.height * 0.17, width: size.width, height: size.width * 0.07), attrs: smallAttrs)

    // Alt bilgiler
    drawCenteredText("\(timeRange)  \(timeValue)", in: CGRect(x: 0, y: size.height * 0.62, width: size.width, height: size.width * 0.06), attrs: tinyAttrs)
    drawChart(ctx: ctx, values: chartValues, frame: CGRect(x: size.width * 0.3, y: size.height * 0.68, width: size.width * 0.4, height: size.height * 0.08))
    drawCenteredText("PAWIVA", in: CGRect(x: 0, y: size.height * 0.84, width: size.width, height: size.width * 0.05), attrs: tinyAttrs)

    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
  }

  private func drawCenteredText(_ text: String, in rect: CGRect, attrs: [NSAttributedString.Key: Any]) {
    let str = NSAttributedString(string: text, attributes: attrs)
    let size = str.size()
    let x = rect.minX + (rect.width - size.width) / 2
    let y = rect.minY + (rect.height - size.height) / 2
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
      let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
      let path = UIBezierPath(roundedRect: barRect, cornerRadius: 2)
      ctx.addPath(path.cgPath)
      ctx.fillPath()
    }
  }
}
