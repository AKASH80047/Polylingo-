import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/network/api_client.dart';
import '../../shared/providers/app_providers.dart';

class CameraScannerScreen extends ConsumerStatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  ConsumerState<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends ConsumerState<CameraScannerScreen> {
  Uint8List? _capturedImageBytes;
  String? _fileName;
  bool _isProcessing = false;
  bool _isCompleted = false;
  String? _errorMessage;

  String _extractedText = '';
  String _translatedText = '';
  String _detectedLang = 'auto';

  Future<void> _pickOrCaptureImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null && file.bytes!.isNotEmpty) {
          setState(() {
            _capturedImageBytes = file.bytes;
            _fileName = file.name;
            _isCompleted = false;
            _errorMessage = null;
            _extractedText = '';
            _translatedText = '';
          });
          _processScan();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting scan image: $e')),
      );
    }
  }

  Future<void> _processScan() async {
    if (_capturedImageBytes == null) return;
    final targetLang = ref.read(targetLanguageProvider);

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiClient.translateDocument(
        fileBytes: _capturedImageBytes!,
        fileName: _fileName ?? 'camera_scan.jpg',
        sourceLanguage: 'auto',
        targetLanguage: targetLang.code,
        jobId: 'scan_job_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['success'] == true) {
        setState(() {
          _extractedText = result['originalText']?.toString() ?? '';
          _translatedText = result['translatedText']?.toString() ?? '';
          _detectedLang = result['detectedSourceLanguage']?.toString() ?? 'auto';
          _isProcessing = false;
          _isCompleted = true;
        });
      } else {
        throw Exception(result['error'] ?? 'Could not scan and extract document text.');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isCompleted = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetLang = ref.watch(targetLanguageProvider);

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
                  gradient: LinearGradient(
                    colors: [Colors.cyan, theme.colorScheme.primary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Camera & Document Scanner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(
                      'Scan physical documents, bills, signs, and pages with instant OCR & neural translation into ${targetLang.name}.',
                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scanner Viewfinder
          Container(
            height: 360,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_capturedImageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.memory(_capturedImageBytes!, fit: BoxFit.contain, width: double.infinity, height: double.infinity),
                  )
                else
                  Center(
                    child: Container(
                      width: 260,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.8), width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Positioned(top: 0, left: 0, child: _cornerMarker()),
                          Positioned(top: 0, right: 0, child: _cornerMarker()),
                          Positioned(bottom: 0, left: 0, child: _cornerMarker()),
                          Positioned(bottom: 0, right: 0, child: _cornerMarker()),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.document_scanner_rounded, size: 54, color: Colors.white.withValues(alpha: 0.7)),
                                const SizedBox(height: 12),
                                const Text(
                                  'CAPTURE OR SELECT DOCUMENT\nTO SCAN & TRANSLATE',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.cyanAccent),
                          SizedBox(height: 16),
                          Text('Neural Vision OCR Scanning & Translating...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scan Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _pickOrCaptureImage,
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text(_capturedImageBytes != null ? 'Scan Another Document' : 'Capture / Upload Document Photo'),
              ),
              if (_capturedImageBytes != null && !_isProcessing) ...[
                const SizedBox(width: 14),
                OutlinedButton.icon(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                  onPressed: _processScan,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Re-Scan'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Error Display
          if (_errorMessage != null)
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

          // Scanned Translation Results
          if (_isCompleted && _translatedText.trim().isNotEmpty) ...[
            Container(
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
                      const Icon(Icons.check_circle_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Document Scanned & Translated (${targetLang.name})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy Translation',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _translatedText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Scanned translation copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (_extractedText.trim().isNotEmpty) ...[
                    const Text('ORIGINAL SCANNED TEXT:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    SelectableText(_extractedText, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 16),
                  ],
                  const Text('TRANSLATED OUTPUT:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  SelectableText(
                    _translatedText,
                    style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cornerMarker() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
