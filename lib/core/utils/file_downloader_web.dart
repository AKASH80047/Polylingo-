// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void downloadFileFromBytes(List<int> bytes, String fileName, {String mimeType = 'application/pdf'}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void downloadFileFromString(String content, String fileName, {String mimeType = 'application/pdf'}) {
  final bytes = utf8.encode(content);
  downloadFileFromBytes(bytes, fileName, mimeType: mimeType);
}
