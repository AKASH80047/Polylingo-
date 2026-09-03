import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/network/api_client.dart';
import '../universal_uploader/universal_uploader.dart';

class ImageTranslationScreen extends ConsumerStatefulWidget {
  const ImageTranslationScreen({super.key});

  @override
  ConsumerState<ImageTranslationScreen> createState() => _ImageTranslationScreenState();
}

class _ImageTranslationScreenState extends ConsumerState<ImageTranslationScreen> {
  PlatformFile? _selectedFile;
  Uint8List? _imageBytes;
  ui.Image? _decodedUiImage;
  
  bool _isProcessing = false;
  bool _isCompleted = false;
  String? _errorMessage;
  String _currentStatusMessage = '';
  
  // Translation Result
  String _originalOcrText = '';
  String _translatedText = '';
  String _activeSourceLang = 'auto';
  String _activeTargetLang = 'en';
  String _detectedSourceLang = 'auto';
  List<Map<String, dynamic>> _regions = [];
  double _confidence = 0.95;
  
  // Google Lens In-Place Translation Controls
  String _activeViewMode = 'overlay'; // 'overlay', 'side_by_side', 'text_only'
  bool _showOriginalOnly = false; // Toggle to view original image without translation overlay
  double _overlayOpacity = 0.90; // Background mask opacity
  double _fontSizeScale = 1.0;
  
  // Controllers
  final TextEditingController _ocrEditController = TextEditingController();
  bool _isEditingOcr = false;

  final Map<String, String> _sourceLanguages = {
    'auto': '🌐 Auto-Detect Script',
    'ar': '🇸🇦 Arabic (العربية)',
    'hi': '🇮🇳 Hindi (हिन्दी)',
    'ur': '🇵🇰 Urdu (اردو)',
    'en': '🇬🇧 English',
    'es': '🇪🇸 Spanish (Español)',
    'fr': '🇫🇷 French (Français)',
    'de': '🇩🇪 German (Deutsch)',
    'zh': '🇨🇳 Chinese (中文)',
    'ja': '🇯🇵 Japanese (日本語)',
    'ru': '🇷🇺 Russian (Русский)',
  };

  final Map<String, String> _targetLanguages = {
    'en': '🇬🇧 English',
    'hi': '🇮🇳 हिन्दी (Hindi)',
    'ur': '🇵🇰 اردو (Urdu)',
    'ar': '🇸🇦 العربية (Arabic)',
    'es': '🇪🇸 Español (Spanish)',
    'fr': '🇫🇷 Français (French)',
    'de': '🇩🇪 German (German)',
    'zh': '🇨🇳 中文 (Chinese)',
    'ja': '🇯🇵 日本語 (Japanese)',
    'ru': '🇷🇺 Русский (Russian)',
  };

  @override
  void dispose() {
    _ocrEditController.dispose();
    super.dispose();
  }

  Future<void> _decodeImage(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) {
      completer.complete(img);
    });
    final decoded = await completer.future;
    if (mounted) {
      setState(() {
        _decodedUiImage = decoded;
      });
    }
  }

  void _onFileSelected(PlatformFile file) async {
    if (file.bytes == null || file.bytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read image file data. Please try another image.')),
      );
      return;
    }

    setState(() {
      _selectedFile = file;
      _imageBytes = file.bytes;
      _isCompleted = false;
      _errorMessage = null;
      _originalOcrText = '';
      _translatedText = '';
      _regions = [];
    });

    await _decodeImage(file.bytes!);
    _processUploadedImage(forceFullOcr: true);
  }

  Future<void> _processUploadedImage({
    String? sourceCode,
    String? targetCode,
    bool forceFullOcr = false,
  }) async {
    if (_imageBytes == null || _selectedFile == null) return;
    
    final src = sourceCode ?? _activeSourceLang;
    final tgt = targetCode ?? _activeTargetLang;
    final jobId = 'img_job_${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.size % 9999}';

    setState(() {
      _isProcessing = true;
      _activeSourceLang = src;
      _activeTargetLang = tgt;
      _errorMessage = null;
      _currentStatusMessage = 'Scanning image with Multi-Script Neural Vision OCR...';
    });

    try {
      // If we already have OCR text extracted and just changing target language or re-translating edited text
      if (!forceFullOcr && _originalOcrText.trim().isNotEmpty) {
        final textToTranslate = _isEditingOcr ? _ocrEditController.text.trim() : _originalOcrText.trim();
        setState(() {
          _currentStatusMessage = 'Translating in-place text into ${_targetLanguages[tgt] ?? tgt}...';
        });

        final fullTrans = await ApiClient.translateText(
          textToTranslate,
          src == 'auto' ? (_detectedSourceLang != 'auto' ? _detectedSourceLang : 'auto') : src,
          tgt,
        );

        final List<Map<String, dynamic>> updatedRegions = [];
        for (final reg in _regions) {
          final regText = reg['text']?.toString() ?? '';
          if (regText.trim().isNotEmpty) {
            try {
              final regTrans = await ApiClient.translateText(regText, _detectedSourceLang, tgt);
              updatedRegions.add({
                ...reg,
                'translatedText': regTrans['translatedText'] ?? regText,
              });
            } catch (_) {
              updatedRegions.add({...reg});
            }
          }
        }

        if (mounted) {
          setState(() {
            _originalOcrText = textToTranslate;
            _translatedText = fullTrans['translatedText'] ?? textToTranslate;
            _regions = updatedRegions;
            _isProcessing = false;
            _isCompleted = true;
          });
        }
        return;
      }

      // First-time or forced full processing via Backend OCR & Translation Pipeline
      final result = await ApiClient.translateDocument(
        fileBytes: _imageBytes!,
        fileName: _selectedFile!.name,
        sourceLanguage: src,
        targetLanguage: tgt,
        jobId: jobId,
      );

      if (result['success'] == true) {
        final original = result['originalText']?.toString() ?? '';
        final translated = result['translatedText']?.toString() ?? '';
        final detected = result['detectedSourceLanguage']?.toString() ?? src;
        final rawRegions = result['regions'] as List? ?? [];
        final conf = (result['confidence'] is num) ? (result['confidence'] as num).toDouble() : 0.95;

        final parsedRegions = rawRegions.map((r) => Map<String, dynamic>.from(r as Map)).toList();

        if (mounted) {
          setState(() {
            _originalOcrText = original;
            _ocrEditController.text = original;
            _translatedText = translated;
            _detectedSourceLang = detected;
            _regions = parsedRegions;
            _confidence = conf;
            _isProcessing = false;
            _isCompleted = true;
          });
        }
      } else {
        throw Exception(result['error'] ?? 'Image OCR did not detect readable text.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isCompleted = false;
          _errorMessage = 'Image translation notice: ${e.toString()}';
        });
      }
    }
  }

  void _swapLanguages() {
    if (_activeSourceLang == 'auto') {
      final detected = _detectedSourceLang != 'auto' ? _detectedSourceLang : 'ar';
      final prevTarget = _activeTargetLang;
      setState(() {
        _activeSourceLang = prevTarget;
        _activeTargetLang = detected;
      });
    } else {
      final prevSrc = _activeSourceLang;
      final prevTgt = _activeTargetLang;
      setState(() {
        _activeSourceLang = prevTgt;
        _activeTargetLang = prevSrc;
      });
    }
    _processUploadedImage(forceFullOcr: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, Colors.deepPurpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Google Lens-Style In-Place Image Translation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber, width: 1),
                          ),
                          child: const Text('REAL-TIME IN-PLACE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ),
                      ],
                    ),
                    Text(
                      'Translates text directly inside the image at exact positions, replacing original words seamlessly.',
                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // DUAL LANGUAGE SELECTOR BAR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // SOURCE LANGUAGE CHIPS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.image_search_rounded, size: 15, color: Colors.blue),
                              const SizedBox(width: 6),
                              const Text('IMAGE SCRIPT (SOURCE OCR):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                              if (_detectedSourceLang != 'auto' && _detectedSourceLang.isNotEmpty) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Detected: ${_detectedSourceLang.toUpperCase()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _sourceLanguages.entries.map((e) {
                              final isSelected = _activeSourceLang == e.key;
                              return ChoiceChip(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                label: Text(e.value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : null)),
                                selected: isSelected,
                                selectedColor: Colors.blue,
                                onSelected: (val) {
                                  if (val && _activeSourceLang != e.key) {
                                    setState(() => _activeSourceLang = e.key);
                                    if (_imageBytes != null) {
                                      _processUploadedImage(sourceCode: e.key, forceFullOcr: true);
                                    }
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // SWAP BUTTON
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: IconButton.filledTonal(
                        onPressed: _swapLanguages,
                        tooltip: 'Swap Languages',
                        icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                      ),
                    ),

                    // TARGET LANGUAGE CHIPS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.translate_rounded, size: 15, color: Colors.green),
                              SizedBox(width: 6),
                              Text('REPLACE WITH (TARGET):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _targetLanguages.entries.map((e) {
                              final isSelected = _activeTargetLang == e.key;
                              return ChoiceChip(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                label: Text(e.value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : null)),
                                selected: isSelected,
                                selectedColor: Colors.green,
                                onSelected: (val) {
                                  if (val && _activeTargetLang != e.key) {
                                    setState(() => _activeTargetLang = e.key);
                                    if (_imageBytes != null) {
                                      _processUploadedImage(targetCode: e.key);
                                    }
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Universal File Uploader
          UniversalFileUploader(
            allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
            selectedFile: _selectedFile,
            onFileSelected: _onFileSelected,
            onRemoveFile: () {
              setState(() {
                _selectedFile = null;
                _imageBytes = null;
                _decodedUiImage = null;
                _isCompleted = false;
                _isProcessing = false;
                _errorMessage = null;
                _originalOcrText = '';
                _translatedText = '';
                _regions = [];
              });
            },
          ),

          const SizedBox(height: 20),

          // Processing indicator
          if (_isProcessing) ...[
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
                  Text(_currentStatusMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  const Text('Detecting text bounding boxes and generating in-place overlay...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Image Translation Notice', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _processUploadedImage(forceFullOcr: true),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry OCR Scan'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _activeSourceLang = 'ar');
                          _processUploadedImage(sourceCode: 'ar', forceFullOcr: true);
                        },
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                        label: const Text('Force Arabic Script OCR'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // SUCCESS TRANSLATION VIEW
          if (_isCompleted && !_isProcessing && _imageBytes != null) ...[
            // View mode switch bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'In-Place Translated ${_regions.length} Blocks (${(_confidence * 100).toInt()}% Confidence)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                  ),
                  const Spacer(),
                  // View mode toggle
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'overlay', icon: Icon(Icons.layers_rounded, size: 16), label: Text('In-Place Image')),
                      ButtonSegment(value: 'side_by_side', icon: Icon(Icons.compare_rounded, size: 16), label: Text('Split View')),
                      ButtonSegment(value: 'text_only', icon: Icon(Icons.text_fields_rounded, size: 16), label: Text('Text List')),
                    ],
                    selected: {_activeViewMode},
                    onSelectionChanged: (val) {
                      setState(() {
                        _activeViewMode = val.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active View Mode Rendering
            if (_activeViewMode == 'overlay')
              _buildInPlaceLensView(theme, isDark)
            else if (_activeViewMode == 'side_by_side')
              _buildSideBySideView(theme, isDark)
            else
              _buildExtractedTextView(theme, isDark),
          ],
        ],
      ),
    );
  }

  // 1. GOOGLE LENS IN-PLACE IMAGE TRANSLATION CANVAS
  Widget _buildInPlaceLensView(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lens Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high_rounded, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'In-Place Translated Image (${_targetLanguages[_activeTargetLang]})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),

                // Toggle Original / Translated
                Row(
                  children: [
                    const Text('Show Original:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 4),
                    Switch.adaptive(
                      value: _showOriginalOnly,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        setState(() {
                          _showOriginalOnly = val;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Copy Full Text Button
                IconButton.filledTonal(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Copy Translated Text',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _translatedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Translated text copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
          ),

          // Lens In-Place Interactive Image Viewer
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final renderWidth = constraints.maxWidth;
                  final origWidth = (_decodedUiImage?.width.toDouble() ?? 800.0);
                  final origHeight = (_decodedUiImage?.height.toDouble() ?? 600.0);
                  final aspectRatio = origWidth / origHeight;
                  final renderHeight = renderWidth / aspectRatio;

                  return SizedBox(
                    width: renderWidth,
                    height: renderHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Base User Image
                        Image.memory(
                          _imageBytes!,
                          fit: BoxFit.fill,
                        ),

                        // In-Place Seamless Text Overlays (Replaces original text directly on image)
                        if (!_showOriginalOnly && _regions.isNotEmpty)
                          ..._regions.map((reg) {
                            final bbox = reg['bbox'] as Map? ?? {};
                            final double x = (bbox['x'] is num) ? (bbox['x'] as num).toDouble() : 30.0;
                            final double y = (bbox['y'] is num) ? (bbox['y'] as num).toDouble() : 30.0;
                            final double w = (bbox['width'] is num) ? (bbox['width'] as num).toDouble() : 200.0;
                            final double h = (bbox['height'] is num) ? (bbox['height'] as num).toDouble() : 30.0;

                            final double scaledLeft = (x / origWidth) * renderWidth;
                            final double scaledTop = (y / origHeight) * renderHeight;
                            final double scaledWidth = MathMax(60.0, (w / origWidth) * renderWidth);
                            final double scaledHeight = MathMax(24.0, (h / origHeight) * renderHeight);

                            final transText = reg['translatedText']?.toString() ?? reg['text']?.toString() ?? '';

                            return Positioned(
                              left: scaledLeft,
                              top: scaledTop,
                              width: scaledWidth,
                              height: scaledHeight,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: _overlayOpacity),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.8), width: 1),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
                                  ],
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    transText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 * _fontSizeScale,
                                      letterSpacing: 0.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }),

                        // If no specific regions, show full In-Place Banner over image
                        if (!_showOriginalOnly && _regions.isEmpty && _translatedText.trim().isNotEmpty)
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber, width: 1.5),
                              ),
                              child: Text(
                                _translatedText,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Translation Card
          if (_translatedText.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Full Document Translation (${_targetLanguages[_activeTargetLang]}):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _translatedText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied translation!')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text('Copy Text', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _translatedText,
                    style: const TextStyle(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 2. SIDE-BY-SIDE SPLIT VIEW WITH EDITABLE OCR TEXT
  Widget _buildSideBySideView(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        
        final leftCard = Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_rounded, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Original Image Upload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditingOcr = !_isEditingOcr;
                          if (_isEditingOcr) {
                            _ocrEditController.text = _originalOcrText;
                          }
                        });
                      },
                      icon: Icon(_isEditingOcr ? Icons.check_rounded : Icons.edit_note_rounded, size: 16),
                      label: Text(_isEditingOcr ? 'Done Editing' : 'Edit OCR Text', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_imageBytes!, fit: BoxFit.contain, width: double.infinity),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Detected OCR Text:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const Spacer(),
                        if (_isEditingOcr)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                            onPressed: () => _processUploadedImage(),
                            icon: const Icon(Icons.translate_rounded, size: 14),
                            label: const Text('Re-Translate', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditingOcr)
                      TextField(
                        controller: _ocrEditController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Edit detected text...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: SelectableText(
                          _originalOcrText.trim().isNotEmpty ? _originalOcrText : 'No text could be extracted.',
                          style: const TextStyle(fontSize: 14, height: 1.5, fontFamily: 'sans-serif'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

        final rightCard = Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.translate_rounded, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Translated Output (${_targetLanguages[_activeTargetLang]})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy Translation',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _translatedText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Translated text copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _translatedText.trim().isNotEmpty ? _translatedText : 'No translation output available.',
                  style: const TextStyle(fontSize: 16, height: 1.7, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              leftCard,
              const SizedBox(height: 16),
              rightCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leftCard),
            const SizedBox(width: 16),
            Expanded(child: rightCard),
          ],
        );
      },
    );
  }

  // 3. EXTRACTED TEXT DETAIL VIEW
  Widget _buildExtractedTextView(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt_rounded, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('Extracted OCR Line-by-Line Translations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _translatedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All translated text copied to clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_regions.isEmpty)
            SelectableText(_translatedText, style: const TextStyle(fontSize: 14, height: 1.5))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _regions.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, idx) {
                final r = _regions[idx];
                final orig = r['text']?.toString() ?? '';
                final trans = r['translatedText']?.toString() ?? '';

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: Text('${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(orig, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 4),
                          SelectableText(trans, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  double MathMax(double a, double b) => a > b ? a : b;
}
