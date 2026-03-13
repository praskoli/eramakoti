import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/certificate_input.dart';

class GeneratedCertificateResult {
  final File file;
  final String storagePath;
  final String downloadUrl;

  const GeneratedCertificateResult({
    required this.file,
    required this.storagePath,
    required this.downloadUrl,
  });
}

class CertificateGeneratorService {
  CertificateGeneratorService._();

  static final CertificateGeneratorService instance =
  CertificateGeneratorService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _bgAssetPath =
      'assets/images/ramakoti_certificate_bg.jpg';
  static const String _borderAssetPath =
      'assets/images/certificate_border.png';
  static const String _fontPath = 'assets/fonts/NotoSerif-Regular.ttf';

  static const PdfPageFormat _pageFormat = PdfPageFormat(980, 620);

  Future<GeneratedCertificateResult> generateAndUploadCertificate({
    required CertificateInput input,
  }) async {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    final storagePath =
        'ramakotiCertificates/$year/$month/$day/${input.uid}/${input.certificateId}.pdf';

    final dateText = DateFormat('dd MMM yyyy').format(input.completedAt);
    final countText = _formatCount(input.completedCount);

    final qrText = '''
eRamakoti – Ramakoti Certificate

With the divine blessings of Lord Sri Rama

This certificate is respectfully awarded to

${input.devoteeName}

For completing $countText sacred writings of Sri Rama Nama
in a spirit of devotion, discipline, and spiritual dedication.

Om Sri Ramaya Namaha

Date: $dateText
Certificate ID: ${input.certificateId}
''';

    final bytes = await _buildPdfBytes(
      input: input,
      qrData: qrText,
    );

    final file = await _saveLocally(
      bytes: bytes,
      fileName: input.fileName,
    );

    final ref = _storage.ref(storagePath);

    await ref.putFile(
      file,
      SettableMetadata(
        contentType: 'application/pdf',
      ),
    );

    final downloadUrl = await ref.getDownloadURL();

    return GeneratedCertificateResult(
      file: file,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
    );
  }

  Future<Uint8List> _buildPdfBytes({
    required CertificateInput input,
    required String qrData,
  }) async {
    final pdf = pw.Document();

    final bgBytes =
    (await rootBundle.load(_bgAssetPath)).buffer.asUint8List();
    final borderBytes =
    (await rootBundle.load(_borderAssetPath)).buffer.asUint8List();
    final font = pw.Font.ttf(
      (await rootBundle.load(_fontPath)).buffer.asByteData(),
    );

    final bgImage = pw.MemoryImage(bgBytes);
    final borderImage = pw.MemoryImage(borderBytes);

    final dateText = DateFormat('dd MMM yyyy').format(input.completedAt);
    final countText = _formatCount(input.completedCount);

    const heading = PdfColor.fromInt(0xFF7A2F1E);
    const accent = PdfColor.fromInt(0xFFD4AF37);
    const body = PdfColor.fromInt(0xFF3F3026);
    const soft = PdfColor.fromInt(0xFF6F5E4C);

    pdf.addPage(
      pw.Page(
        pageFormat: _pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(50),
                  child: pw.Opacity(
                    opacity: 0.04,
                    child: pw.Image(
                      bgImage,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ),
              pw.Positioned.fill(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Image(
                    borderImage,
                    fit: pw.BoxFit.fill,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(96, 88, 96, 56),
                child: pw.Stack(
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Text(
                          'eRamakoti',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 20,
                            color: PdfColor.fromInt(0xFFB27A22),
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Ramakoti Certificate',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 30,
                            color: heading,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Center(
                          child: pw.Container(
                            width: 320,
                            height: 2,
                            color: accent,
                          ),
                        ),
                        pw.SizedBox(height: 14),
                        pw.Text(
                          'With the divine blessings of Lord Sri Rama',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 13,
                            color: soft,
                          ),
                        ),
                        pw.SizedBox(height: 24),
                        pw.Text(
                          'This certificate is respectfully awarded to',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 15,
                            color: body,
                          ),
                        ),
                        pw.SizedBox(height: 14),
                        pw.Text(
                          input.devoteeName,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: heading,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Center(
                          child: pw.Container(
                            width: 360,
                            height: 1.5,
                            color: accent,
                          ),
                        ),
                        pw.SizedBox(height: 24),
                        pw.Text(
                          'For completing $countText sacred writings of Sri Rama Nama',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            color: body,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'in a spirit of devotion, discipline, and spiritual dedication.',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 14,
                            color: body,
                          ),
                        ),
                        pw.SizedBox(height: 20),
                        pw.Text(
                          'Om Sri Ramaya Namaha',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: heading,
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        pw.Text(
                          'Date: $dateText',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                            color: body,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Certificate ID: ${input.certificateId}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 11,
                            color: soft,
                          ),
                        ),
                        pw.Spacer(),
                      ],
                    ),
                    pw.Positioned(
                      right: 0,
                      bottom: 170,
                      child: pw.Container(
                        width: 110,
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(
                            color: accent,
                            width: 1,
                          ),
                        ),
                        child: pw.Column(
                          children: [
                            pw.SizedBox(
                              width: 88,
                              height: 88,
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: qrData,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Scan to View',
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 8,
                                color: soft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<File> _saveLocally({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final certDir = Directory('${dir.path}/certificates');

    if (!await certDir.exists()) {
      await certDir.create(recursive: true);
    }

    final file = File('${certDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _formatCount(int count) {
    final raw = count.toString();
    final chars = raw.split('').reversed.toList();
    final buffer = StringBuffer();

    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }

    return buffer.toString().split('').reversed.join();
  }
}