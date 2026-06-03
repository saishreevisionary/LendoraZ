// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveAndDownloadFile(List<int> bytes, String fileName) async {
  final Uint8List byteData = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  
  String mimeType = 'application/octet-stream';
  if (fileName.toLowerCase().endsWith('.pdf')) {
    mimeType = 'application/pdf';
  } else if (fileName.toLowerCase().endsWith('.xlsx')) {
    mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }

  final blob = html.Blob([byteData], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

