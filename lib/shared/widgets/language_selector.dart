import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/language.dart';
import '../providers/app_providers.dart';

class LanguageSelectorModal extends ConsumerStatefulWidget {
  final bool isSource;
  final Function(Language) onSelect;

  const LanguageSelectorModal({
    super.key,
    required this.isSource,
    required this.onSelect,
  });

  @override
  ConsumerState<LanguageSelectorModal> createState() => _LanguageSelectorModalState();
}

class _LanguageSelectorModalState extends ConsumerState<LanguageSelectorModal> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final languagesAsync = ref.watch(languagesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isSource ? 'Select Source Language' : 'Select Target Language',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search input
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                searchQuery = val.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search language, country or native name...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: languagesAsync.when(
              data: (languages) {
                // Filter out 'auto' if target language
                List<Language> filtered = languages;
                if (!widget.isSource) {
                  filtered = filtered.where((l) => l.code != 'auto').toList();
                }

                if (searchQuery.isNotEmpty) {
                  filtered = filtered.where((l) =>
                    l.name.toLowerCase().contains(searchQuery) ||
                    l.nativeName.toLowerCase().contains(searchQuery) ||
                    l.code.toLowerCase().contains(searchQuery)
                  ).toList();
                }

                final popularLangs = filtered.where((l) => l.popular).toList();

                return ListView(
                  children: [
                    if (searchQuery.isEmpty && popularLangs.isNotEmpty) ...[
                      const Text(
                        'POPULAR LANGUAGES',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: popularLangs.map((lang) {
                          return ActionChip(
                            avatar: Text(lang.flag, style: const TextStyle(fontSize: 14)),
                            label: Text(lang.name),
                            onPressed: () {
                              widget.onSelect(lang);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ALL LANGUAGES',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ...filtered.map((lang) {
                      return ListTile(
                        leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
                        title: Text(lang.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${lang.nativeName} • ${lang.code.toUpperCase()}'),
                        trailing: lang.rtl
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('RTL', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                              )
                            : null,
                        onTap: () {
                          widget.onSelect(lang);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading languages: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
