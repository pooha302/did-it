import "package:package_info_plus/package_info_plus.dart";
import 'package:didit/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/action_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<AppLocaleProvider>();
    final isDark = context.isDarkMode;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localeProvider.tr('settings'),
          style: TextStyle(
            color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            title: localeProvider.tr('language'),
            value: _getLanguageName(localeProvider.locale, localeProvider),
            icon: LucideIcons.globe,
            isDark: isDark,
            onTap: () => _showLanguagePicker(context),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            title: localeProvider.tr('cloud_backup'),
            value: '',
            icon: LucideIcons.cloud,
            isDark: isDark,
            onTap: () => _showCloudBackupPicker(context),
          ),
          // Development-only: Data Reset
          if (const bool.fromEnvironment('dart.vm.product') == false) ...[
            const SizedBox(height: 12),
            _buildSettingsTile(
              context,
              title: '[DEV] Reset All Data',
              value: '',
              icon: LucideIcons.trash2,
              isDark: isDark,
              onTap: () => _showResetConfirmDialog(context),
            ),
          ],
          const Spacer(),
          Column(
            children: [
              Text(
                'Did it',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFCEFF00).withOpacity(0.8), // More vibrant Lime
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '1.0.0';
                  return Text(
                    'v$version',
                    style: TextStyle(
                      color: const Color(0xFFCEFF00).withOpacity(0.6), // Lime color with opacity
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }


  String _getLanguageName(Locale? locale, AppLocaleProvider lp) {
    if (locale == null) return lp.tr('follow_system');
    final code = locale.languageCode;
    switch (code) {
      case 'ko': return '한국어';
      case 'en': return 'English';
      case 'ja': return '日本語';
      case 'zh': return '简体中文';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      default: return code;
    }
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFCEFF00).withOpacity(0.8), // Vibrant Lime BG
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon, 
            color: Colors.black, // Black icon on Lime background
            size: 20
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 16, color: isDark ? Colors.white30 : Colors.black.withOpacity(0.3)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }


  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final lp = context.watch<AppLocaleProvider>();
        final isDark = context.isDarkMode;

        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                lp.tr('language'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildPickerOption(context, lp.tr('follow_system'), lp.locale == null, isDark, () {
                      context.read<AppLocaleProvider>().setLocale(null);
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, 'English', lp.locale?.languageCode == 'en', isDark, () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('en'));
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, '简体中文', lp.locale?.languageCode == 'zh', isDark, () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('zh'));
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, 'Español', lp.locale?.languageCode == 'es', isDark, () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('es'));
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, '日本語', lp.locale?.languageCode == 'ja', isDark, () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('ja'));
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, '한국어', lp.locale?.languageCode == 'ko', isDark, () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('ko'));
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, 'Français', lp.locale?.languageCode == 'fr', isDark, () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('fr'));
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, 'Deutsch', lp.locale?.languageCode == 'de', isDark, () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('de'));
                      Navigator.pop(context);
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCloudBackupPicker(BuildContext outerContext) {
    showModalBottomSheet(
      context: outerContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final lp = sheetContext.watch<AppLocaleProvider>();
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final provider = sheetContext.read<ActionProvider>();

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lp.tr('cloud_backup'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                _buildCloudOption(
                  sheetContext,
                  title: lp.tr('backup'),
                  subtitle: lp.tr('backup_desc'),
                  icon: LucideIcons.upload,
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(sheetContext); // Close bottom sheet
                    _showLoadingDialog(outerContext, lp.tr('backup'));
                    try {
                      await provider.backupToCloud();
                      if (outerContext.mounted) {
                        Navigator.of(outerContext).pop(); // Close loading dialog
                        _showToast(outerContext, lp.tr('backup_success'), isDark);
                      }
                    } catch (e) {
                      if (outerContext.mounted) {
                        Navigator.of(outerContext).pop(); // Close loading dialog
                        _showToast(outerContext, 'Backup Failed: $e', isDark, isError: true);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildCloudOption(
                  sheetContext,
                  title: lp.tr('restore'),
                  subtitle: lp.tr('restore_desc'),
                  icon: LucideIcons.download,
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(sheetContext); // Close bottom sheet
                    _showLoadingDialog(outerContext, lp.tr('restore'));
                    try {
                      final success = await provider.restoreFromCloud();
                      if (outerContext.mounted) {
                        Navigator.of(outerContext).pop(); // Close loading dialog
                        if (success) {
                          _showToast(outerContext, lp.tr('restore_success'), isDark);
                        } else {
                          _showToast(outerContext, 'No backup found in cloud', isDark, isError: true);
                        }
                      }
                    } catch (e) {
                      if (outerContext.mounted) {
                        Navigator.of(outerContext).pop(); // Close loading dialog
                        _showToast(outerContext, 'Restore Failed: $e', isDark, isError: true);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCloudOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 20, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context, String text) {
    final isDark = context.isDarkMode;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String message, bool isDark, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      ),
    );
  }

  Widget _buildPickerOption(BuildContext context, String title, bool isSelected, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05)) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blueAccent : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, color: Colors.blueAccent, size: 20),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    final isDark = context.isDarkMode;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        content: Text(
          'This will delete all actions, counts, and settings. This action cannot be undone.\n\nAre you sure you want to continue?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _resetAllData(context);
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData(BuildContext context) async {
    final isDark = context.isDarkMode;
    
    // Show loading
    _showLoadingDialog(context, 'Resetting...');
    
    // Reset all providers
    final actionProvider = context.read<ActionProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final localeProvider = context.read<AppLocaleProvider>();
    
    // Reset each provider to defaults
    await actionProvider.resetToDefaults();
    themeProvider.resetToDefaults();
    localeProvider.resetToDefaults();
    
    // Small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show success message
      _showToast(context, 'All data has been reset', isDark);
      
      // Pop back to main screen with result to trigger tutorial
      Navigator.of(context).pop('data_reset');
      
      // The UI will automatically update because providers notified listeners
    }
  }
}
