import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/action_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<AppLocaleProvider>();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localeProvider.tr('settings'),
          style: const TextStyle(
            color: Color(0xFFF3F4F6),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF9CA3AF)),
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
            onTap: () => _showLanguagePicker(context),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            title: localeProvider.tr('cloud_backup'),
            value: '',
            icon: LucideIcons.cloud,
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
              onTap: () => _showResetConfirmDialog(context),
            ),
          ],
          const Spacer(),
          Column(
            children: [
              Text(
                'Did it',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFCEFF00).withValues(alpha: 0.8), // More vibrant Lime
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
                      color: const Color(0xFFCEFF00).withValues(alpha: 0.6), // Lime color with opacity
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
    // Removed unused 'isDark' parameter
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFCEFF00).withValues(alpha: 0.8), // Vibrant Lime BG
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
          style: const TextStyle(
            color: Colors.white,
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
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, size: 16, color: Colors.white30),
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

        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFF1F2937),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                lp.tr('language'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildPickerOption(context, lp.tr('follow_system'), lp.locale == null, () {
                      context.read<AppLocaleProvider>().setLocale(null);
                      context.read<ActionProvider>().updateHomeWidget();
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, 'English', lp.locale?.languageCode == 'en', () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('en'));
                      context.read<ActionProvider>().updateHomeWidget();
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, '简体中文', lp.locale?.languageCode == 'zh', () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('zh'));
                      context.read<ActionProvider>().updateHomeWidget();
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, 'Español', lp.locale?.languageCode == 'es', () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('es'));
                      context.read<ActionProvider>().updateHomeWidget();
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, '日本語', lp.locale?.languageCode == 'ja', () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('ja'));
                      context.read<ActionProvider>().updateHomeWidget();
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, '한국어', lp.locale?.languageCode == 'ko', () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('ko'));
                      context.read<ActionProvider>().updateHomeWidget();
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, 'Français', lp.locale?.languageCode == 'fr', () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('fr'));
                      context.read<ActionProvider>().updateHomeWidget();
                      Navigator.pop(context);
                    }),
                    _buildPickerOption(context, 'Deutsch', lp.locale?.languageCode == 'de', () {
                      context.read<AppLocaleProvider>().setLocale(const Locale('de'));
                      context.read<ActionProvider>().updateHomeWidget();
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
        final provider = sheetContext.read<ActionProvider>();

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1F2937),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lp.tr('cloud_backup'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                _buildCloudOption(
                  sheetContext,
                  title: lp.tr('backup'),
                  icon: LucideIcons.upload,
                  onTap: () async {
                    final confirmed = await _showConfirmDialog(
                      outerContext,
                      title: lp.tr('backup'),
                      message: lp.tr('backup_desc'),
                    );
                    if (!confirmed) return;

                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    if (outerContext.mounted) _showLoadingDialog(outerContext, lp.tr('backup'));
                    try {
                      await provider.backupToCloud();
                      if (outerContext.mounted) {
                        Navigator.of(outerContext).pop();
                        _showToast(outerContext, lp.tr('backup_success'));
                      }
                    } catch (e) {
                      if (outerContext.mounted) {
                        Navigator.of(outerContext).pop();
                        _showToast(outerContext, 'Backup Failed: $e', isError: true);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildCloudOption(
                  sheetContext,
                  title: lp.tr('restore'),
                  icon: LucideIcons.download,
                  onTap: () async {
                    final confirmed = await _showConfirmDialog(
                      outerContext,
                      title: lp.tr('restore'),
                      message: lp.tr('restore_desc'),
                    );
                    if (!confirmed) return;

                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    if (outerContext.mounted) _showLoadingDialog(outerContext, lp.tr('restore'));
                    try {
                      final success = await provider.restoreFromCloud();
                      if (outerContext.mounted) {
                        Navigator.of(outerContext).pop();
                        if (success) {
                          _showToast(outerContext, lp.tr('restore_success'));
                        } else {
                          _showToast(outerContext, 'No backup found in cloud', isError: true);
                        }
                      }
                    } catch (e) {
                      if (outerContext.mounted) {
                        Navigator.of(outerContext).pop();
                        _showToast(outerContext, 'Restore Failed: $e', isError: true);
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
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 20, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
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
                  color: Colors.white.withValues(alpha: 0.9),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
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

  Widget _buildPickerOption(BuildContext context, String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blueAccent : Colors.white70,
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, color: Colors.blueAccent, size: 20),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, {required String title, required String message}) async {
    final lp = context.read<AppLocaleProvider>();

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title, 
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold
          )
        ),
        content: Text(
          message, 
          style: const TextStyle(
            color: Colors.white70,
            height: 1.5,
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              lp.tr('cancel'), 
              style: const TextStyle(color: Colors.white54)
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              lp.tr('confirm'), 
              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        content: const Text(
          'This will delete all actions, counts, and settings. This action cannot be undone.\n\nAre you sure you want to continue?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
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
    
    // Show loading
    _showLoadingDialog(context, 'Resetting...');
    
    final actionProvider = context.read<ActionProvider>();
    final localeProvider = context.read<AppLocaleProvider>();
    
    // Reset each provider to defaults
    await actionProvider.resetToDefaults();
    localeProvider.resetToDefaults();
    
    // Small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (context.mounted) {
      Navigator.of(context).pop();
      
      // Show success message
      _showToast(context, 'All data has been reset');
      
      Navigator.of(context).pop('data_reset');
    }
  }
}
