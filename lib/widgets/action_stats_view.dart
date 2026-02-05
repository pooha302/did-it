import 'package:didit/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/action.dart';
import '../providers/action_provider.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../providers/theme_provider.dart';

class ActionStatsView extends StatelessWidget {
  final ActionConfig action;

  const ActionStatsView({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActionProvider>();
    final localeProvider = context.watch<AppLocaleProvider>();
    final state = provider.actionStates[action.id]!;
    final isDark = context.isDarkMode;
    
    // Get history data and force sync the last day (Today) with current count
    final List<int> data = List.from(provider.getHistoryData(action.id));
    if (data.isNotEmpty) {
      data[data.length - 1] = state.count;
    }
    
    final hasData = data.any((v) => v > 0);
    
    // Average calculation: exclude days with 0 records
    final records = data.where((e) => e > 0);
    final avg = records.isEmpty ? 0.0 : data.reduce((a, b) => a + b) / records.length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Column(
        children: [
          // Stats Summary (Max, Min, Avg)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                 _buildStatItem(
                  context, 
                  localeProvider.tr('max'), 
                  hasData ? "${data.reduce(math.max)}" : "-", 
                  action.color,
                  isDark
                ),
                _buildVerticalDivider(isDark),
                _buildStatItem(
                  context, 
                  localeProvider.tr('min'), 
                  hasData ? "${data.where((e) => e > 0).reduce(math.min)}" : "-", 
                  action.color.withOpacity(0.7),
                  isDark
                ),
                _buildVerticalDivider(isDark),
                _buildStatItem(
                  context, 
                  localeProvider.tr('avg'), 
                  hasData ? avg.toStringAsFixed(1) : "-", 
                  action.color.withOpacity(0.7),
                  isDark
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Period Selector
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...[7, 14, 30].map((period) {
                  final isSelected = provider.statsPeriod == period;
                  return GestureDetector(
                    onTap: () => provider.setStatsPeriod(period),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? action.color : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected ? [
                          BoxShadow(color: action.color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)
                        ] : null,
                      ),
                      child: Text(
                        "$period${localeProvider.tr('days')}",
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
                // Custom Period Button
                Builder(
                  builder: (context) {
                    final isCustom = ![7, 14, 30].contains(provider.statsPeriod);
                    return GestureDetector(
                      onTap: () => _showCustomPeriodDialog(context, provider, localeProvider, action.color),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCustom ? action.color : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isCustom ? [
                            BoxShadow(color: action.color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              isCustom ? "${provider.statsPeriod}${localeProvider.tr('days')}" : localeProvider.tr('custom'),
                              style: TextStyle(
                                color: isCustom ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                fontSize: 12,
                                fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.pencil, 
                              size: 10, 
                              color: isCustom ? Colors.white : (isDark ? Colors.white70 : Colors.black54)
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // The Chart - Expanding to fill available space
          Expanded(
            child: hasData ? SizedBox(
              width: double.infinity,
              child: CustomPaint(
                painter: LineChartPainter(
                  data: data,
                  color: action.color,
                  goal: state.goal,
                  isDark: isDark,
                  goalLabel: localeProvider.tr('goal_label'),
                ),
              ),
            ) : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded, size: 64, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                const SizedBox(height: 16),
                Text(
                  localeProvider.tr('no_data'),
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom padding to ensure chart doesn't touch the bottom indicator too closely
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      height: 30,
      width: 1,
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
    );
  }

  void _showCustomPeriodDialog(BuildContext context, ActionProvider provider, AppLocaleProvider localeProvider, Color themeColor) {
    // If current is a preset, use the saved custom value. If current is already custom, use that.
    final bool isPreset = [7, 14, 30].contains(provider.statsPeriod);
    final String initialValue = isPreset ? provider.customStatsPeriod.toString() : provider.statsPeriod.toString();
    final TextEditingController controller = TextEditingController(text: initialValue);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final int? val = int.tryParse(controller.text);
          final bool isValid = val != null && val >= 7 && val <= 365;
          final bool isNotEmpty = controller.text.isNotEmpty;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(
                    suffixText: localeProvider.tr('days'),
                    hintText: "7-365",
                    errorText: (isNotEmpty && !isValid) ? localeProvider.tr('invalid_period_msg') : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeColor, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localeProvider.tr('cancel'), style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: isValid ? () {
                  provider.setStatsPeriod(val);
                  Navigator.pop(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  disabledBackgroundColor: themeColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: isValid ? 2 : 0,
                ),
                child: Text(
                  localeProvider.tr('create'), 
                  style: TextStyle(color: isValid ? Colors.white : Colors.white60)
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<int> data;
  final Color color;
  final int goal;
  final bool isDark;
  final String goalLabel;

  LineChartPainter({
    required this.data, 
    required this.color, 
    required this.goal,
    required this.isDark,
    required this.goalLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double bottomPadding = 30.0;
    const double topPadding = 5.0;
    const double leftPadding = 25.0; // Restored to previous value
    const double rightPadding = 45.0; // Restored and slightly increased for Goal label
    final double chartHeight = size.height - bottomPadding - topPadding;
    final double chartWidth = size.width - leftPadding - rightPadding;
    
    final baseTextColor = isDark ? Colors.white : Colors.black;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(leftPadding, topPadding + chartHeight * 0.2),
        Offset(leftPadding, topPadding + chartHeight),
        [color.withOpacity(0.3), color.withOpacity(0.0)],
      )
      ..style = PaintingStyle.fill;

    if (data.isEmpty || chartWidth <= 0) return;

    final double dataMax = data.reduce((a, b) => a > b ? a : b).toDouble();
    final double absoluteMax = math.max(dataMax, goal.toDouble());
    final double maxVal = absoluteMax.clamp(1.0, double.infinity) * 1.2; // Add 20% padding for headroom
    final widthStep = data.length > 1 ? chartWidth / (data.length - 1) : 0.0;

    final path = Path();
    final fillPath = Path();

    // Calculate dates for x-axis
    final today = DateTime.now();
    final dateLabelsCount = data.length > 14 ? 5 : (data.length > 7 ? 4 : data.length);
    final skip = (data.length / dateLabelsCount).ceil();

    for (int i = 0; i < data.length; i++) {
        final x = leftPadding + (i * widthStep);
        final y = topPadding + chartHeight - (data[i] / maxVal * chartHeight);
        
        if (i == 0) {
            path.moveTo(x, y);
            fillPath.moveTo(x, topPadding + chartHeight);
            fillPath.lineTo(x, y);
        } else {
            final prevX = leftPadding + ((i - 1) * widthStep);
            final prevY = topPadding + chartHeight - (data[i - 1] / maxVal * chartHeight);
            
            path.cubicTo(
                prevX + widthStep / 2, prevY,
                x - widthStep / 2, y,
                x, y
            );
            fillPath.cubicTo(
                prevX + widthStep / 2, prevY,
                x - widthStep / 2, y,
                x, y
            );
        }

        if (i == data.length - 1) {
            fillPath.lineTo(x, topPadding + chartHeight);
            fillPath.close();
        }

        // Draw Date labels (M.d format)
        if (i % skip == 0 || i == data.length - 1) {
          final date = today.subtract(Duration(days: data.length - 1 - i));
          final label = "${date.month}.${date.day}";
          
          final dateLabelPainter = TextPainter(
            text: TextSpan(
              text: label,
              style: TextStyle(
                color: baseTextColor.withOpacity(0.3),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          )..layout();

          // Avoid labels going out of bounds
          double xPos = x - dateLabelPainter.width / 2;
          if (i == 0) xPos = x;
          if (i == data.length - 1) xPos = x - dateLabelPainter.width;

          dateLabelPainter.paint(
            canvas, 
            Offset(xPos, topPadding + chartHeight + 8)
          );
        }
    }

    // Draw grid lines and Y-axis labels based on actual values
    final gridPaint = Paint()
      ..color = baseTextColor.withOpacity(0.05)
      ..strokeWidth = 1;

    // Define label values: 0, Max, and a few steps in between
    final List<double> yValues = [0, maxVal / 2, maxVal];
    
    for (final val in yValues) {
      final y = topPadding + chartHeight - (val / maxVal * chartHeight);
      canvas.drawLine(Offset(leftPadding, y), Offset(leftPadding + chartWidth, y), gridPaint);
      
      final yLabelPainter = TextPainter(
        text: TextSpan(
          text: "${val.round()}",
          style: TextStyle(
            color: baseTextColor.withOpacity(0.3),
            fontSize: 10,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      
      yLabelPainter.paint(
        canvas, 
        Offset(leftPadding - yLabelPainter.width - 8, y - yLabelPainter.height / 2)
      );
    }

    // Draw Goal Line
    if (goal > 0) {
      final goalY = topPadding + chartHeight - (goal / maxVal * chartHeight);
      if (goalY >= topPadding && goalY <= topPadding + chartHeight) {
        final goalPaint = Paint()
          ..color = color.withOpacity(0.4)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        
        double dashWidth = 6, dashSpace = 4, startX = leftPadding;
        while (startX < leftPadding + chartWidth) {
          canvas.drawLine(Offset(startX, goalY), Offset(startX + dashWidth, goalY), goalPaint);
          startX += dashWidth + dashSpace;
        }

        // Draw Goal Label back on the right
        final goalLabelPainter = TextPainter(
          text: TextSpan(
            text: goalLabel,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        
        goalLabelPainter.paint(
          canvas, 
          Offset(leftPadding + chartWidth + 6, goalY - goalLabelPainter.height / 2)
        );
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
