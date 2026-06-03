import 'dart:io';

Future<void> saveAndDownloadFile(List<int> bytes, String fileName) async {
  final dir = Directory('c:\\LendoraZ\\exports');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final file = File('${dir.path}\\$fileName');
  await file.writeAsBytes(bytes);
}
