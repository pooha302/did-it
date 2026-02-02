import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:didit/providers/action_provider.dart';
import 'package:didit/providers/locale_provider.dart';
import 'package:didit/providers/theme_provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/analytics_service.dart';

import '../widgets/action_goal_tile.dart';
import '../widgets/add_action_sheet.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GlobalKey _goalInputKey = GlobalKey();
  final GlobalKey _goalTypeKey = GlobalKey();
  final GlobalKey _goalActiveKey = GlobalKey();
  final GlobalKey _goalReorderKey = GlobalKey();
  final GlobalKey _goalDeleteKey = GlobalKey();
  final GlobalKey _goalHelpKey = GlobalKey();

  TutorialCoachMark? tutorialCoachMark;
  bool _isTutorialPreparing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTutorial());
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('tutorial_goals_shown') ?? false;
    
    if (!mounted) return;

    final provider = context.read<ActionProvider>();
    if (!hasShown && provider.actionOrder.isNotEmpty) {
      setState(() => _isTutorialPreparing = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _showTutorial();
    }
  }

  void _showTutorial({bool isReplay = false}) {
    if (!mounted) return;
    
    if (isReplay) {
       setState(() => _isTutorialPreparing = true);
       Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _startTutorialCoachMark(isReplay: true);
       });
       return;
    }
    
    _startTutorialCoachMark(isReplay: isReplay);
  }

  void _startTutorialCoachMark({required bool isReplay}) {
    if (!mounted) return;
    final lp = context.read<AppLocaleProvider>();
    final provider = context.read<ActionProvider>();
    if (provider.actionOrder.isEmpty) return;

    if (_goalActiveKey.currentContext == null || _goalHelpKey.currentContext == null) {
      Future.delayed(const Duration(milliseconds: 300), () => _startTutorialCoachMark(isReplay: isReplay));
      return;
    }

    final List<TargetFocus> targets = [];
    late TutorialCoachMark tutorial;

    /// Helper function to create a standardized TargetFocus.
    /// Includes a GestureDetector to allow advancing by tapping the text area.
    void addTarget({
      required String id,
      required GlobalKey key,
      required String titleKey,
      required String descKey,
      ContentAlign align = ContentAlign.bottom,
      CrossAxisAlignment crossAlign = CrossAxisAlignment.center,
      double paddingFocus = 10,
    }) {
      if (key.currentContext == null) return;
      
      targets.add(TargetFocus(
        identify: id,
        keyTarget: key,
        alignSkip: Alignment.bottomRight,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        paddingFocus: paddingFocus,
        contents: [
          TargetContent(
            align: align,
            builder: (context, controller) => GestureDetector(
              onTap: () => controller.next(), // Advance on tap
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: crossAlign,
                children: [
                  if (align == ContentAlign.bottom) const SizedBox(height: 15),
                  Text(
                    lp.tr(titleKey), 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22)
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lp.tr(descKey), 
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: crossAlign == CrossAxisAlignment.center 
                        ? TextAlign.center 
                        : (crossAlign == CrossAxisAlignment.start ? TextAlign.left : TextAlign.right)
                  ),
                  if (align == ContentAlign.top) const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ));
    }

    // Build the tutorial sequence in strict order
    addTarget(
      id: "active",
      key: _goalActiveKey,
      titleKey: 'tutorial_goal_active_title',
      descKey: 'tutorial_goal_active_desc',
      crossAlign: CrossAxisAlignment.end,
    );

    addTarget(
      id: "input",
      key: _goalInputKey,
      titleKey: 'tutorial_goal_input_title',
      descKey: 'tutorial_goal_input_desc',
    );

    addTarget(
      id: "type",
      key: _goalTypeKey,
      titleKey: 'tutorial_goal_type_title',
      descKey: 'tutorial_goal_type_desc',
      crossAlign: CrossAxisAlignment.start,
    );

    addTarget(
      id: "reorder",
      key: _goalReorderKey,
      titleKey: 'tutorial_goal_reorder_title',
      descKey: 'tutorial_goal_reorder_desc',
      crossAlign: CrossAxisAlignment.start,
      paddingFocus: 20,
    );

    addTarget(
      id: "delete",
      key: _goalDeleteKey,
      titleKey: 'tutorial_goal_delete_title',
      descKey: 'tutorial_goal_delete_desc',
    );

    addTarget(
      id: "help",
      key: _goalHelpKey,
      titleKey: 'tutorial_goal_help_title',
      descKey: 'tutorial_goal_help_desc',
      align: ContentAlign.bottom,
      crossAlign: CrossAxisAlignment.end,
    );

    tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF1A1A40),
      opacityShadow: 0.98,
      hideSkip: !isReplay,
      focusAnimationDuration: const Duration(milliseconds: 300),
      unFocusAnimationDuration: const Duration(milliseconds: 300),
      skipWidget: const Padding(
        padding: EdgeInsets.only(right: 20, bottom: 10),
        child: Text(
          "SKIP",
          style: TextStyle(color: Color(0xFFCEFF00), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      onFinish: () async {
        if (!isReplay) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('tutorial_goals_shown', true);
          AnalyticsService.instance.logTutorialComplete('goals_screen');
        }
        setState(() {
          _isTutorialPreparing = false;
          tutorialCoachMark = null;
        });
      },
      onSkip: () {
        SharedPreferences.getInstance().then((p) => p.setBool('tutorial_goals_shown', true));
        setState(() {
          _isTutorialPreparing = false;
          tutorialCoachMark = null;
        });
        return true;
      },
    );

    tutorial.show(context: context);
    tutorialCoachMark = tutorial;
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActionProvider>();
    final isDark = context.isDarkMode;

    return PopScope(
      canPop: !_isTutorialPreparing,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isTutorialPreparing && tutorialCoachMark != null) {
          tutorialCoachMark?.finish();
          setState(() {
            _isTutorialPreparing = false;
            tutorialCoachMark = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Did it',
          style: GoogleFonts.outfit(
            color: const Color(0xFFCEFF00),
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(key: _goalHelpKey, onPressed: () => _showTutorial(isReplay: true), icon: const Icon(LucideIcons.helpCircle, color: Colors.white)),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
            child: Material(
              color: const Color(0xFF9D4EDD).withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: const Color(0xFF9D4EDD).withOpacity(0.4), width: 1.5)),
              child: InkWell(
                onTap: () => AddActionSheet.show(context),
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox(width: 44, height: 44, child: Center(child: Icon(LucideIcons.plus, color: Colors.white, size: 22))),
              ),
            ),
          ),
        ],
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) => provider.reorderActions(oldIndex, newIndex),
        children: [
          ...provider.allActionsByOrder.map((action) {
            final state = provider.actionStates[action.id];
            if (state == null) return const SizedBox.shrink();
            final index = provider.actionOrder.indexOf(action.id);
            return Dismissible(
              key: ValueKey('dismiss_${action.id}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) => _showDeleteConfirmDialog(context, action.id),
              onDismissed: (_) => provider.deleteAction(action.id),
              background: _buildDismissBackground(),
              child: ActionGoalTile(
                key: ValueKey('tile_${action.id}'),
                action: action,
                isActive: state.isActive,
                initialGoal: state.goal,
                onGoalChanged: (val) => provider.updateActionGoal(action.id, val),
                onToggle: () => provider.toggleActionStatus(action.id),
                onDelete: () => _deleteAction(context, provider, action.id),
                tutorialGoalInputKey: index == 0 ? _goalInputKey : null,
                tutorialGoalTypeKey: index == 0 ? _goalTypeKey : null,
                tutorialGoalActiveKey: index == 0 ? _goalActiveKey : null,
                tutorialGoalReorderKey: index == 0 ? _goalReorderKey : null,
                tutorialGoalDeleteKey: index == 0 ? _goalDeleteKey : null,
              ),
            );
          }).toList(),
        ],
      ),
    ),
  );
}

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(LucideIcons.trash2, color: Colors.white),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context, String actionId) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? const Color(0xFF161618) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Text(context.read<AppLocaleProvider>().tr('delete_action_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.read<AppLocaleProvider>().tr('cancel'), style: const TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.read<AppLocaleProvider>().tr('delete'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _deleteAction(BuildContext context, ActionProvider provider, String actionId) async {
    final confirmed = await _showDeleteConfirmDialog(context, actionId);
    if (confirmed == true) {
      provider.deleteAction(actionId);
    }
  }
}
