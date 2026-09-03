import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // Header Greeting
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, ${user?.name ?? 'Alex'} 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'What would you like to translate today?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Hero Landing Banner
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.85),
                const Color(0xFF4F46E5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✨ AI-POWERED PLATFORM',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Translate Anything. Anywhere.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Translate text, PDFs, images, DOCX and Excel spreadsheets preserving formulas & layout visual structure.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                      ),
                      onPressed: () {
                        ref.read(navigationIndexProvider.notifier).state = 1; // Translate tab
                        ref.read(activeTranslateTabProvider.notifier).state = 'pdf';
                      },
                      child: const Text('Start Translating Document'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        const Text(
          'CORE TRANSLATION TOOLS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // 6 Quick Actions Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 600 ? 2 : 1;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildActionCard(
                  context,
                  ref,
                  title: 'Translate Text',
                  subtitle: 'Instant multilingual text translation',
                  icon: Icons.text_fields_rounded,
                  color: const Color(0xFF2563EB),
                  subTab: 'text',
                ),
                _buildActionCard(
                  context,
                  ref,
                  title: 'Translate PDF',
                  subtitle: '25-page layout & visual preservation',
                  icon: Icons.picture_as_pdf_rounded,
                  color: const Color(0xFF8B5CF6),
                  subTab: 'pdf',
                ),
                _buildActionCard(
                  context,
                  ref,
                  title: 'Translate Image',
                  subtitle: 'OCR bounding box & visual overlay',
                  icon: Icons.image_rounded,
                  color: const Color(0xFF10B981),
                  subTab: 'image',
                ),
                _buildActionCard(
                  context,
                  ref,
                  title: 'Translate Word',
                  subtitle: 'Preserve DOCX headers & tables',
                  icon: Icons.description_rounded,
                  color: const Color(0xFF0284C7),
                  subTab: 'docx',
                ),
                _buildActionCard(
                  context,
                  ref,
                  title: 'Translate Excel',
                  subtitle: 'Translate text, preserve =SUM() formulas',
                  icon: Icons.table_chart_rounded,
                  color: const Color(0xFF059669),
                  subTab: 'xlsx',
                ),
                _buildActionCard(
                  context,
                  ref,
                  title: 'Scan Document',
                  subtitle: 'Camera capture & OCR document scan',
                  icon: Icons.document_scanner_rounded,
                  color: const Color(0xFFF97316),
                  subTab: 'scan',
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT TRANSLATIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
            ),
            TextButton(
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).state = 2; // History
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recent items preview
        _recentItemTile(context, 'Agreement.pdf', 'English → Hindi', '25 pages • 8.4 MB → 2.1 MB', 'Completed', Icons.picture_as_pdf_rounded, Colors.purple),
        _recentItemTile(context, 'Invoice_Scan.png', 'Spanish → English', '1 page • 2.4 MB → 1.1 MB', 'Completed', Icons.image_rounded, Colors.green),
        _recentItemTile(context, 'Financial_Report.docx', 'French → German', '12 pages • 4.2 MB → 2.8 MB', 'Completed', Icons.description_rounded, Colors.blue),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String subTab,
  }) {
    return InkWell(
      onTap: () {
        ref.read(navigationIndexProvider.notifier).state = 1;
        ref.read(activeTranslateTabProvider.notifier).state = subTab;
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentItemTile(
    BuildContext context,
    String title,
    String languages,
    String meta,
    String status,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$languages • $meta', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
