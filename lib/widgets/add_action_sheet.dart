import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/action_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';

class AddActionSheet extends StatefulWidget {
  const AddActionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddActionSheet(),
    );
  }

  @override
  State<AddActionSheet> createState() => _AddActionSheetState();
}

class _AddActionSheetState extends State<AddActionSheet> {
  final _titleController = TextEditingController();
  
  final suggestedColors = [
    const Color(0xFFFF5757), const Color(0xFFFF6B6B),
    const Color(0xFFFF8C42), const Color(0xFFF8B500),
    const Color(0xFFFFD93D), const Color(0xFFD4A574),
    const Color(0xFF6BCF7F), const Color(0xFF5FD3BC),
    const Color(0xFF4ECDC4), const Color(0xFF45B7D1),
    const Color(0xFF5DADE2), const Color(0xFF7B68EE),
    const Color(0xFF9D4EDD), const Color(0xFFE056FD),
    const Color(0xFFFF6AC1), const Color(0xFFFF85A2),
  ];

  final icons = [
    LucideIcons.coffee, LucideIcons.glassWater, LucideIcons.utensils, LucideIcons.apple,
    LucideIcons.dumbbell, LucideIcons.bike, LucideIcons.footprints, LucideIcons.heart,
    LucideIcons.book, LucideIcons.pencil, LucideIcons.laptop, LucideIcons.brain,
    LucideIcons.pill, LucideIcons.bed, LucideIcons.bath, LucideIcons.home,
    LucideIcons.shoppingCart, LucideIcons.trash2, LucideIcons.music, LucideIcons.camera,
    LucideIcons.gamepad2, LucideIcons.palette, LucideIcons.smile, LucideIcons.clock,
  ];

  late Color selectedColor;
  late IconData selectedIcon;
  bool isPositiveMode = true;

  @override
  void initState() {
    super.initState();
    final random = Random();
    selectedColor = suggestedColors[random.nextInt(suggestedColors.length)];
    selectedIcon = icons[random.nextInt(icons.length)];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<AppLocaleProvider>();
    final provider = context.read<ActionProvider>();
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: lp.tr('action_placeholder'),
                hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.white10 : Colors.black12),
            const SizedBox(height: 12),

            SizedBox(
              height: 120,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: icons.map((icon) {
                  final isSelected = selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? selectedColor.withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: selectedColor.withOpacity(0.5), width: 1.5) : null,
                      ),
                      child: Icon(icon, color: isSelected ? selectedColor : (isDark ? Colors.white70 : Colors.black54), size: 18),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.white10 : Colors.black12),
            const SizedBox(height: 12),

            SizedBox(
              height: 80,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestedColors.map((color) {
                  final isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black87, width: 2.5) : null,
                        boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)] : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.white10 : Colors.black12),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFFD1D5DB).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modeButton(LucideIcons.thumbsUp, isPositiveMode, () => setState(() => isPositiveMode = true), const Color(0xFF6BCF7F)),
                  const SizedBox(width: 4),
                  _modeButton(LucideIcons.thumbsDown, !isPositiveMode, () => setState(() => isPositiveMode = false), Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.trim().isNotEmpty) {
                    provider.addCustomAction(
                      _titleController.text.trim(),
                      selectedIcon,
                      selectedColor,
                      isPositiveGoal: isPositiveMode,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9D4EDD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(lp.tr('add_action_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(IconData icon, bool isSelected, VoidCallback onTap, Color activeColor) {
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? activeColor.withOpacity(0.2) : activeColor.withOpacity(0.1)) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? activeColor.withOpacity(0.5) : (isDark ? Colors.white10 : Colors.black12)),
        ),
        child: Icon(icon, size: 18, color: isSelected ? activeColor : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563))),
      ),
    );
  }
}
