import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'app_logo.dart';
import '../../core/theme/app_theme.dart';

class ResponsiveScaffold extends ConsumerWidget {
  final Widget body;

  const ResponsiveScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final navIndex = ref.watch(navigationIndexProvider);
    final user = ref.watch(userProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const AppLogo(size: 32),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: Icon(
                    themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).state =
                        themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              child: _buildDesktopSidebar(context, ref, navIndex, user),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildDesktopHeader(context, ref, user),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: navIndex > 4 ? 0 : navIndex,
              onTap: (index) {
                ref.read(navigationIndexProvider.notifier).state = index;
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.g_translate_rounded), label: 'Translate'),
                BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
                BottomNavigationBarItem(icon: Icon(Icons.folder_rounded), label: 'Files'),
                BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
              ],
            ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, WidgetRef ref, user) {
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Translate Anything. Anywhere.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const Spacer(),
          // Accent Color Quick Pickers
          Row(
            children: AppAccentColor.values.map((ac) {
              return GestureDetector(
                onTap: () {
                  ref.read(accentColorProvider.notifier).state = ac;
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ac.primary,
                    shape: BoxShape.circle,
                    border: accent == ac
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: accent == ac
                        ? [BoxShadow(color: ac.primary.withOpacity(0.5), blurRadius: 6)]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              ref.read(navigationIndexProvider.notifier).state = 5; // Profile / Admin
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  child: Text(
                    user?.name.substring(0, 1).toUpperCase() ?? 'A',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Alex Johnson',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      user?.plan ?? 'Pro Plan',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, WidgetRef ref, int navIndex, user) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: AppLogo(size: 34),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            children: [
              _sidebarItem(context, ref, 0, Icons.dashboard_rounded, 'Dashboard', navIndex == 0),
              
              // Translate section with sub-items
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 12, bottom: 6),
                child: Text(
                  'TRANSLATION TOOLS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ),
              _sidebarItem(context, ref, 1, Icons.text_fields_rounded, 'Text Translator', navIndex == 1 && ref.watch(activeTranslateTabProvider) == 'text', subTab: 'text'),
              _sidebarItem(context, ref, 1, Icons.picture_as_pdf_rounded, 'PDF Documents', navIndex == 1 && ref.watch(activeTranslateTabProvider) == 'pdf', subTab: 'pdf'),
              _sidebarItem(context, ref, 1, Icons.image_rounded, 'Images (OCR)', navIndex == 1 && ref.watch(activeTranslateTabProvider) == 'image', subTab: 'image'),
              _sidebarItem(context, ref, 1, Icons.description_rounded, 'Word (DOCX)', navIndex == 1 && ref.watch(activeTranslateTabProvider) == 'docx', subTab: 'docx'),
              _sidebarItem(context, ref, 1, Icons.table_chart_rounded, 'Excel (XLSX)', navIndex == 1 && ref.watch(activeTranslateTabProvider) == 'xlsx', subTab: 'xlsx'),
              _sidebarItem(context, ref, 1, Icons.document_scanner_rounded, 'Camera Scanner', navIndex == 1 && ref.watch(activeTranslateTabProvider) == 'scan', subTab: 'scan'),
              
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 6),
                child: Text(
                  'MANAGEMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ),
              _sidebarItem(context, ref, 2, Icons.history_rounded, 'History', navIndex == 2),
              _sidebarItem(context, ref, 3, Icons.folder_rounded, 'My Files', navIndex == 3),
              _sidebarItem(context, ref, 4, Icons.settings_rounded, 'Settings', navIndex == 4),
              _sidebarItem(context, ref, 5, Icons.admin_panel_settings_rounded, 'Admin Dashboard', navIndex == 5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sidebarItem(BuildContext context, WidgetRef ref, int index, IconData icon, String label, bool isSelected, {String? subTab}) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        selected: isSelected,
        selectedTileColor: primary.withOpacity(0.12),
        leading: Icon(
          icon,
          color: isSelected ? primary : Theme.of(context).iconTheme.color?.withOpacity(0.7),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? primary : Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 14,
          ),
        ),
        onTap: () {
          ref.read(navigationIndexProvider.notifier).state = index;
          if (subTab != null) {
            ref.read(activeTranslateTabProvider.notifier).state = subTab;
          }
        },
      ),
    );
  }
}
