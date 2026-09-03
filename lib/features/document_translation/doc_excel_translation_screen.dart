import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/file_downloader.dart';
import '../../shared/providers/app_providers.dart';
import '../universal_uploader/universal_uploader.dart';

class DocExcelTranslationScreen extends ConsumerStatefulWidget {
  final String mode; // 'docx' or 'xlsx'

  const DocExcelTranslationScreen({super.key, required this.mode});

  @override
  ConsumerState<DocExcelTranslationScreen> createState() => _DocExcelTranslationScreenState();
}

class _DocExcelTranslationScreenState extends ConsumerState<DocExcelTranslationScreen> {
  PlatformFile? _selectedFile;
  bool _isTranslating = false;
  bool _isCompleted = false;
  String? _errorMessage;

  // Translation Results
  String _originalText = '';
  String _translatedText = '';
  String _xlsxBase64 = '';
  int _cellsCount = 0;
  int _formulasCount = 0;
  List<Map<String, dynamic>> _previewRows = [];
  List<String> _translatedParagraphs = [];

  Future<void> _startTranslation() async {
    if (_selectedFile == null || _selectedFile!.bytes == null || _selectedFile!.bytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or upload a valid document first.')),
      );
      return;
    }

    final isExcel = widget.mode == 'xlsx';
    final targetLang = ref.read(targetLanguageProvider);

    setState(() {
      _isTranslating = true;
      _isCompleted = false;
      _errorMessage = null;
    });

    try {
      final result = await ApiClient.translateDocument(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        sourceLanguage: 'auto',
        targetLanguage: targetLang.code,
        jobId: 'doc_job_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['success'] == true) {
        setState(() {
          _isTranslating = false;
          _isCompleted = true;
          _originalText = result['originalText']?.toString() ?? '';
          _translatedText = result['translatedText']?.toString() ?? '';
          _xlsxBase64 = result['xlsxBase64']?.toString() ?? '';
          _cellsCount = (result['totalCellsTranslated'] is num) ? (result['totalCellsTranslated'] as num).toInt() : 0;
          _formulasCount = (result['formulasPreservedCount'] is num) ? (result['formulasPreservedCount'] as num).toInt() : 0;
          
          final rawRows = result['previewRows'] as List? ?? [];
          _previewRows = rawRows.map((r) => Map<String, dynamic>.from(r as Map)).toList();

          final rawPars = result['translatedParagraphs'] as List? ?? [];
          _translatedParagraphs = rawPars.map((p) => p.toString()).toList();
        });
      } else {
        throw Exception(result['error'] ?? 'Document translation processing failed.');
      }
    } catch (e) {
      setState(() {
        _isTranslating = false;
        _isCompleted = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _downloadResultFile() {
    final isExcel = widget.mode == 'xlsx';
    final baseName = _selectedFile?.name ?? (isExcel ? 'Translated_Spreadsheet.xlsx' : 'Translated_Document.docx');
    final outName = 'Translated_$baseName';

    if (isExcel && _xlsxBase64.isNotEmpty) {
      final bytes = base64Decode(_xlsxBase64);
      downloadFileFromBytes(bytes, outName, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading $outName...')),
      );
    } else {
      // Plain text or docx export
      final textContent = _translatedText.isNotEmpty ? _translatedText : _originalText;
      final bytes = utf8.encode(textContent);
      downloadFileFromBytes(bytes, '${outName.replaceAll('.docx', '')}.txt', mimeType: 'text/plain');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading translated file...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExcel = widget.mode == 'xlsx';
    final targetLang = ref.watch(targetLanguageProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExcel ? Colors.green.withValues(alpha: 0.12) : Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isExcel ? Icons.table_chart_rounded : Icons.description_rounded,
                  color: isExcel ? Colors.green : Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExcel ? 'Excel (XLSX) Neural Translation' : 'Word (DOCX) Neural Translation',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isExcel
                          ? 'Translates all natural-language worksheet cells into ${targetLang.name} while preserving =SUM, =AVG formulas'
                          : 'Translates paragraphs, headings & tables in Word documents into ${targetLang.name} with layout preservation',
                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // File Uploader
          UniversalFileUploader(
            allowedExtensions: isExcel ? const ['xlsx', 'xls'] : const ['docx', 'doc', 'txt'],
            selectedFile: _selectedFile,
            onFileSelected: (file) {
              setState(() {
                _selectedFile = file;
                _isCompleted = false;
                _errorMessage = null;
              });
              _startTranslation();
            },
            onRemoveFile: () => setState(() {
              _selectedFile = null;
              _isCompleted = false;
              _errorMessage = null;
              _originalText = '';
              _translatedText = '';
              _previewRows = [];
              _translatedParagraphs = [];
            }),
          ),
          const SizedBox(height: 20),

          // Action Button
          if (_selectedFile != null && !_isTranslating && !_isCompleted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isExcel ? Colors.green : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _startTranslation,
                icon: Icon(isExcel ? Icons.table_chart_rounded : Icons.description_rounded),
                label: Text('Translate ${isExcel ? 'Excel Spreadsheet' : 'Word Document'} into ${targetLang.name}'),
              ),
            ),
          ],

          // Progress Spinner
          if (_isTranslating) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Translating ${isExcel ? "spreadsheet cells & preserving formulas" : "document paragraphs"} into ${targetLang.name}...',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],

          // Error Display
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent))),
                ],
              ),
            ),
          ],

          // Completed Translation View
          if (_isCompleted) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${isExcel ? 'Spreadsheet' : 'Document'} Translated Successfully into ${targetLang.name}!',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: 'Copy Translated Text',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _translatedText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied translated content!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Excel stats
                  if (isExcel) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.translate_rounded, size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text('Cells Translated: $_cellsCount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.functions_rounded, size: 16, color: Colors.blue),
                              const SizedBox(width: 6),
                              Text('Formulas Preserved: $_formulasCount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Live Preview Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TRANSLATION PREVIEW:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        SelectableText(
                          _translatedText.trim().isNotEmpty ? _translatedText : 'Translation content ready.',
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          backgroundColor: isExcel ? Colors.green : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _downloadResultFile,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text('Download Translated ${isExcel ? 'XLSX' : 'DOCX'} File'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
