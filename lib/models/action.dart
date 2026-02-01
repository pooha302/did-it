import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';



class ActionConfig {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final Color glowColor;
  final bool isCustom;

  ActionConfig({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.glowColor,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon.codePoint,
        'fontFamily': icon.fontFamily,
        'fontPackage': icon.fontPackage,
        'color': color.value,
        'glowColor': glowColor.value,
        'isCustom': isCustom,
      };

  factory ActionConfig.fromJson(Map<String, dynamic> json) {
    return ActionConfig(
      id: json['id'],
      title: json['title'],
      icon: IconData(
        json['icon'],
        fontFamily: json['fontFamily'] ?? 'Lucide',
        fontPackage: json['fontPackage'] ?? 'lucide_icons',
      ),
      color: Color(json['color']),
      glowColor: Color(json['glowColor']),
      isCustom: json['isCustom'] ?? false,
    );
  }
}

class ActionData {
  int count;
  int resetCredits;
  int goal;
  bool isActive;
  bool isPositiveGoal; // true: achieve, false: avoid
  Map<String, int> history;

  ActionData({
    this.count = 0,
    this.resetCredits = 1,
    this.goal = 0,
    this.isActive = false,
    this.isPositiveGoal = true,
    this.history = const {},
  });

  Map<String, dynamic> toJson() => {
        'count': count,
        'resetCredits': resetCredits,
        'goal': goal,
        'isActive': isActive,
        'isPositiveGoal': isPositiveGoal,
        'history': history,
      };

  factory ActionData.fromJson(Map<String, dynamic> json) {
    return ActionData(
      count: json['count'] ?? 0,
      resetCredits: json['resetCredits'] ?? (json['isResetUsed'] == true ? 0 : 1),
      goal: json['goal'] ?? 0,
      isActive: json['isActive'] ?? false,
      isPositiveGoal: json['isPositiveGoal'] ?? true,
      history: Map<String, int>.from(json['history'] ?? {}),
    );
  }

  ActionData copyWith({
    int? count,
    int? resetCredits,
    int? goal,
    bool? isActive,
    bool? isPositiveGoal,
    Map<String, int>? history,
  }) {
    return ActionData(
      count: count ?? this.count,
      resetCredits: resetCredits ?? this.resetCredits,
      goal: goal ?? this.goal,
      isActive: isActive ?? this.isActive,
      isPositiveGoal: isPositiveGoal ?? this.isPositiveGoal,
      history: history ?? Map.from(this.history),
    );
  }
}

final List<ActionConfig> ACTIONS = [
  ActionConfig(
    id: 'coffee',
    title: 'action_coffee',
    icon: LucideIcons.coffee,
    color: const Color(0xFFD4A574), // Caramel Gold
    glowColor: const Color(0x26D4A574),
  ),
  ActionConfig(
    id: 'water',
    title: 'action_water',
    icon: LucideIcons.glassWater,
    color: const Color(0xFF38BDF8),
    glowColor: const Color(0x2638BDF8),
  ),
  ActionConfig(
    id: 'pill',
    title: 'action_pill',
    icon: LucideIcons.pill,
    color: const Color(0xFFF472B6),
    glowColor: const Color(0x26F472B6),
  ),
  ActionConfig(
    id: 'exercise',
    title: 'action_exercise',
    icon: LucideIcons.dumbbell,
    color: const Color(0xFF2DD4BF),
    glowColor: const Color(0x262DD4BF),
  ),
  ActionConfig(
    id: 'snack',
    title: 'action_snack',
    icon: LucideIcons.candy,
    color: const Color(0xFFFB923C),
    glowColor: const Color(0x26FB923C),
  ),
];
