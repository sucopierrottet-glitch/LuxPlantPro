import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/light_audit_record.dart';

class PdfReportService {
  static Future<Uint8List> buildAuditPdfBytes({
    required LightAuditRecord audit,
    required String inspectorName,
    required String projectLocation,
    Uint8List? signaturePngBytes,
  }) async {
    final doc = pw.Document(
      title: 'LuxPlant Pro Technical Report - ${audit.id}',
      author: inspectorName.isEmpty ? 'LuxPlant Pro Auditor' : inspectorName,
    );

    final obsidianColor = PdfColor.fromInt(0xFF0B0F19);
    final slateCard = PdfColor.fromInt(0xFF161F30);
    final emeraldAccent = PdfColor.fromInt(0xFF10B981);
    final goldAccent = PdfColor.fromInt(0xFFF59E0B);
    final borderGrey = PdfColor.fromInt(0xFFCBD5E1);
    final textDark = PdfColor.fromInt(0xFF0F172A);
    final textMuted = PdfColor.fromInt(0xFF475569);

    final dateStr =
        '${audit.timestamp.year}-${audit.timestamp.month.toString().padLeft(2, '0')}-${audit.timestamp.day.toString().padLeft(2, '0')} '
        '${audit.timestamp.hour.toString().padLeft(2, '0')}:${audit.timestamp.minute.toString().padLeft(2, '0')}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: obsidianColor,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LUXPLANT PRO - PHOTOMETRIC & BOTANICAL AUDIT',
                          style: pw.TextStyle(
                            color: emeraldAccent,
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'PPFD / DLI Photosynthetic Analysis, Photo EV & EN 12464-1 / OSHA Compliance',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: slateCard,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        'ID: ${audit.id}',
                        style: pw.TextStyle(
                          color: goldAccent,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Metadata block
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderGrey),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PROJECT / LOCATION: ${projectLocation.isEmpty ? audit.title : projectLocation}',
                          style: pw.TextStyle(
                            color: textDark,
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'AUDITOR / SPECIALIST: ${inspectorName.isEmpty ? "SimpleAppsPG Certified Specialist" : inspectorName}',
                          style: pw.TextStyle(color: textMuted, fontSize: 9.5),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'DATE: $dateStr',
                          style: pw.TextStyle(
                            color: textDark,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'SPECTRUM: ${audit.spectrumName}',
                          style: pw.TextStyle(color: textMuted, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              // Primary Photometric Metrics Grid
              pw.Text(
                '1. INCIDENT PHOTOMETRIC & PHOTOSYNTHETIC MEASUREMENTS (PAR)',
                style: pw.TextStyle(
                  color: textDark,
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  _metricBox(
                    'ILLUMINANCE (LUX)',
                    '${audit.lux.toStringAsFixed(0)} lx',
                    emeraldAccent,
                    textDark,
                  ),
                  pw.SizedBox(width: 10),
                  _metricBox(
                    'FOOT-CANDLES (FC)',
                    '${audit.footCandles.toStringAsFixed(1)} fc',
                    goldAccent,
                    textDark,
                  ),
                  pw.SizedBox(width: 10),
                  _metricBox(
                    'PPFD (PAR FLUX)',
                    '${audit.ppfd.toStringAsFixed(1)} umol/m2/s',
                    emeraldAccent,
                    textDark,
                  ),
                  pw.SizedBox(width: 10),
                  _metricBox(
                    'DAILY DLI (${audit.photoperiodHours.toStringAsFixed(0)}h)',
                    '${audit.dli.toStringAsFixed(2)} mol/m2/d',
                    goldAccent,
                    textDark,
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              // Section 2: Botanical Health Evaluation
              pw.Text(
                '2. BOTANICAL SPECIES DIAGNOSIS & PHOTOPERIOD MATCH',
                style: pw.TextStyle(
                  color: textDark,
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8FAFC),
                  border: pw.Border.all(color: borderGrey),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Target Species: ${audit.plantName} (${audit.plantScientificName})',
                          style: pw.TextStyle(
                            color: textDark,
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: emeraldAccent,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'STATUS: ${audit.plantStatus}',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Photoperiod Configured: ${audit.photoperiodHours.toStringAsFixed(1)} hours/day | '
                      'Active Spectrum: ${audit.spectrumName} | '
                      'Calculated Daily Light Integral: ${audit.dli.toStringAsFixed(2)} mol/m2/day.',
                      style: pw.TextStyle(color: textMuted, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              // Section 3: EN 12464-1 / OSHA & Photography EV
              pw.Text(
                '3. WORKSPACE NORMATIVE COMPLIANCE (EN 12464-1 / OSHA) & PHOTO EV',
                style: pw.TextStyle(
                  color: textDark,
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: borderGrey),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                },
                children: [
                  _tableRow('Evaluated Normative Zone', audit.workspaceZoneName,
                      textDark, textMuted),
                  _tableRow(
                      'Required Minimum Lux (EN 12464-1)',
                      '${audit.workspaceMinLux.toStringAsFixed(0)} lx',
                      textDark,
                      textMuted),
                  _tableRow(
                      'Normative Compliance Verdict',
                      audit.workspaceCompliant
                          ? 'COMPLIANT (>= Minimum Required)'
                          : 'NON-COMPLIANT (Below Minimum Threshold)',
                      textDark,
                      textMuted),
                  _tableRow('Exposure Value (EV100 Base)',
                      '${audit.ev100.toStringAsFixed(2)} EV', textDark, textMuted),
                  _tableRow('Reference Camera Setting',
                      audit.shutterRecommendation, textDark, textMuted),
                ],
              ),
              pw.Spacer(),

              // Signature Footer
              pw.Divider(color: borderGrey),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (signaturePngBytes != null &&
                          signaturePngBytes.isNotEmpty)
                        pw.Container(
                          height: 55,
                          width: 170,
                          margin: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Image(
                            pw.MemoryImage(signaturePngBytes),
                            fit: pw.BoxFit.contain,
                          ),
                        )
                      else
                        pw.SizedBox(height: 45),
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: textDark,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        inspectorName.isEmpty
                            ? 'Authorized Signature - Lighting & Botany Auditor'
                            : 'Signed by: $inspectorName',
                        style: pw.TextStyle(
                          color: textDark,
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Certified Photometric Audit • EN 12464-1 / PAR Protocol',
                        style: pw.TextStyle(color: textMuted, fontSize: 8.5),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated by LuxPlant Pro v1.0.0',
                        style: pw.TextStyle(
                          color: textDark,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'SimpleAppsPG • 100% Offline-First Precision Tool',
                        style: pw.TextStyle(color: textMuted, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _metricBox(
    String label,
    String value,
    PdfColor accent,
    PdfColor textDark,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: accent, width: 1.2),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColor.fromInt(0xFF64748B),
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _tableRow(
    String key,
    String val,
    PdfColor textDark,
    PdfColor textMuted,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(7),
          child: pw.Text(
            key,
            style: pw.TextStyle(
              color: textDark,
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(7),
          child: pw.Text(
            val,
            style: pw.TextStyle(color: textMuted, fontSize: 9.5),
          ),
        ),
      ],
    );
  }

  static Future<void> previewAndSharePdf({
    required LightAuditRecord audit,
    required String inspectorName,
    required String projectLocation,
    Uint8List? signaturePngBytes,
  }) async {
    final bytes = await buildAuditPdfBytes(
      audit: audit,
      inspectorName: inspectorName,
      projectLocation: projectLocation,
      signaturePngBytes: signaturePngBytes,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'LuxPlantPro_Audit_${audit.id}.pdf',
    );
  }
}
