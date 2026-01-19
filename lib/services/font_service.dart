import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 字体信息类
class FontInfo {
  final String name;
  final bool isMonospace;

  FontInfo({required this.name, required this.isMonospace});

  factory FontInfo.fromMap(Map<dynamic, dynamic> map) {
    return FontInfo(
      name: map['name'] as String,
      isMonospace: map['isMonospace'] as bool? ?? false,
    );
  }
}

class FontService {
  static const String _channelName = 'com.example.f/fonts';
  static const String _fontPreferenceKey = 'selected_font_family';
  static const MethodChannel _channel = MethodChannel(_channelName);

  // 获取系统字体列表（包含等宽信息）
  static Future<List<FontInfo>> getSystemFontsWithInfo() async {
    try {
      final List<dynamic> fontsData = await _channel.invokeMethod('getSystemFonts');
      return fontsData
          .map((font) => FontInfo.fromMap(font as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      // 如果平台通道失败，返回默认字体列表（使用名称推断）
      return getDefaultFonts()
          .map((name) => FontInfo(
                name: name,
                isMonospace: _inferMonospaceFromName(name),
              ))
          .toList();
    }
  }

  // 获取系统字体列表（仅名称，保持向后兼容）
  static Future<List<String>> getSystemFonts() async {
    try {
      final fonts = await getSystemFontsWithInfo();
      return fonts.map((f) => f.name).toList();
    } catch (e) {
      return getDefaultFonts();
    }
  }

  // 从字体名称推断是否为等宽字体（作为后备方案）
  static bool _inferMonospaceFromName(String fontName) {
    final lowerName = fontName.toLowerCase();
    return lowerName.contains('mono') ||
        lowerName.contains('courier') ||
        lowerName == 'monospace' ||
        lowerName.contains('console') ||
        lowerName.contains('terminal') ||
        lowerName.contains('code') ||
        lowerName.contains('menlo') ||
        lowerName.contains('consolas') ||
        lowerName.contains('source code') ||
        lowerName.contains('fira code') ||
        lowerName.contains('jetbrains mono');
  }

  // 获取默认字体列表（用于桌面平台或平台通道失败时）
  static List<String> getDefaultFonts() {
    return [
      'System',
      'Roboto',
      'Arial',
      'Helvetica',
      'Times New Roman',
      'Courier New',
      'Verdana',
      'Georgia',
      'Palatino',
      'Garamond',
      'Bookman',
      'Comic Sans MS',
      'Trebuchet MS',
      'Arial Black',
      'Impact',
      'Lucida Console',
      'Tahoma',
      'Courier',
      'sans-serif',
      'serif',
      'monospace',
    ];
  }

  // 获取用户选择的字体
  static Future<String?> getSelectedFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fontPreferenceKey);
    } catch (e) {
      return null;
    }
  }

  // 保存用户选择的字体
  static Future<bool> setSelectedFont(String fontFamily) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_fontPreferenceKey, fontFamily);
    } catch (e) {
      return false;
    }
  }

  // 清除字体设置（恢复默认）
  static Future<bool> clearSelectedFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_fontPreferenceKey);
    } catch (e) {
      return false;
    }
  }

  // 根据选择的字体创建ThemeData
  static ThemeData applyFontToTheme(ThemeData baseTheme, String? fontFamily) {
    if (fontFamily == null || fontFamily.isEmpty || fontFamily == 'System') {
      return baseTheme;
    }

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        fontFamily: fontFamily,
      ),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(
        fontFamily: fontFamily,
      ),
    );
  }
}
