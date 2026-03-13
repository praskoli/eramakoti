import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CertificateShareService {
  CertificateShareService._();

  static final CertificateShareService instance =
  CertificateShareService._();

  Future<void> shareCertificate(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Jai Shri Ram 🙏',
    );
  }

  Future<File> downloadToLocalTemp({
    required String downloadUrl,
    required String fileName,
  }) async {
    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode != 200) {
      throw Exception('Could not download certificate');
    }

    final bytes = Uint8List.fromList(response.bodyBytes);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}