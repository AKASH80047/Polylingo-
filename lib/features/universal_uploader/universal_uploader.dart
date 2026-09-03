import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UniversalFileUploader extends StatefulWidget {
  final List<String> allowedExtensions;
  final Function(PlatformFile file) onFileSelected;
  final VoidCallback? onRemoveFile;
  final PlatformFile? selectedFile;
  final String? errorMessage;
  final bool isUploading;
  final double uploadProgress;

  const UniversalFileUploader({
    super.key,
    this.allowedExtensions = const ['pdf', 'docx', 'xlsx', 'jpg', 'png', 'webp', 'txt'],
    required this.onFileSelected,
    this.onRemoveFile,
    this.selectedFile,
    this.errorMessage,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  @override
  State<UniversalFileUploader> createState() => _UniversalFileUploaderState();
}

class _UniversalFileUploaderState extends State<UniversalFileUploader> {
  bool _isHovering = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // Check size limit (50 MB max)
        if (file.size > 50 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File is too large. Maximum supported file size is 50 MB.')),
          );
          return;
        }
        widget.onFileSelected(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'docx': case 'doc': return Icons.description_rounded;
      case 'xlsx': case 'xls': return Icons.table_chart_rounded;
      case 'jpg': case 'jpeg': case 'png': case 'webp': return Icons.image_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return Colors.purple;
      case 'docx': return Colors.blue;
      case 'xlsx': return Colors.green;
      case 'jpg': case 'jpeg': case 'png': case 'webp': return Colors.teal;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (widget.selectedFile != null) {
      final file = widget.selectedFile!;
      final ext = file.extension ?? 'file';
      final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(2);

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _getFileColor(ext).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_getFileIcon(ext), color: _getFileColor(ext), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ext.toUpperCase()} • $sizeMb MB',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.swap_calls_rounded, size: 16),
                  label: const Text('Replace'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: widget.onRemoveFile,
                  tooltip: 'Remove file',
                ),
              ],
            ),
            if (widget.isUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: widget.uploadProgress > 0 ? widget.uploadProgress : null,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                'Uploading document... ${(widget.uploadProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
            if (widget.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _pickFile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: _isHovering ? primaryColor.withOpacity(0.04) : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovering ? primaryColor : Theme.of(context).dividerColor.withOpacity(0.2),
              width: _isHovering ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_upload_rounded, color: primaryColor, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Drag and drop your document here, or click to browse',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Supports PDF, DOCX, XLSX, JPG, PNG, WEBP and TXT (Max 50 MB)',
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Select File'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
