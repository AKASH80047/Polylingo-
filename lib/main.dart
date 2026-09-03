import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/app_providers.dart';
import 'shared/widgets/responsive_scaffold.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/translator/text_translator_screen.dart';
import 'features/pdf_translation/pdf_translation_screen.dart';
import 'features/image_translation/image_translation_screen.dart';
import 'features/document_translation/doc_excel_translation_screen.dart';
import 'features/scanner/camera_scanner_screen.dart';
import 'features/history/history_screen.dart';
import 'features/files/files_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/admin/admin_screen.dart';

void main() {
  runApp(const ProviderScope(child: PolyLingoApp()));
}

class PolyLingoApp extends ConsumerStatefulWidget {
  const PolyLingoApp({super.key});

  @override
  ConsumerState<PolyLingoApp> createState() => _PolyLingoAppState();
}

class _PolyLingoAppState extends ConsumerState<PolyLingoApp> {
  bool _hasCompletedOnboarding = false;
  bool _isAuthenticated = true; // Set default to true for instant demo access

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return MaterialApp(
      title: 'PolyLingo — Translate Anything. Anywhere.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(accentColor),
      darkTheme: AppTheme.getDarkTheme(accentColor),
      themeMode: themeMode,
      home: !_hasCompletedOnboarding
          ? OnboardingScreen(
              onFinish: () {
                setState(() {
                  _hasCompletedOnboarding = true;
                });
              },
            )
          : !_isAuthenticated
              ? AuthScreen(
                  onLoginSuccess: () {
                    setState(() {
                      _isAuthenticated = true;
                    });
                  },
                )
              : ResponsiveScaffold(
                  body: _buildActiveScreen(ref),
                ),
    );
  }

  Widget _buildActiveScreen(WidgetRef ref) {
    final navIndex = ref.watch(navigationIndexProvider);
    final activeTab = ref.watch(activeTranslateTabProvider);

    switch (navIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        // Translate tool router
        switch (activeTab) {
          case 'pdf':
            return const PdfTranslationScreen();
          case 'image':
            return const ImageTranslationScreen();
          case 'docx':
            return const DocExcelTranslationScreen(mode: 'docx');
          case 'xlsx':
            return const DocExcelTranslationScreen(mode: 'xlsx');
          case 'scan':
            return const CameraScannerScreen();
          case 'text':
          default:
            return const TextTranslatorScreen();
        }
      case 2:
        return const HistoryScreen();
      case 3:
        return const FilesScreen();
      case 4:
        return const SettingsScreen();
      case 5:
        return const ProfileScreen();
      case 6:
        return const AdminScreen();
      default:
        return const DashboardScreen();
    }
  }
}
