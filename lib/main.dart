import 'package:flutter/material.dart';
import 'services/font_service.dart';
import 'widgets/font_picker_bottom_sheet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _selectedFont;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedFont();
  }

  Future<void> _loadSelectedFont() async {
    final font = await FontService.getSelectedFont();
    setState(() {
      _selectedFont = font;
      _isLoading = false;
    });
  }

  void _onFontSelected(String fontFamily) {
    setState(() {
      _selectedFont = fontFamily;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    final theme = FontService.applyFontToTheme(baseTheme, _selectedFont);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: theme,
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        onFontChanged: _onFontSelected,
        currentFont: _selectedFont,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.onFontChanged,
    this.currentFont,
  });

  final String title;
  final Function(String) onFontChanged;
  final String? currentFont;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _showFontPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => FontPickerBottomSheet(
          currentFont: widget.currentFont,
          scrollController: scrollController,
          onFontSelected: (font) {
            widget.onFontChanged(font);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: '选择字体',
            onPressed: _showFontPicker,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
