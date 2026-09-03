import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _historyItems = [
    {
      'id': 'hist_1',
      'fileName': 'Agreement.pdf',
      'sourceLanguage': 'English',
      'targetLanguage': 'Hindi',
      'pageCount': 25,
      'originalSize': '8.4 MB',
      'translatedSize': '2.1 MB',
      'status': 'Completed',
      'timestamp': 'Today, 10:42 AM',
      'type': 'PDF',
      'icon': Icons.picture_as_pdf_rounded,
      'color': Colors.purple,
    },
    {
      'id': 'hist_2',
      'fileName': 'Invoice_Scan.png',
      'sourceLanguage': 'Spanish',
      'targetLanguage': 'English',
      'pageCount': 1,
      'originalSize': '2.4 MB',
      'translatedSize': '1.1 MB',
      'status': 'Completed',
      'timestamp': 'Yesterday, 4:15 PM',
      'type': 'Image',
      'icon': Icons.image_rounded,
      'color': Colors.green,
    },
    {
      'id': 'hist_3',
      'fileName': 'Financial_Report.docx',
      'sourceLanguage': 'French',
      'targetLanguage': 'German',
      'pageCount': 12,
      'originalSize': '4.2 MB',
      'translatedSize': '2.8 MB',
      'status': 'Completed',
      'timestamp': 'Aug 17, 2026',
      'type': 'Word',
      'icon': Icons.description_rounded,
      'color': Colors.blue,
    },
    {
      'id': 'hist_4',
      'fileName': 'Budget_2026.xlsx',
      'sourceLanguage': 'Auto Detect',
      'targetLanguage': 'Spanish',
      'pageCount': 4,
      'originalSize': '1.8 MB',
      'translatedSize': '1.2 MB',
      'status': 'Completed',
      'timestamp': 'Aug 15, 2026',
      'type': 'Excel',
      'icon': Icons.table_chart_rounded,
      'color': Colors.teal,
    },
    {
      'id': 'hist_5',
      'fileName': 'Quick Note',
      'sourceLanguage': 'Arabic',
      'targetLanguage': 'English',
      'pageCount': 1,
      'originalSize': '0.1 MB',
      'translatedSize': '0.1 MB',
      'status': 'Completed',
      'timestamp': 'Aug 14, 2026',
      'type': 'Text',
      'icon': Icons.text_fields_rounded,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filtered = _historyItems.where((item) {
      if (_selectedFilter != 'All' && item['type'] != _selectedFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return item['fileName'].toString().toLowerCase().contains(query) ||
            item['sourceLanguage'].toString().toLowerCase().contains(query) ||
            item['targetLanguage'].toString().toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Translation History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'Clear History',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History cleared successfully!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search history by file name or language...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).cardTheme.color,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter Chips (All, PDF, Image, Word, Excel, Text)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'PDF', 'Image', 'Word', 'Excel', 'Text'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // History Items List with Exact Card Requirements (Section 25)
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('No translations yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Translate your first document and it will appear here.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item['sourceLanguage']} ➔ ${item['targetLanguage']}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['status'],
                            style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['fileName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(
                                '${item['pageCount']} pages • ${item['originalSize']} ➔ ${item['translatedSize']}',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                            ],
                          ),
                        ),
                        Text(item['timestamp'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Actions: Open, Download, Share, Delete, Translate again
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Open'),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Download'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded, size: 18),
                          tooltip: 'Share',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () {
                            setState(() {
                              _historyItems.removeWhere((h) => h['id'] == item['id']);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
