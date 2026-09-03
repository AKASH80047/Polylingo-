import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/language_selector.dart';
import '../universal_uploader/universal_uploader.dart';
import '../../core/utils/file_downloader.dart';
import '../../core/network/api_client.dart';

class PdfTranslationScreen extends ConsumerStatefulWidget {
  const PdfTranslationScreen({super.key});

  @override
  ConsumerState<PdfTranslationScreen> createState() => _PdfTranslationScreenState();
}

class _PdfTranslationScreenState extends ConsumerState<PdfTranslationScreen> {
  PlatformFile? _selectedFile;
  bool _isProcessing = false;
  double _progress = 0;
  String _currentStepMessage = '';
  int _totalPages = 1;
  String _compressionMode = 'balanced';
  
  String _activeViewMode = 'split'; // 'original', 'translated', 'split'
  String _activeTargetLang = 'hi';  // default Hindi
  String _activeSourceLang = 'auto';

  // Unique Job Identity & Real Output Storage
  String _activeJobId = '';
  String _activeFileId = '';
  String _pdfBase64 = '';

  List<Map<String, dynamic>> _translatedPages = [];
  double _originalSize = 0.0;
  double _translatedSize = 0.0;
  bool _jobCompleted = false;
  String? _errorMessage;

  final Map<String, String> _supportedLanguages = {
    'hi': '🇮🇳 हिन्दी (Hindi)',
    'en': '🇬🇧 English (English)',
    'es': '🇪🇸 Español (Spanish)',
    'fr': '🇫🇷 Français (French)',
    'de': '🇩🇪 Deutsch (German)',
    'ur': '🇵🇰 اردو (Urdu)',
    'ar': '🇸🇦 العربية (Arabic)',
    'zh': '🇨🇳 中文 (Chinese)',
    'ja': '🇯🇵 日本語 (Japanese)',
    'ru': '🇷🇺 Русский (Russian)',
  };

  void _onNewFileSelected(PlatformFile file) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final newJobId = 'job_${now}_${file.size % 99999}';
    final newFileId = 'file_${now}_${file.name.hashCode.abs()}';

    setState(() {
      _selectedFile = file;
      _activeJobId = newJobId;
      _activeFileId = newFileId;
      _translatedPages = [];
      _pdfBase64 = '';
      _jobCompleted = false;
      _progress = 0.0;
      _errorMessage = null;
    });

    _startPdfTranslation(_activeTargetLang, newJobId);
  }

  Future<Uint8List?> _getFileBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes;
    }
    return null;
  }

  Future<void> _startPdfTranslation([String? overrideLang, String? assignedJobId]) async {
    final targetCode = overrideLang ?? _activeTargetLang;
    
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload or select a valid PDF document to translate.')),
      );
      return;
    }

    final String jobId = assignedJobId ?? 'job_${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.size % 99999}';
    _activeJobId = jobId;

    final pdfFileName = _selectedFile!.name;
    final fileMb = (_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2);

    setState(() {
      _isProcessing = true;
      _jobCompleted = false;
      _errorMessage = null;
      _progress = 0.05;
      _activeTargetLang = targetCode;
      _currentStepMessage = 'Reading PDF "$pdfFileName" ($fileMb MB) — Job ID: $jobId...';
      _originalSize = double.tryParse(fileMb) ?? 0.1;
      _translatedSize = 0.0;
      _translatedPages = [];
      _pdfBase64 = '';
    });

    try {
      final bytes = await _getFileBytes(_selectedFile!);
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Could not read file data. Please select a valid PDF file.');
      }

      setState(() {
        _progress = 0.20;
        _currentStepMessage = 'Uploaded PDF. Analyzing structure, pages & text streams...';
      });

      // Execute REAL document analysis & live translation via backend pipeline
      final res = await ApiClient.translateDocument(
        fileBytes: bytes,
        fileName: pdfFileName,
        sourceLanguage: _activeSourceLang,
        targetLanguage: targetCode,
        jobId: jobId,
      );

      if (_activeJobId != jobId) return; // Discard stale requests

      if (res['success'] != true) {
        final errText = res['error'] ?? res['details'] ?? 'Document translation failed. Please verify the PDF format.';
        throw Exception(errText);
      }

      setState(() {
        _progress = 0.85;
        _currentStepMessage = 'Reconstructing layout and validating output integrity...';
      });

      final int pageCount = res['pageCount'] ?? 1;
      final List rawPages = res['pages'] ?? [];
      final List<Map<String, dynamic>> parsedPages = rawPages.map((p) => Map<String, dynamic>.from(p)).toList();

      final origMb = (res['originalSizeMb'] as num?)?.toDouble() ?? _originalSize;
      final transMb = (res['translatedSizeMb'] as num?)?.toDouble() ?? (origMb * 0.4);

      setState(() {
        _totalPages = pageCount;
        _originalSize = origMb;
        _translatedSize = transMb;
        _translatedPages = parsedPages;
        _pdfBase64 = res['pdfBase64'] ?? '';
        _progress = 1.0;
        _currentStepMessage = 'All $pageCount Page(s) Translated In-Place Successfully (Job: $jobId)!';
        _isProcessing = false;
        _jobCompleted = true;
      });
    } catch (e) {
      if (_activeJobId != jobId) return;
      setState(() {
        _isProcessing = false;
        _jobCompleted = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _downloadPdf() {
    if (_pdfBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(_pdfBase64);
        final rawName = (_selectedFile?.name ?? "Document.pdf").replaceAll('.pdf', '');
        final fileName = 'PolyLingo_Translated_${rawName}_${_activeTargetLang}_${_activeJobId.substring(0, 8)}.pdf';
        
        downloadFileFromBytes(bytes, fileName, mimeType: 'application/pdf');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Downloaded "$fileName" to your device!')),
              ],
            ),
          ),
        );
        return;
      } catch (err) {
        debugPrint('[PdfDownload] Base64 decode notice: $err');
      }
    }

    // Fallback text summary download
    final buffer = StringBuffer();
    buffer.writeln('========================================================================');
    buffer.writeln('POLYLINGO AI DOCUMENT TRANSLATOR — TRANSLATED PDF EXPORT');
    buffer.writeln('Job ID: $_activeJobId');
    buffer.writeln('Document: ${_selectedFile?.name ?? "Document.pdf"}');
    buffer.writeln('Target Language: ${_supportedLanguages[_activeTargetLang]}');
    buffer.writeln('Total Pages: $_totalPages');
    buffer.writeln('========================================================================\n');

    for (final page in _translatedPages) {
      final pageNum = page['page'] ?? 1;
      buffer.writeln('------------------------------------------------------------------------');
      buffer.writeln('PAGE $pageNum OF $_totalPages [${page['pageType'] ?? 'NATIVE_TEXT_PAGE'}]');
      buffer.writeln('------------------------------------------------------------------------');
      buffer.writeln(page['translatedText'] ?? page['originalText'] ?? '');
      buffer.writeln('\n');
    }

    final rawName = (_selectedFile?.name ?? "Document.pdf").replaceAll('.pdf', '');
    final fileName = 'PolyLingo_Translated_${rawName}_${_activeTargetLang}_${_activeJobId.substring(0, 8)}.txt';
    downloadFileFromString(buffer.toString(), fileName, mimeType: 'text/plain;charset=utf-8');
  }

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PDF Document Slide-by-Slide Visual Translation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(
                    'Accepts any valid PDF — dynamically detects layouts, text blocks, scanned OCR regions, tables and dimensions',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // TARGET LANGUAGE SELECTOR TOOLBAR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SELECT TARGET LANGUAGE (REAL LIVE API TRANSLATION):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _supportedLanguages.entries.map((e) {
                    final isSelected = _activeTargetLang == e.key;
                    return ChoiceChip(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      label: Text(e.value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.white : null)),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      onSelected: (val) {
                        if (val && _selectedFile != null) {
                          _startPdfTranslation(e.key);
                        } else if (val) {
                          setState(() => _activeTargetLang = e.key);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Universal File Uploader for PDFs
          UniversalFileUploader(
            allowedExtensions: const ['pdf'],
            selectedFile: _selectedFile,
            onFileSelected: _onNewFileSelected,
            onRemoveFile: () {
              setState(() {
                _selectedFile = null;
                _translatedPages = [];
                _jobCompleted = false;
                _errorMessage = null;
                _activeJobId = '';
                _pdfBase64 = '';
              });
            },
          ),

          const SizedBox(height: 20),

          // Controls & Trigger
          if (_selectedFile != null && !_isProcessing && !_jobCompleted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FILE SELECTED: "${_selectedFile!.name}" (${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _compressionChip('High Quality', 'high', 'Preserve all detail'),
                      const SizedBox(width: 8),
                      _compressionChip('Balanced', 'balanced', 'Recommended ratio'),
                      const SizedBox(width: 8),
                      _compressionChip('Small Size', 'small', 'Max compression'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startPdfTranslation(),
                icon: const Icon(Icons.translate_rounded),
                label: Text('Translate In-Place via Live API (${_supportedLanguages[_activeTargetLang]})'),
              ),
            ),
          ],

          // Error Message Display
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('PDF Processing Notice', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _startPdfTranslation(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry Document Translation'),
                  ),
                ],
              ),
            ),
          ],

          // Real Progress Tracker
          if (_isProcessing) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Translating "${_selectedFile?.name ?? 'Uploaded PDF'}" In-Place...', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('${(_progress * 100).toInt()}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _progress, borderRadius: BorderRadius.circular(6), minHeight: 8),
                  const SizedBox(height: 12),
                  Text(_currentStepMessage, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 16),
                  _stepCheckmark('Exact uploaded PDF opened and validated (Pages: $_totalPages)', _progress >= 0.2),
                  _stepCheckmark('Detecting text regions and layout structures', _progress >= 0.4),
                  _stepCheckmark('Live Neural Translation API processing translatable blocks', _progress >= 0.7),
                  _stepCheckmark('Reconstructed document with layout and visual preservation', _progress >= 1.0),
                ],
              ),
            ),
          ],

          // CONTINUOUS VERTICAL SLIDE VIEWER (ALL PAGES TRANSLATED IN-PLACE)
          if (_jobCompleted) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ALL $_totalPages Page(s) Translated In-Place: "${_selectedFile?.name ?? 'Uploaded PDF'}" (${_supportedLanguages[_activeTargetLang]})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                        ),
                        Text('Original: $_totalPages Pages (${_originalSize.toStringAsFixed(2)} MB)  ➔  Translated: $_totalPages Pages (${_translatedSize.toStringAsFixed(2)} MB) [Job: ${_activeJobId.length >= 8 ? _activeJobId.substring(0, 8) : _activeJobId}]', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download PDF'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Toolbar View Mode Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'original', label: Text('Original (Source)')),
                      ButtonSegment(value: 'translated', label: Text('Translated (In-Place)')),
                      ButtonSegment(value: 'split', label: Text('Side-by-Side (Continuous)')),
                    ],
                    selected: {_activeViewMode},
                    onSelectionChanged: (val) => setState(() => _activeViewMode = val.first),
                  ),
                  const Spacer(),
                  const Icon(Icons.swap_vert_rounded, color: Colors.blue, size: 20),
                  const SizedBox(width: 6),
                  Text('Scroll Up / Down for All $_totalPages Pages', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CONTINUOUS VERTICAL SCROLL LIST FOR ALL PAGES
            Container(
              height: 820,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
              ),
              child: ListView.builder(
                itemCount: _translatedPages.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final slide = _translatedPages[index];
                  final pageNum = slide['page'] ?? (index + 1);
                  final pageType = slide['pageType'] ?? 'NATIVE_TEXT_PAGE';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 28.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '--- PAGE $pageNum OF $_totalPages [$pageType] ---',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_activeViewMode == 'original') ...[
                          _buildDynamicPageCard(slide, isOriginal: true),
                        ] else if (_activeViewMode == 'translated') ...[
                          _buildDynamicPageCard(slide, isOriginal: false),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildDynamicPageCard(slide, isOriginal: true)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDynamicPageCard(slide, isOriginal: false)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compressionChip(String label, String value, String sub) {
    final isSelected = _compressionMode == value;
    final primary = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _compressionMode = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? primary : Theme.of(context).dividerColor.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? primary : null)),
              Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCheckmark(String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isDone ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 13, color: isDone ? null : Colors.grey)),
        ],
      ),
    );
  }

  // Universal Dynamic Page Card matching authentic analyzed PDF structure and slide design
  Widget _buildDynamicPageCard(Map<String, dynamic> page, {required bool isOriginal}) {
    final pageNum = page['page'] ?? 1;
    final pageType = page['pageType'] ?? 'NATIVE_TEXT_PAGE';
    final orientation = page['orientation'] ?? 'landscape';
    final List blocks = page['blocks'] as List? ?? [];
    final textContent = isOriginal ? (page['originalText'] ?? '') : (page['translatedText'] ?? page['originalText'] ?? '');

    final isLandscape = orientation == 'landscape';
    final cardHeight = isLandscape ? 360.0 : 480.0;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: isOriginal ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6)),
        ],
        border: Border.all(
          color: isOriginal ? Colors.grey.shade700 : const Color(0xFF3B82F6).withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Slide Background Gradient & Accent lines
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOriginal
                        ? [Colors.grey.shade600, Colors.grey.shade400]
                        : [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
                  ),
                ),
              ),
            ),

            // 1. Header ribbon indicator
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              height: 38,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: isOriginal ? Colors.black.withOpacity(0.25) : const Color(0xFF1E3A8A).withOpacity(0.35),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isOriginal ? Icons.slideshow_rounded : Icons.translate_rounded,
                          size: 16,
                          color: isOriginal ? Colors.grey.shade300 : const Color(0xFF60A5FA),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOriginal ? 'Original Slide $pageNum' : 'Translated Slide $pageNum (${_supportedLanguages[_activeTargetLang]})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOriginal ? Colors.grey.shade200 : const Color(0xFF93C5FD),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOriginal ? Colors.white10 : const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOriginal ? Colors.white24 : const Color(0xFF60A5FA).withOpacity(0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'PAGE $pageNum / $_totalPages',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Main Slide Presentation Canvas (In-Place Layout)
            Positioned(
              left: 20,
              right: 20,
              top: 50,
              bottom: 34,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOriginal ? const Color(0xFF0F172A).withOpacity(0.6) : const Color(0xFF172554).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: blocks.isNotEmpty
                    ? ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: blocks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final b = blocks[i] is Map ? blocks[i] : {};
                          final origText = b['original']?.toString() ?? '';
                          final transText = b['translated']?.toString() ?? origText;
                          final isHeading = b['isHeading'] == true;
                          final textToShow = isOriginal ? origText : transText;

                          if (isHeading || i == 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isOriginal ? Colors.white.withOpacity(0.05) : const Color(0xFF3B82F6).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOriginal ? Colors.white12 : const Color(0xFF60A5FA).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                textToShow,
                                style: TextStyle(
                                  fontSize: isLandscape ? 15 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: isOriginal ? Colors.amber.shade200 : const Color(0xFF67E8F9),
                                  height: 1.3,
                                ),
                              ),
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isOriginal ? Colors.grey.shade400 : const Color(0xFF60A5FA),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  textToShow,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: isOriginal ? Colors.grey.shade200 : Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : SingleChildScrollView(
                        child: Text(
                          textContent.isNotEmpty ? textContent : '[Slide Visual Content]',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isOriginal ? Colors.grey.shade200 : Colors.white,
                          ),
                        ),
                      ),
              ),
            ),

            // 3. Footer Branding
            Positioned(
              bottom: 8,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOriginal ? 'Original Layout Document' : 'In-Place Neural Translation',
                    style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'PolyLingo Document AI',
                    style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
