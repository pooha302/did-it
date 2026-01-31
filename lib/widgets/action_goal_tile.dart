import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/action.dart';
import '../providers/action_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';

class ActionGoalTile extends StatefulWidget {
  final ActionConfig action;
  final bool isActive;
  final int initialGoal;
  final Function(int) onGoalChanged;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final bool isFirst;
  
  // Tutorial keys
  final GlobalKey? tutorialGoalInputKey;
  final GlobalKey? tutorialGoalTypeKey;
  final GlobalKey? tutorialGoalActiveKey;
  final GlobalKey? tutorialGoalReorderKey;
  final GlobalKey? tutorialGoalDeleteKey;

  const ActionGoalTile({
    super.key,
    required this.action,
    required this.isActive,
    required this.initialGoal,
    required this.onGoalChanged,
    required this.onToggle,
    this.onDelete,
    this.isFirst = false,
    this.tutorialGoalInputKey,
    this.tutorialGoalTypeKey,
    this.tutorialGoalActiveKey,
    this.tutorialGoalReorderKey,
    this.tutorialGoalDeleteKey,
  });

  @override
  State<ActionGoalTile> createState() => _ActionGoalTileState();
}

class _ActionGoalTileState extends State<ActionGoalTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialGoal.toString());
  }

  @override
  void didUpdateWidget(ActionGoalTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGoal != widget.initialGoal) {
      _controller.text = widget.initialGoal.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ActionProvider provider = context.watch<ActionProvider>();
    final AppLocaleProvider lp = context.watch<AppLocaleProvider>();
    final actionData = provider.actionStates[widget.action.id];
    if (actionData == null) return const SizedBox.shrink();
    
    final index = provider.actionOrder.indexOf(widget.action.id);
    final isDark = context.isDarkMode;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: widget.isActive ? 1.0 : 0.65,
      child: Container(
        key: widget.tutorialGoalDeleteKey,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isActive 
                ? widget.action.color.withOpacity(0.2) 
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                key: widget.tutorialGoalReorderKey,
                children: [
                  const SizedBox(height: 8),
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      LucideIcons.gripVertical,
                      size: 16,
                      color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.action.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.action.icon, color: widget.action.color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lp.tr(widget.action.title),
                              style: TextStyle(
                                color: widget.action.color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        key: widget.tutorialGoalActiveKey,
                        child: Transform.translate(
                          offset: const Offset(8, 0),
                          child: Transform.scale(
                            scale: 0.9,
                            child: Switch(
                              value: widget.isActive,
                              onChanged: (_) => widget.onToggle(),
                              activeColor: widget.action.color,
                              activeTrackColor: widget.action.color.withOpacity(0.3),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (widget.isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2, left: 0, right: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Goal Type Selection - Button Group Style
                          Container(
                            key: widget.tutorialGoalTypeKey,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _typeButton(
                                  icon: LucideIcons.thumbsUp,
                                  isSelected: actionData.isPositiveGoal,
                                  activeColor: Colors.greenAccent,
                                  onTap: () {
                                    if (!actionData.isPositiveGoal) {
                                      provider.toggleGoalType(widget.action.id);
                                    }
                                  },
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 2),
                                _typeButton(
                                  icon: LucideIcons.thumbsDown,
                                  isSelected: !actionData.isPositiveGoal,
                                  activeColor: Colors.redAccent,
                                  onTap: () {
                                    if (actionData.isPositiveGoal) {
                                      provider.toggleGoalType(widget.action.id);
                                    }
                                  },
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ), // Added missing closing brace and comma
                          Container(
                            key: widget.tutorialGoalInputKey,
                            height: 36,
                            width: 100,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                            ),
                            child: Row(
                              children: [
                                _incrementButton(LucideIcons.minus, () {
                                  final current = int.tryParse(_controller.text) ?? 0;
                                  if (current > 0) {
                                    final newVal = current - 1;
                                    _controller.text = newVal.toString();
                                    widget.onGoalChanged(newVal);
                                  }
                                }, isDark),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      final newGoal = int.tryParse(val) ?? 0;
                                      widget.onGoalChanged(newGoal);
                                    },
                                  ),
                                ),
                                _incrementButton(LucideIcons.plus, () {
                                  final current = int.tryParse(_controller.text) ?? 0;
                                  final newVal = current + 1;
                                  _controller.text = newVal.toString();
                                  widget.onGoalChanged(newVal);
                                }, isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton({
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
    GlobalKey? tutorialKey,
  }) {
    return InkWell(
      key: tutorialKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withOpacity(isDark ? 0.15 : 0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.5) : (isDark ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? activeColor : (isDark ? Colors.white24 : Colors.black26),
        ),
      ),
    );
  }

  Widget _incrementButton(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }
}
