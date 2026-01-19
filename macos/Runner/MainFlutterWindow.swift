import Cocoa
import FlutterMacOS
import AppKit

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // 设置字体方法通道
    setupFontChannel(controller: flutterViewController)

    super.awakeFromNib()
  }
  
  private func setupFontChannel(controller: FlutterViewController) {
    let fontChannel = FlutterMethodChannel(
      name: "com.example.f/fonts",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    fontChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getSystemFonts" {
        let fonts = self.getSystemFonts()
        result(fonts)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  private func getSystemFonts() -> [[String: Any]] {
    var fontInfoList: [[String: Any]] = []
    var processedFonts = Set<String>()
    
    // 方法1: 使用 NSFontManager 获取所有可用的字体族
    let allFontFamilies = NSFontManager.shared.availableFontFamilies
    
    // 遍历所有字体族，获取每个族中的具体字体
    for family in allFontFamilies {
      if let fontMembers = NSFontManager.shared.availableMembers(ofFontFamily: family) {
        for fontMember in fontMembers {
          if let fontName = fontMember[0] as? String {
            // 避免重复
            if processedFonts.contains(fontName) {
              continue
            }
            processedFonts.insert(fontName)
            
            // 创建字体实例来检查是否为等宽字体
            if let font = NSFont(name: fontName, size: 12) {
              let isMonospace = font.isFixedPitch
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
      }
    }
    
    // 添加一些常见的系统字体
    let commonSystemFonts = [
      "System", "San Francisco", ".AppleSystemUIFont",
      "Helvetica", "Helvetica Neue", "Times", "Times New Roman",
      "Courier", "Courier New", "Arial", "Avenir", "Menlo",
      "Monaco", "Lucida Grande", "Geneva", "Verdana", "Georgia"
    ]
    
    for fontName in commonSystemFonts {
      if !processedFonts.contains(fontName) {
        if let font = NSFont(name: fontName, size: 12) {
          let isMonospace = font.isFixedPitch
          fontInfoList.append([
            "name": fontName,
            "isMonospace": isMonospace
          ])
        } else {
          let isMonospace = inferMonospaceFromName(fontName)
          fontInfoList.append([
            "name": fontName,
            "isMonospace": isMonospace
          ])
        }
        processedFonts.insert(fontName)
      }
    }
    
    // 按名称排序
    fontInfoList.sort { ($0["name"] as! String) < ($1["name"] as! String) }
    
    return fontInfoList
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
  
  // 辅助方法：从 PostScript name 提取 family name
  private func extractFamilyName(from postScriptName: String) -> String? {
    // 移除常见的后缀（如 -Bold, -Italic, -Regular 等）
    let suffixes = ["-Bold", "-Italic", "-Regular", "-Light", "-Medium", 
                    "-Heavy", "-Black", "-Thin", "-UltraLight", "-Semibold"]
    var familyName = postScriptName
    for suffix in suffixes {
      if familyName.hasSuffix(suffix) {
        familyName = String(familyName.dropLast(suffix.count))
        return familyName.isEmpty ? nil : familyName
      }
    }
    return familyName.isEmpty ? nil : familyName
  }
}
