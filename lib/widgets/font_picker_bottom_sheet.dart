import 'package:flutter/material.dart';
import '../services/font_service.dart';

class FontPickerBottomSheet extends StatefulWidget {
  final String? currentFont;
  final Function(String) onFontSelected;
  final ScrollController? scrollController;

  const FontPickerBottomSheet({
    super.key,
    required this.currentFont,
    required this.onFontSelected,
    this.scrollController,
  });

  @override
  State<FontPickerBottomSheet> createState() => _FontPickerBottomSheetState();
}

class _FontPickerBottomSheetState extends State<FontPickerBottomSheet>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _selectedFont;

  // 等宽字体和非等宽字体
  List<String> _monospaceFonts = [];
  List<String> _proportionalFonts = [];

  // 分组后的字体（等宽和非等宽分别分组）
  Map<String, List<String>> _monospaceGrouped = {};
  Map<String, List<String>> _proportionalGrouped = {};

  // 排序后的字母键
  List<String> _monospaceKeys = [];
  List<String> _proportionalKeys = [];

  // 滚动控制器和section keys
  final ScrollController _monospaceScrollController = ScrollController();
  final ScrollController _proportionalScrollController = ScrollController();
  final Map<String, GlobalKey> _monospaceSectionKeys = {};
  final Map<String, GlobalKey> _proportionalSectionKeys = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedFont = widget.currentFont;
    _tabController = TabController(length: 2, vsync: this);
    _loadFonts();
  }

  @override
  void dispose() {
    _monospaceScrollController.dispose();
    _proportionalScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFonts() async {
    try {
      // 使用新的方法获取包含等宽信息的字体列表
      final fontInfos = await FontService.getSystemFontsWithInfo();
      setState(() {
        _separateFontsByType(fontInfos);
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      // 如果失败，使用默认字体列表（通过名称推断）
      final defaultFonts = FontService.getDefaultFonts();
      final fontInfos = defaultFonts
          .map(
            (name) => FontInfo(name: name, isMonospace: _isMonospaceFont(name)),
          )
          .toList();
      setState(() {
        _separateFontsByType(fontInfos);
        _isLoading = false;
      });
    }
  }

  void _separateFontsByType(List<FontInfo> fontInfos) {
    _monospaceFonts.clear();
    _proportionalFonts.clear();

    // 使用平台返回的等宽信息来分类
    for (final fontInfo in fontInfos) {
      if (fontInfo.isMonospace) {
        _monospaceFonts.add(fontInfo.name);
      } else {
        _proportionalFonts.add(fontInfo.name);
      }
    }

    // 分别分组
    _groupFontsByFirstLetter(
      _monospaceFonts,
      _monospaceGrouped,
      _monospaceSectionKeys,
    );
    _groupFontsByFirstLetter(
      _proportionalFonts,
      _proportionalGrouped,
      _proportionalSectionKeys,
    );

    // 生成排序后的字母列表
    _monospaceKeys = _getSortedKeys(_monospaceGrouped);
    _proportionalKeys = _getSortedKeys(_proportionalGrouped);
  }

  bool _isMonospaceFont(String fontName) {
    final lowerName = fontName.toLowerCase();
    // 检测等宽字体的关键词
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

  void _groupFontsByFirstLetter(
    List<String> fonts,
    Map<String, List<String>> groupedFonts,
    Map<String, GlobalKey> sectionKeys,
  ) {
    groupedFonts.clear();
    sectionKeys.clear();

    // 按首字母分组
    for (final font in fonts) {
      final firstLetter = font.isNotEmpty ? font[0].toUpperCase() : '#';
      final letter = _isLetter(firstLetter) ? firstLetter : '#';

      if (!groupedFonts.containsKey(letter)) {
        groupedFonts[letter] = [];
        sectionKeys[letter] = GlobalKey();
      }
      groupedFonts[letter]!.add(font);
    }

    // 对每个字母组内的字体进行排序
    for (final key in groupedFonts.keys) {
      groupedFonts[key]!.sort();
    }
  }

  List<String> _getSortedKeys(Map<String, List<String>> groupedFonts) {
    return groupedFonts.keys.toList()..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
  }

  bool _isLetter(String char) {
    return char.length == 1 &&
        char.codeUnitAt(0) >= 65 &&
        char.codeUnitAt(0) <= 90;
  }

  void _scrollToSection(String letter, bool isMonospace) {
    final sectionKeys = isMonospace
        ? _monospaceSectionKeys
        : _proportionalSectionKeys;
    final key = sectionKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择字体',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          // Tab Bar
          if (!_isLoading)
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '等宽字体'),
                Tab(text: '非等宽字体'),
              ],
            ),
          // 字体列表
          if (_isLoading)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 等宽字体
                  _buildFontList(
                    _monospaceGrouped,
                    _monospaceKeys,
                    _monospaceScrollController,
                    _monospaceSectionKeys,
                    true,
                  ),
                  // 非等宽字体
                  _buildFontList(
                    _proportionalGrouped,
                    _proportionalKeys,
                    _proportionalScrollController,
                    _proportionalSectionKeys,
                    false,
                  ),
                ],
              ),
            ),
          // 确认按钮
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedFont != null
                  ? () {
                      FontService.setSelectedFont(_selectedFont!);
                      widget.onFontSelected(_selectedFont!);
                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text('确认选择'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontList(
    Map<String, List<String>> groupedFonts,
    List<String> sortedKeys,
    ScrollController scrollController,
    Map<String, GlobalKey> sectionKeys,
    bool isMonospace,
  ) {
    return Row(
      children: [
        // 字体列表
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: _getTotalItemCount(groupedFonts, sortedKeys),
            itemBuilder: (context, index) {
              final item = _getItemAtIndex(groupedFonts, sortedKeys, index);
              if (item is _SectionHeader) {
                return _buildSectionHeader(
                  item.letter,
                  sectionKeys[item.letter]!,
                );
              } else if (item is _FontItem) {
                return _buildFontItem(item.font);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        // 字母索引
        _buildAlphabetIndex(sortedKeys, isMonospace),
      ],
    );
  }

  int _getTotalItemCount(
    Map<String, List<String>> groupedFonts,
    List<String> sortedKeys,
  ) {
    int count = 0;
    for (final key in sortedKeys) {
      count += 1; // 字母标题
      count += groupedFonts[key]!.length; // 字体项
    }
    return count;
  }

  dynamic _getItemAtIndex(
    Map<String, List<String>> groupedFonts,
    List<String> sortedKeys,
    int index,
  ) {
    int currentIndex = 0;
    for (final key in sortedKeys) {
      if (currentIndex == index) {
        return _SectionHeader(key);
      }
      currentIndex++;

      final fonts = groupedFonts[key]!;
      for (final font in fonts) {
        if (currentIndex == index) {
          return _FontItem(font);
        }
        currentIndex++;
      }
    }
    return null;
  }

  Widget _buildSectionHeader(String letter, GlobalKey key) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFontItem(String font) {
    final isSelected = _selectedFont == font;

    return ListTile(
      title: Text(
        font,
        style: TextStyle(
          fontFamily: font == 'System' ? null : font,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '示例文本 The quick brown fox',
        style: TextStyle(
          fontFamily: font == 'System' ? null : font,
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedFont = font;
        });
      },
    );
  }

  Widget _buildAlphabetIndex(List<String> sortedKeys, bool isMonospace) {
    // 生成 A-Z 的字母列表
    final letters = List.generate(
      26,
      (index) => String.fromCharCode(65 + index),
    );

    return Container(
      width: 28,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: letters.map((letter) {
          final hasFonts = sortedKeys.contains(letter);
          return InkWell(
            onTap: hasFonts
                ? () => _scrollToSection(letter, isMonospace)
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 11,
                  color: hasFonts ? Colors.blue[700] : Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 辅助类用于区分列表项类型
class _SectionHeader {
  final String letter;
  _SectionHeader(this.letter);
}

class _FontItem {
  final String font;
  _FontItem(this.font);
}
