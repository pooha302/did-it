import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class WidgetIntroService {
  static const String _keyHasShownWidgetIntro = 'has_shown_widget_intro_v2';

  static Future<void> checkAndShowIntro(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_keyHasShownWidgetIntro) ?? false;

    if (!hasShown) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => _WidgetIntroDialog(),
        );
        await prefs.setBool(_keyHasShownWidgetIntro, true);
      }
    }
  }
}

class _WidgetIntroDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lp = context.watch<AppLocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      title: Column(
        children: [
          const Icon(Icons.widgets_rounded, size: 48, color: Colors.blueAccent),
          const SizedBox(height: 16),
          Text(
            lp.tr('widget_intro_title'),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black, 
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Text(
        lp.tr('widget_intro_desc'),
        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            lp.tr('got_it'), 
            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)
          ),
        ),
      ],
    );
  }
}
