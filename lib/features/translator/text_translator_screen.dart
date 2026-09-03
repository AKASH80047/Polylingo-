import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/language_selector.dart';
import '../../core/network/api_client.dart';

class TextTranslatorScreen extends ConsumerStatefulWidget {
  const TextTranslatorScreen({super.key});

  @override
  ConsumerState<TextTranslatorScreen> createState() => _TextTranslatorScreenState();
}

class _TextTranslatorScreenState extends ConsumerState<TextTranslatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _translatedText = '';
  bool _isTranslating = false;
  String _detectedSource = '';

  void _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _translatedText = '';
        _detectedSource = '';
      });
      return;
    }

    setState(() => _isTranslating = true);

    final src = ref.read(sourceLanguageProvider);
    final tgt = ref.read(targetLanguageProvider);

    final result = await ApiClient.translateText(text, src.code, tgt.code);

    setState(() {
      _translatedText = result['translatedText'] ?? '';
      _detectedSource = result['detectedSourceLanguage'] ?? '';
      _isTranslating = false;
    });
  }

  void _swapLanguages() {
    final src = ref.read(sourceLanguageProvider);
    final tgt = ref.read(targetLanguageProvider);

    if (src.code == 'auto') return; // Cannot swap when auto detect is active

    ref.read(sourceLanguageProvider.notifier).state = tgt;
    ref.read(targetLanguageProvider.notifier).state = src;

    // Swap text content as well if available
    if (_translatedText.isNotEmpty) {
      _inputController.text = _translatedText;
      _translate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceLang = ref.watch(sourceLanguageProvider);
    final targetLang = ref.watch(targetLanguageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language selector bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                // Source Language Selector
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => LanguageSelectorModal(
                          isSource: true,
                          onSelect: (lang) {
                            ref.read(sourceLanguageProvider.notifier).state = lang;
                            _translate();
                          },
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Text(sourceLang.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SOURCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text(
                                  sourceLang.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded),
                        ],
                      ),
                    ),
                  ),
                ),

                // Swap Button
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded),
                  tooltip: 'Swap Languages',
                  onPressed: sourceLang.code == 'auto' ? null : _swapLanguages,
                ),

                // Target Language Selector
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => LanguageSelectorModal(
                          isSource: false,
                          onSelect: (lang) {
                            ref.read(targetLanguageProvider.notifier).state = lang;
                            _translate();
                          },
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Text(targetLang.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TARGET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text(
                                  targetLang.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Translation Workspace (Desktop split view or mobile stack)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 768;

              final inputCard = Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sourceLang.code == 'auto' && _detectedSource.isNotEmpty
                              ? 'Detected: ${_detectedSource.toUpperCase()}'
                              : sourceLang.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.paste_rounded, size: 18),
                              tooltip: 'Paste',
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null) {
                                  _inputController.text = data!.text!;
                                  _translate();
                                }
                              },
                            ),
                            if (_inputController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                tooltip: 'Clear',
                                onPressed: () {
                                  _inputController.clear();
                                  _translate();
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                    TextField(
                      controller: _inputController,
                      maxLines: 8,
                      minLines: 5,
                      onChanged: (val) => _translate(),
                      decoration: const InputDecoration(
                        hintText: 'Type or paste text here to translate instantly...',
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_inputController.text.length} characters',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, size: 20),
                          tooltip: 'Text to speech',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🔊 Speech synthesis playing...'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final outputCard = Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Translation (${targetLang.name})',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              tooltip: 'Copy translation',
                              onPressed: _translatedText.isEmpty ? null : () {
                                Clipboard.setData(ClipboardData(text: _translatedText));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied translation to clipboard!')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, size: 18),
                              tooltip: 'Share',
                              onPressed: _translatedText.isEmpty ? null : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Share option ready')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _isTranslating
                        ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator()))
                        : SelectableText(
                            _translatedText.isEmpty ? 'Translation will appear here...' : _translatedText,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: _translatedText.isEmpty ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                    const SizedBox(height: 24),
                    if (_translatedText.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Translation saved to History!')),
                            );
                          },
                          icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                          label: const Text('Save Translation'),
                        ),
                      ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: inputCard),
                    const SizedBox(width: 16),
                    Expanded(child: outputCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    inputCard,
                    const SizedBox(height: 16),
                    outputCard,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
