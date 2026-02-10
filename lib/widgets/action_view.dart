import 'dart:async';
import '../providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/action.dart';
import '../providers/action_provider.dart';
import '../constants/app_colors.dart';

class ActionView extends StatelessWidget {
  final ActionConfig action;
  final GlobalKey? tutorialKey;
  final bool showTutorialHand;

  const ActionView({
    super.key, 
    required this.action, 
    this.tutorialKey,
    this.showTutorialHand = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActionProvider>();
    final localeProvider = context.watch<AppLocaleProvider>();
    final state = provider.actionStates[action.id]!;
    final isPositive = state.isPositiveGoal;
    
    final double count = state.count.toDouble();
    final double goal = state.goal.toDouble();
    final double progress = goal > 0 ? (count / goal).clamp(0.0, 1.0) : 0.0;
    
    final bool isGoalReached = goal > 0 && count >= goal;
    final bool showStatus = goal > 0 && count >= goal;
    final bool isToAvoid = !isPositive;
    final bool isSuccess = isPositive && isGoalReached;
    final bool isWarning = isToAvoid && goal > 0 && count == goal;
    final bool isFailure = isToAvoid && goal > 0 && count > goal;

    final Color statusColor = isSuccess 
        ? AppColors.success
        : (isWarning ? AppColors.warning : AppColors.failure);
    
    final String statusText = isSuccess 
        ? localeProvider.tr('goal_reached') 
        : (isWarning ? localeProvider.tr('limit_reached') : localeProvider.tr('limit_exceeded'));

    final IconData statusIcon = isSuccess 
        ? LucideIcons.sparkles 
        : (isWarning ? LucideIcons.alertCircle : LucideIcons.alertTriangle);

    final baseColor = (isWarning || isFailure) ? statusColor : action.color;

    return Align(
      alignment: const Alignment(0, 0.3),
      child: GestureDetector(
        onTap: () {
          provider.incrementActionCount(action.id);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double size = (constraints.maxWidth < constraints.maxHeight 
                ? constraints.maxWidth 
                : constraints.maxHeight) * 0.85;
            
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [

                // Action Circle Background & Progress Fill
                Container(
                  key: tutorialKey,
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: baseColor.withValues(alpha: 0.25),
                            width: 3.0,
                          ),
                        ),
                      ),
                      ClipPath(
                        clipper: CircleClipper(),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedFractionallySizedBox(
                          key: ValueKey('progress_${action.id}'),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutQuart,
                            widthFactor: 1.0,
                            heightFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: baseColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Foreground Content (Icon & Status)
                SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Status Badge (Just above the icon)
                      if (showStatus)
                        Positioned(
                          top: size * 0.22,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isFailure 
                                  ? const Color(0xFF7F1D1D) // Deep Red/Burgundy for Failure
                                  : (isWarning ? const Color(0xFF1E293B) : statusColor), // Deep Blue for Warning
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isFailure 
                                      ? const Color(0xFF7F1D1D) 
                                      : (isWarning ? const Color(0xFF1E293B) : statusColor)).withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon, 
                                  size: 14, 
                                  color: isSuccess ? Colors.black : Colors.white
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: (isFailure || isWarning) ? Colors.white : Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isSuccess) ...[
                                  const SizedBox(width: 4),
                                  Icon(statusIcon, size: 14, color: Colors.black),
                                ],
                              ],
                            ),
                          ).animate().scale(curve: Curves.elasticOut, duration: 600.ms).fadeIn(),
                        ),

                      // CENTER: Main Icon Container
                      AnimatedContainer(
                        key: ValueKey('icon_box_${action.id}'),
                        duration: const Duration(milliseconds: 300),
                        width: size * 0.22,
                        height: size * 0.22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (progress > 0.5)
                              ? Colors.white.withValues(alpha: 0.18) 
                              : Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: (progress > 0.5) ? Colors.white.withValues(alpha: 0.7) : baseColor.withValues(alpha: 0.35),
                            width: 2.5,
                          ),
                        ),
                        child: Transform.translate(
                          // Offset correction for specific icons
                          offset: action.icon == LucideIcons.coffee 
                              ? Offset(size * 0.006, 0) 
                              : Offset.zero,
                          child: Icon(
                            action.icon,
                            size: size * 0.12,
                            color: (progress > 0.5) ? Colors.white : baseColor,
                          ),
                        ),
                      ),
                      
                      // BOTTOM PART: Count & Unit
                      Positioned(
                        bottom: size * 0.15,
                        child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  state.count.toString(),
                                  style: TextStyle(
                                    fontSize: size * 0.16,
                                    fontWeight: FontWeight.w900,
                                    color: (goal > 0 && (isWarning || isFailure)) 
                                        ? Colors.black 
                                        : (progress > 0.2) 
                                            ? Colors.white 
                                            : const Color(0xFFF3F4F6),
                                    letterSpacing: -1,
                                  ),
                                ).animate(target: count).scale(
                                      begin: const Offset(0.8, 0.8),
                                      end: const Offset(1.1, 1.1),
                                      duration: 200.ms,
                                      curve: Curves.elasticOut,
                                    ).then().scale(
                                      begin: const Offset(1.1, 1.1),
                                      end: const Offset(1.0, 1.0),
                                      duration: 150.ms,
                                    ),
                                if (goal > 0)
                                  Text(
                                    ' / ${state.goal}',
                                    style: TextStyle(
                                      color: (isWarning || isFailure)
                                          ? Colors.black.withValues(alpha: 0.6)
                                          : (progress > 0.2) 
                                              ? Colors.white.withValues(alpha: 0.8) 
                                              : Colors.white38,
                                      fontSize: size * 0.08,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                      ),

                      // Tap Hint (Just above bottom)
                      Positioned(
                        bottom: size * 0.06,
                          child: Text(
                            localeProvider.tr('tap_to_record'),
                            style: TextStyle(
                              color: (progress > 0.1)
                                  ? Colors.white.withValues(alpha: 0.8) 
                                  : Colors.white.withValues(alpha: 0.35),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ),
                    ],
                  ),
                ),

                // Tutorial Hand (Placed last to overlap everything)
                if (showTutorialHand)
                  Center(
                    child: const Icon(
                      Icons.touch_app,
                      color: Colors.orangeAccent,
                      size: 60,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 5, offset: Offset(1, 1)),
                      ],
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 800.ms),
                  ),

                // Last Tap Time (Outside below the circle)
                if (state.lastTapTime != null)
                  Positioned(
                    bottom: -26,
                    child: _LiveRelativeTimeText(
                      lastTapTime: state.lastTapTime!,
                      localeProvider: localeProvider,
                      formatter: _formatLastTapTime,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatLastTapTime(DateTime time, AppLocaleProvider localeProvider) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return localeProvider.tr('just_now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${localeProvider.tr('min_ago')}';
    } else {
      return '${difference.inHours}${localeProvider.tr('hour_ago')}';
    }
  }
}

class _LiveRelativeTimeText extends StatefulWidget {
  final DateTime lastTapTime;
  final AppLocaleProvider localeProvider;
  final TextStyle style;
  final String Function(DateTime, AppLocaleProvider) formatter;

  const _LiveRelativeTimeText({
    required this.lastTapTime,
    required this.localeProvider,
    required this.style,
    required this.formatter,
  });

  @override
  State<_LiveRelativeTimeText> createState() => _LiveRelativeTimeTextState();
}

class _LiveRelativeTimeTextState extends State<_LiveRelativeTimeText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_LiveRelativeTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastTapTime != widget.lastTapTime) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    // Update every second to ensure the relative time switches (e.g. to '1 min ago') promptly
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.formatter(widget.lastTapTime, widget.localeProvider),
      style: widget.style,
    );
  }
}

class CircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
