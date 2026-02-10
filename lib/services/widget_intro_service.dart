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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF1A1A1A),
      title: Column(
        children: [
          const Icon(Icons.widgets_rounded, size: 48, color: Colors.blueAccent),
          const SizedBox(height: 16),
          Text(
            lp.tr('widget_intro_title'),
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Text(
        lp.tr('widget_intro_desc'),
        style: const TextStyle(color: Colors.white70),
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
