import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/mandali_certificate_input.dart';

class GeneratedMandaliCertificateResult {
  final File file;
  final String storagePath;
  final String downloadUrl;

  const GeneratedMandaliCertificateResult({
    required this.file,
    required this.storagePath,
    required this.downloadUrl,
  });
}

class MandaliCertificateGeneratorService {
  MandaliCertificateGeneratorService._();

  static final MandaliCertificateGeneratorService instance =
  MandaliCertificateGeneratorService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _bgAssetPath =
      'assets/images/ramakoti_certificate_bg.jpg';
  static const String _borderAssetPath =
      'assets/images/certificate_border.png';
  static const String _fontPath = 'assets/fonts/NotoSerif-Regular.ttf';

  static const PdfPageFormat _pageFormat = PdfPageFormat(980, 620);

  Future<GeneratedMandaliCertificateResult> generateAndUploadCertificate({
    required MandaliCertificateInput input,
  }) async {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    final storagePath =
        'mandaliCertificates/$year/$month/$day/${input.mandaliId}/${input.certificateId}.pdf';

    final qrData = input.certificateId;

    final bytes = await _buildPdfBytes(
      input: input,
      qrData: qrData,
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

    return GeneratedMandaliCertificateResult(
      file: file,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
    );
  }

  Future<Uint8List> _buildPdfBytes({
    required MandaliCertificateInput input,
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
    final targetText = _formatCount(input.challengeTarget);
    final recipientsText = _formatCount(input.recipientCount);

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
                padding: const pw.EdgeInsets.fromLTRB(96, 78, 96, 72),
                child: pw.Stack(
                  children: [
                    pw.Center(
                      child: pw.SizedBox(
                        width: 600,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'eRamakoti',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 18,
                                color: PdfColor.fromInt(0xFFB27A22),
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Bhakta Mandali Certificate',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 24,
                                color: heading,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Center(
                              child: pw.Container(
                                width: 340,
                                height: 2,
                                color: accent,
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            pw.SizedBox(height: 18),
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
                            pw.Center(
                              child: pw.SizedBox(
                                width: 500,
                                height: 40,
                                child: pw.FittedBox(
                                  fit: pw.BoxFit.scaleDown,
                                  child: pw.Text(
                                    input.mandaliName,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 30,
                                      fontWeight: pw.FontWeight.bold,
                                      color: heading,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Center(
                              child: pw.Container(
                                width: 430,
                                height: 1.5,
                                color: accent,
                              ),
                            ),
                            pw.SizedBox(height: 14),
                            pw.Text(
                              'For successfully completing the Mandali challenge',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 15,
                                color: body,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Center(
                              child: pw.SizedBox(
                                width: 500,
                                height: 34,
                                child: pw.FittedBox(
                                  fit: pw.BoxFit.scaleDown,
                                  child: pw.Text(
                                    input.challengeName,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 23,
                                      fontWeight: pw.FontWeight.bold,
                                      color: heading,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            pw.Text(
                              'Challenge Target: $targetText Sri Rama Namas',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 15,
                                fontWeight: pw.FontWeight.bold,
                                color: body,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Participating Devotees: $recipientsText',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 13,
                                color: body,
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            pw.Text(
                              'Completed in devotion, unity, and collective Nama smarana.',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 13,
                                color: body,
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            pw.Text(
                              'Jai Shri Ram',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: heading,
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            pw.Text(
                              'Date: $dateText',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 12,
                                color: body,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Center(
                              child: pw.SizedBox(
                                width: 360,
                                height: 14,
                                child: pw.FittedBox(
                                  fit: pw.BoxFit.scaleDown,
                                  child: pw.Text(
                                    'Certificate ID: ${input.certificateId}',
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 11,
                                      color: soft,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.Positioned(
                      right: 8,
                      top: 205,
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
    final certDir = Directory('${dir.path}/mandali_certificates');

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