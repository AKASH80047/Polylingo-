import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  String _sortOption = 'Newest';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _files = [
    {'id': 'f_1', 'name': 'Agreement_Translated_HI.pdf', 'format': 'PDF', 'sizeMb': 2.1, 'date': '2026-08-19', 'pages': 25, 'color': Colors.purple, 'icon': Icons.picture_as_pdf_rounded},
    {'id': 'f_2', 'name': 'Invoice_Scan_Translated.png', 'format': 'PNG', 'sizeMb': 1.1, 'date': '2026-08-18', 'pages': 1, 'color': Colors.green, 'icon': Icons.image_rounded},
    {'id': 'f_3', 'name': 'Financial_Report_DE.docx', 'format': 'DOCX', 'sizeMb': 2.8, 'date': '2026-08-17', 'pages': 12, 'color': Colors.blue, 'icon': Icons.description_rounded},
    {'id': 'f_4', 'name': 'Budget_2026_ES.xlsx', 'format': 'XLSX', 'sizeMb': 1.2, 'date': '2026-08-15', 'pages': 4, 'color': Colors.teal, 'icon': Icons.table_chart_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Cloud Files', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File upload trigger active')),
                  );
                },
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Upload File'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search & Sort Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search cloud files...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _sortOption,
                items: ['Newest', 'Oldest', 'Name', 'File Size'].map((s) {
                  return DropdownMenuItem(value: s, child: Text('Sort by $s'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _sortOption = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // File items grid or list
          ..._files.map((file) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Icon(file['icon'] as IconData, color: file['color'] as Color, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${file['format']} • ${file['sizeMb']} MB • Added ${file['date']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 20),
                    tooltip: 'Download',
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    tooltip: 'Rename',
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () {
                      setState(() {
                        _files.removeWhere((f) => f['id'] == file['id']);
                      });
                    },
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
