import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let fontChannel = FlutterMethodChannel(name: "com.example.f/fonts",
                                           binaryMessenger: controller.binaryMessenger)
    
    fontChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getSystemFonts" {
        let fonts = self.getSystemFonts()
        result(fonts)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func getSystemFonts() -> [[String: Any]] {
    var fontInfoList: [[String: Any]] = []
    var processedFonts = Set<String>()
    
    // Get all font family names
    for family in UIFont.familyNames {
      // Also get individual font names within each family
      for fontName in UIFont.fontNames(forFamilyName: family) {
        if processedFonts.contains(fontName) {
          continue
        }
        processedFonts.insert(fontName)
        
        // 创建字体实例来检查是否为等宽字体
        if let font = UIFont(name: fontName, size: 12) {
          // 在 iOS 上，通过测量字符宽度来判断是否为等宽字体
          let isMonospace = isFontMonospace(font: font)
          fontInfoList.append([
            "name": fontName,
            "isMonospace": isMonospace
          ])
        } else {
          // 如果无法创建字体，使用字体名称推断
          let isMonospace = inferMonospaceFromName(fontName)
          fontInfoList.append([
            "name": fontName,
            "isMonospace": isMonospace
          ])
        }
      }
    }
    
    // Add system default fonts
    let systemFonts = ["System", "San Francisco"]
    for fontName in systemFonts {
      if !processedFonts.contains(fontName) {
        let isMonospace = inferMonospaceFromName(fontName)
        fontInfoList.append([
          "name": fontName,
          "isMonospace": isMonospace
        ])
        processedFonts.insert(fontName)
      }
    }
    
    // 按名称排序
    fontInfoList.sort { ($0["name"] as! String) < ($1["name"] as! String) }
    
    return fontInfoList
  }
  
  // 检测字体是否为等宽字体（通过测量字符宽度）
  private func isFontMonospace(font: UIFont) -> Bool {
    // 测量几个不同字符的宽度
    let testChars = ["i", "m", "W", "0"]
    var widths: [CGFloat] = []
    
    for char in testChars {
      let size = char.size(withAttributes: [.font: font])
      widths.append(size.width)
    }
    
    // 如果所有字符宽度相同（允许很小的误差），则为等宽字体
    if widths.count > 1 {
      let firstWidth = widths[0]
      for width in widths {
        if abs(width - firstWidth) > 0.1 {
          return false
        }
      }
      return true
    }
    return false
  }
  
  // 辅助方法：从字体名称推断是否为等宽字体（作为后备方案）
  private func inferMonospaceFromName(_ fontName: String) -> Bool {
    let lowerName = fontName.lowercased()
    return lowerName.contains("mono") ||
           lowerName.contains("courier") ||
           lowerName == "monospace" ||
           lowerName.contains("console") ||
           lowerName.contains("terminal") ||
           lowerName.contains("code") ||
           lowerName.contains("menlo") ||
           lowerName.contains("consolas")
  }
}
