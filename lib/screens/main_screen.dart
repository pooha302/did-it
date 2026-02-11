import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter/foundation.dart';

import '../providers/action_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/action_view.dart';
import '../widgets/action_stats_view.dart';
import '../screens/goals_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/widget_intro_service.dart';
import '../models/action.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Minimum splash duration of 2 seconds as requested
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }
    
    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  Timer? _midnightTimer;
  Timer? _periodicTimer;
  
  // Keys for tutorial
  final GlobalKey _resetKey = GlobalKey();
  final GlobalKey _actionsKey = GlobalKey();
  final GlobalKey _actionViewKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();
  
  // Tutorial state
  String? _activeTutorialTargetId;
  TutorialCoachMark? _tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85, 
      initialPage: 0,
    );
    
    // Check if tutorial should be shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });

    WidgetsBinding.instance.addObserver(this);
    _setupMidnightTimer();
    _setupPeriodicCheck();
  }

  void _setupPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        context.read<ActionProvider>().checkAndResetDailyData().then((didReset) {
          if (didReset) {
            _showDailyResetNotification();
          }
        });
      }
    });
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasShownTutorial = prefs.getBool('has_shown_tutorial') ?? false;

    if (!hasShownTutorial) {
      // Delay slightly to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 1500), () async {
        if (mounted) await _showTutorial();
      });
    } else {
      // Already saw tutorial, check if we need to show widget intro
      if (mounted) {
         // Tiny delay to ensure layout
         Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) WidgetIntroService.checkAndShowIntro(context);
         });
      }
    }
  }

  Future<void> _showTutorial({bool isReplay = false, int retryCount = 0}) async {
    if (!mounted) return;

    final provider = context.read<ActionProvider>();
    if (provider.showStats) {
      provider.setShowStats(false);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;
    final lp = context.read<AppLocaleProvider>();
    
    if (_actionViewKey.currentContext == null || 
        _resetKey.currentContext == null || 
        _actionsKey.currentContext == null || 
        _helpKey.currentContext == null) {
      if (retryCount < 20) {
        Future.delayed(const Duration(milliseconds: 500), () => _showTutorial(isReplay: isReplay, retryCount: retryCount + 1));
      }
      return;
    }

    late TutorialCoachMark tutorial;
    final List<TargetFocus> targets = [];

    TargetFocus createTarget({
      required String id,
      required GlobalKey key,
      required ContentAlign align,
      required String titleKey,
      required String descKey,
      CrossAxisAlignment crossAlign = CrossAxisAlignment.start,
      ShapeLightFocus shape = ShapeLightFocus.RRect,
    }) {
      return TargetFocus(
        identify: id,
        keyTarget: key,
        alignSkip: Alignment.bottomRight,
        enableOverlayTab: true,
        shape: shape,
        radius: 12,
        contents: [
          TargetContent(
            align: align,
            builder: (context, controller) => GestureDetector(
              onTap: () => controller.next(),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: crossAlign,
                children: [
                  if (align == ContentAlign.bottom) const SizedBox(height: 15),
                  Text(lp.tr(titleKey), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22)),
                  const SizedBox(height: 10),
                  Text(lp.tr(descKey), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  if (align == ContentAlign.top) const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      );
    }

    targets.add(createTarget(
      id: 'action_card',
      key: _actionViewKey,
      align: ContentAlign.bottom,
      titleKey: 'tutorial_record_title',
      descKey: 'tutorial_record_desc',
      shape: ShapeLightFocus.Circle,
    ));

    targets.add(createTarget(
      id: 'reset',
      key: _resetKey,
      align: ContentAlign.bottom,
      titleKey: 'tutorial_reset_title',
      descKey: 'tutorial_reset_desc',
    ));

    targets.add(createTarget(
      id: 'actions',
      key: _actionsKey,
      align: ContentAlign.bottom,
      titleKey: 'tutorial_action_title',
      descKey: 'tutorial_action_desc',
      crossAlign: CrossAxisAlignment.end,
    ));

    targets.add(createTarget(
      id: 'help',
      key: _helpKey,
      align: ContentAlign.top,
      titleKey: 'tutorial_help_title',
      descKey: 'tutorial_help_desc',
    ));

    tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF1A1A40),
      paddingFocus: 10,
      opacityShadow: 0.98,
      hideSkip: kDebugMode ? false : !isReplay,
      focusAnimationDuration: const Duration(milliseconds: 300),
      unFocusAnimationDuration: const Duration(milliseconds: 300),
      skipWidget: const Padding(
        padding: EdgeInsets.only(right: 20, bottom: 10),
        child: Text(
          'SKIP',
          style: TextStyle(color: Color(0xFFCEFF00), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      onFinish: () async {
        setState(() {
          _activeTutorialTargetId = null;
          _tutorialCoachMark = null;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_shown_tutorial', true);
        if (!isReplay) {
          await AnalyticsService.instance.logTutorialComplete('main_screen');
          // Show Widget Intro after tutorial
          if (mounted) await WidgetIntroService.checkAndShowIntro(context);
        }
      },
      onSkip: () {
        setState(() {
          _activeTutorialTargetId = null;
          _tutorialCoachMark = null;
        });
        SharedPreferences.getInstance().then((prefs) => prefs.setBool('has_shown_tutorial', true));
        if (!isReplay) {
          AnalyticsService.instance.logTutorialComplete('main_screen');
          // Show Widget Intro after skip
          if (mounted) WidgetIntroService.checkAndShowIntro(context);
        }
        return true;
      },
      beforeFocus: (target) => setState(() => _activeTutorialTargetId = target.identify),
    );
    
    if (!mounted) return;
    _tutorialCoachMark = tutorial;
    tutorial.show(context: context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _periodicTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app returns to foreground
      context.read<ActionProvider>().checkAndResetDailyData().then((didReset) {
        if (didReset) {
          _showDailyResetNotification();
        }
        // Sync widget data
        if (mounted) context.read<ActionProvider>().syncFromWidget();
      });
      // Reset timer in case it became outdated
      _setupMidnightTimer();
    }
  }

  void _setupMidnightTimer() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(durationUntilMidnight, () {
      if (mounted) {
        context.read<ActionProvider>().checkAndResetDailyData().then((didReset) {
          if (didReset) {
            _showDailyResetNotification();
          }
        });
        // Setup the next day's timer
        _setupMidnightTimer();
      }
    });
  }

  void _showDailyResetNotification() {
    if (!mounted) return;
    
    final localeProvider = context.read<AppLocaleProvider>();
    final overlay = Overlay.of(context);
    
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height * 0.22, // Near the action circle
        left: 32,
        right: 32,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Text(
              localeProvider.tr('daily_reset_msg'),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutCubic).fadeIn(),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove after 7 seconds
    Future.delayed(const Duration(seconds: 7), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showNothingToResetBubble(BuildContext context) {
    final localeProvider = context.read<AppLocaleProvider>();
    final overlay = Overlay.of(context);
    
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 70, // Roughly below the reset button
        left: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.info, size: 14, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  localeProvider.tr('nothing_to_reset'),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(duration: 200.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack)
            .slideY(begin: -0.2, end: 0)
            .then(delay: 1700.ms)
            .fadeOut(duration: 300.ms),
        ),
      ),
    );
    
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _showResetDialog(BuildContext context, ActionProvider provider) {
    if (provider.activeState.count == 0) {
      _showNothingToResetBubble(context);
      return;
    }

    final localeProvider = context.read<AppLocaleProvider>();
    const dialogBg = Color(0xFF161618);

    if (provider.activeState.resetCredits == 0) {
      showGeneralDialog(
        context: context,
        pageBuilder: (ctx, a1, a2) => Container(),
        transitionBuilder: (ctx, a1, a2, child) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
              opacity: a1.value,
              child: AlertDialog(
                backgroundColor: dialogBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                content: Text(localeProvider.tr('resets_exhausted_msg')),
                actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(localeProvider.tr('cancel'), style: const TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      AdService.instance.showRewardedAd(
                        onRewardEarned: () {
                          provider.replenishResets();
                          // Show the confirmation dialog again instead of resetting immediately
                          _showResetDialog(context, provider);
                        },
                      );
                    },
                    child: Text(localeProvider.tr('replenish_resets'), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      );
      return;
    }

    showGeneralDialog(
      context: context,
      pageBuilder: (ctx, a1, a2) => Container(),
      transitionBuilder: (ctx, a1, a2, child) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(
            opacity: a1.value,
            child: AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
              content: Text(localeProvider.tr('reset_confirm')),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localeProvider.tr('cancel'), style: const TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    provider.resetCount();
                    Navigator.pop(context);
                  },
                  child: Text(localeProvider.tr('reset'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  void _showHistoryEditor(
    BuildContext context, 
    ActionProvider provider, 
    ActionConfig action,
    AppLocaleProvider localeProvider,
  ) {
    // Helper to strip time
    DateTime normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

    // Initial setup with normalized dates to avoid assertion errors
    final DateTime now = DateTime.now();
    final DateTime yesterday = normalizeDate(now.subtract(const Duration(days: 1)));
    
    DateTime selectedDate = yesterday;
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();

    // Helper to update text based on date
    void updateCountForDate(DateTime date) {
      final dateStr = date.toIso8601String().split('T')[0];
      final state = provider.actionStates[action.id]!;
      int val = 0;
      
      if (state.history.containsKey(dateStr)) {
        val = state.history[dateStr]!;
      } else if (dateStr == normalizeDate(now).toIso8601String().split('T')[0]) {
        // Even though we block today in picker, this logic handles if we ever allow it
        val = state.count;
      }
      
      controller.text = val.toString();
    }

    // Initialize text
    updateCountForDate(selectedDate);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Custom Theme for Calendar
                    SizedBox(
                      height: 320, // Constrain height for CalendarDatePicker
                      width: 320, // Constrain width
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                                primary: action.color,
                                onPrimary: Colors.black,
                                surface: const Color(0xFF1F2937),
                                onSurface: Colors.white,
                              ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: yesterday,
                          onDateChanged: (newDate) {
                            setState(() {
                              selectedDate = newDate;
                              updateCountForDate(newDate);
                            });
                            // Temporarily unfocus to allow date picking without keyboard popping up annoyance
                            focusNode.unfocus();
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Input Field Container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: focusNode.hasFocus ? action.color : Colors.transparent,
                          width: 1.5
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.edit3, size: 18, color: Colors.white70),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(5),
                              ],
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                border: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(color: Colors.white24),
                              ),
                              onTap: () => setState(() {}), // Trigger rebuild to show focus border
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Ad Guide Text
                    Text(
                      localeProvider.tr('edit_history_ad_guide'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localeProvider.tr('cancel'), style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  onPressed: () {
                    final int? val = int.tryParse(controller.text);
                    if (val != null && val >= 0) {
                      // Show Ad to unlock edit
                      AdService.instance.showEditHistoryAd(
                        onRewardEarned: () {
                          provider.updateHistory(action.id, selectedDate, val);
                          Navigator.pop(context);
                        }
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    localeProvider.tr('save'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActionProvider>();
    final activeAction = provider.activeAction;
    final localeProvider = context.watch<AppLocaleProvider>();
    
    // Calculate active actions list efficiently
    final activeActionsList = provider.activeActions;

    // No active actions empty state
    if (activeActionsList.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.list, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                localeProvider.tr('active_action_none'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF757575), fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoalsScreen()),
                  );
                },
                icon: const Icon(LucideIcons.settings),
                label: Text(localeProvider.tr('settings')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: _activeTutorialTargetId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_activeTutorialTargetId != null) {
          _tutorialCoachMark?.finish();
          setState(() {
            _activeTutorialTargetId = null;
            _tutorialCoachMark = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header (Buttons and Title integrated)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Reset Button
                          provider.showStats
                              ? const SizedBox(width: 46)
                              : Material(
                                  key: _resetKey,
                                  color: Colors.red.withValues(alpha: 0.15),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Colors.redAccent.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      if (_activeTutorialTargetId != null) return;
                                      _showResetDialog(context, provider);
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          const Icon(LucideIcons.rotateCcw, size: 22, color: Colors.white),
                                          Positioned(
                                            right: -6,
                                            bottom: -6,
                                            child: Container(
                                              width: 21,
                                              height: 21,
                                              decoration: BoxDecoration(
                                                color: Colors.deepPurpleAccent,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: const Color(0xFF111827), width: 1.5),
                                              ),
                                              child: Center(
                                                child: provider.activeState.resetCredits > 0
                                                  ? Text(
                                                      '${provider.activeState.resetCredits}',
                                                      strutStyle: const StrutStyle(
                                                        fontSize: 11,
                                                        forceStrutHeight: true,
                                                        height: 1.0,
                                                      ),
                                                      style: GoogleFonts.outfit(
                                                        color: Colors.white, 
                                                        fontSize: 11, 
                                                        fontWeight: FontWeight.w900,
                                                        height: 1.0,
                                                      ),
                                                    )
                                                  : Text(
                                                      'AD',
                                                      strutStyle: const StrutStyle(
                                                        fontSize: 9,
                                                        forceStrutHeight: true,
                                                        height: 1.0,
                                                      ),
                                                      style: GoogleFonts.outfit(
                                                        color: Colors.white, 
                                                        fontSize: 9, 
                                                        fontWeight: FontWeight.w900,
                                                        height: 1.0,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                          // App Title (Current Action)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                localeProvider.tr(activeAction.title),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: activeAction.color, // Use action's color
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          // Goals Button (Top Right)
                          provider.showStats
                              ? Material(
                                  color: const Color(0xFF9D4EDD).withValues(alpha: 0.15),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: const Color(0xFF9D4EDD).withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showHistoryEditor(context, provider, activeAction, localeProvider),
                                    borderRadius: BorderRadius.circular(14),
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(LucideIcons.pencil, size: 22, color: Colors.white),
                                    ),
                                  ),
                                )
                              : Material(
                                  key: _actionsKey,
                                  color: const Color(0xFF9D4EDD).withValues(alpha: 0.15), // Purple
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: const Color(0xFF9D4EDD).withValues(alpha: 0.3), // Purple border
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      if (_activeTutorialTargetId != null) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const GoalsScreen()),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(LucideIcons.list, size: 22, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        key: const ValueKey('main_page_view'),
                        controller: _pageController,
                        onPageChanged: (index) {
                          provider.setActiveActionIndex(index);
                        },
                        itemCount: activeActionsList.length,
                        itemBuilder: (context, index) {
                          final action = activeActionsList[index];
                          final isCurrentCenter = provider.activeActionIndex == index;
                          
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return AnimatedCrossFade(
                                key: ValueKey('crossfade_${action.id}'),
                                duration: const Duration(milliseconds: 300),
                                alignment: Alignment.center,
                                firstChild: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  child: AnimatedScale(
                                    key: ValueKey('record_wrap_${action.id}'),
                                    scale: isCurrentCenter ? 1.0 : 0.9,
                                    duration: const Duration(milliseconds: 300),
                                    child: AnimatedOpacity(
                                      opacity: isCurrentCenter ? 1.0 : 0.5,
                                      duration: const Duration(milliseconds: 300),
                                      child: ActionView(
                                        key: ValueKey('action_view_${action.id}'),
                                        action: action, 
                                        tutorialKey: isCurrentCenter ? _actionViewKey : null,
                                        showTutorialHand: isCurrentCenter && _activeTutorialTargetId == 'action_view',
                                      ),
                                    ),
                                  ),
                                ),
                                secondChild: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  child: ActionStatsView(
                                    key: ValueKey('stats_${action.id}'),
                                    action: action,
                                  ),
                                ),
                                crossFadeState: provider.showStats
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                              );
                            }
                          );
                        },
                      ),
                      
                    ],
                  ),
                ),
                
                // Tutorial Button
                if (!provider.showStats)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Container(
                          key: _helpKey,
                          child: IconButton(
                            onPressed: () => _showTutorial(isReplay: true),
                            icon: const Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  LucideIcons.helpCircle,
                                  color: Colors.white, 
                                  size: 24
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Page Indicator
                if (activeActionsList.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(activeActionsList.length, (index) {
                        final isActive = provider.activeActionIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 10 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive 
                              ? const Color(0xFFCEFF00) 
                              : Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                
                // Bottom Navigation Row
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 34),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stats Mode Button
                       IconButton(
                        onPressed: () async {
                          await HapticFeedback.lightImpact();
                          provider.setShowStats(true);
                          await AnalyticsService.instance.logViewStats(provider.activeAction.id);
                        },
                        icon: Icon(
                          LucideIcons.barChart2,
                          color: provider.showStats ? const Color(0xFFCEFF00) : Colors.white54,
                          size: 24,
                        ),
                      ),
                      
                      // Record Mode Button
                      IconButton(
                        onPressed: () async {
                          await HapticFeedback.lightImpact();
                          provider.setShowStats(false);
                        },
                        icon: Icon(
                          LucideIcons.timer,
                          color: !provider.showStats ? const Color(0xFFCEFF00) : Colors.white54,
                          size: 24,
                        ),
                      ),

                      // Settings Button
                      IconButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                          
                          if (result == 'data_reset') {
                            provider.setShowStats(false); // Ensure targets like _resetKey are visible
                            // Delay slightly to allow screen transition to finish
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) _checkAndShowTutorial();
                            });
                          }
                        },
                        icon: const Icon(
                          LucideIcons.settings,
                          color: Colors.white54,
                          size: 24,
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
}
