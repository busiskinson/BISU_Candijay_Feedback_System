import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/report_model.dart';

class ReportHtmlGenerator {
  // Cache so images are only read/encoded once per app session.
  static String? _bisuLogoDataUri;
  static String? _bagongLogoDataUri;
  static String? _isoLogoDataUri;

  static Future<String> _loadAsDataUri(String assetPath, String mimeType) async {
    final bytes = await rootBundle.load(assetPath);
    final base64Str = base64Encode(bytes.buffer.asUint8List());
    return 'data:$mimeType;base64,$base64Str';
  }

  static Future<void> _ensureLogosLoaded() async {
    _bisuLogoDataUri ??= await _loadAsDataUri('image/img.png', 'image/png');
    _bagongLogoDataUri ??= await _loadAsDataUri('image/img_1.png', 'image/png');
    _isoLogoDataUri ??= await _loadAsDataUri('image/img.jpeg', 'image/jpeg');
  }

  static String _letterheadHtml() {
    return '''
      <div class="letterhead">
        <img class="seal" src="$_bisuLogoDataUri" width="50" height="50" />
        <div class="info">
          <div class="country">Republic of the Philippines</div>
          <div class="uni">BOHOL ISLAND STATE UNIVERSITY</div>
          <div class="addr">Candijay, 6312, Bohol, Philippines</div>
          <div class="office">Office of the Quality Assurance</div>
          <div class="tagline">Balance | Innovativeness | Stewardship | Uprightness</div>
        </div>
        <div class="badges">
          <img src="$_bagongLogoDataUri" />
          <img src="$_isoLogoDataUri" />
        </div>
      </div>
    ''';
  }

  static const monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const dimKeys = [
    'responsiveness', 'reliability', 'accessFacilities', 'communication',
    'costs', 'integrity', 'assurance', 'outcome',
  ];
  static const dimLabels = [
    'Responsiveness', 'Reliability', 'Access & Facilities', 'Communication',
    'Costs', 'Integrity', 'Assurance', 'Outcome',
  ];

  static Future<String> build({
    required String reportType,
    required int year,
    required int month,
    required List<OfficeReportBreakdown> breakdowns,
    OfficeReportBreakdown? overall,
    required Map<String, String> detailSuggestions,
    required Map<String, String> rootCauses,
    required Map<String, String> actionPlans,
    required Map<String, String> targets,
    required Map<String, String> statuses,
    String? preparedByName,
    String? verifiedByName,
    String? approvedByName,
  }) async {
    await _ensureLogosLoaded();

    final isSummary = reportType == 'CSF Summary Report';
    final showOverall = isSummary && breakdowns.length > 1 && overall != null;
    final rows = [...breakdowns, if (showOverall) overall!];

    final title = isSummary
        ? 'MONTHLY CUSTOMER SATISFACTION SUMMARY REPORT'
        : 'MONTHLY REPORT CARD';

    final formCode = isSummary ? 'F-AQA-CSF-002' : 'F-AQA-CSF-001';

    final subHeader = isSummary
        ? '<div class="sub">Month: ${monthNames[month]} $year</div><div class="campus-line">Campus: <u>Candijay</u></div>'
        : (breakdowns.isNotEmpty
        ? '<div class="row-between"><b>Office Concerned: ${_esc(breakdowns.first.officeName)}</b><b>Month: ${monthNames[month]} $year</b></div>'
        : '');

    // CSF Summary Report: each section on its own page, ending with signatures.
    // Monthly Report Card: everything flows on one page, no signature block.
    final sectionBBreak = isSummary ? 'page-break' : '';
    final sectionCBreak = isSummary ? 'page-break' : '';
    final signatureSection = isSummary
        ? '<div class="page-break"></div>${_signatureBlock(preparedByName, verifiedByName, approvedByName)}'
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>$title</title>
<style>
  @page { size: 297mm 210mm; margin: 3mm 10mm; }
  * { box-sizing: border-box; }
  body { font-family: Arial, Helvetica, sans-serif; color: #1a1a1a; font-size: 10px; margin: 0; }
  .page-wrapper { width: 100%; border-collapse: collapse; }
  .page-wrapper > thead > tr > td,
  .page-wrapper > tfoot > tr > td { padding: 0; }
  .letterhead { display: flex; align-items: center; border-bottom: 1px solid #999; padding: 6mm 0 8px; }
  .letterhead img.seal { width: 50px; height: 50px; margin-right: 10px; }
  .letterhead .info { flex: 1; }
  .letterhead .info .country { font-size: 9px; }
  .letterhead .info .uni { font-size: 13px; font-weight: bold; }
  .letterhead .info .addr, .letterhead .info .office { font-size: 8px; color: #444; }
  .letterhead .info .tagline { font-size: 8px; font-style: italic; color: #444; margin-top: 2px; }
  .letterhead .badges img { height: 36px; width: auto; max-width: 44px; margin-left: 8px; object-fit: contain; }
  .footer-content { font-size: 7.5px; color: #666; display: flex; justify-content: space-between; border-top: 0.5px solid #ccc; padding: 4px 0 4mm; }
  h1 { text-align: center; font-size: 15px; margin: 10px 0 2px; }
  .sub { text-align: center; font-size: 10.5px; color: #555; margin-bottom: 2px; }
  .campus-line { text-align: right; font-size: 9.5px; margin-bottom: 12px; }
  .row-between { display: flex; justify-content: space-between; font-size: 10.5px; margin-bottom: 16px; }
  .section-label { font-size: 11px; font-weight: bold; border-bottom: 1.4px solid #4A1D6E; padding-bottom: 4px; margin: 18px 0 8px; }
  .page-break { page-break-before: always; }
  .sig-block { margin-top: 40px; }
  .sig-row { display: flex; justify-content: space-between; margin-bottom: 56px; }
  .sig-col { width: 46%; }
  .sig-role { font-size: 9px; color: #444; margin-bottom: 30px; }
  .sig-name { text-align: center; font-size: 10.5px; font-weight: bold; min-height: 14px; }
  .sig-line { border-top: 1px solid #333; margin-top: 2px; }
  .sig-caption { font-size: 8px; color: #666; text-align: center; margin-top: 3px; }
  .content-table { width: 100%; border-collapse: collapse; margin-bottom: 6px; }
  .content-table th, .content-table td { border: 0.5px solid #bbb; padding: 2.5px 3px; font-size: 6.5px; text-align: center; line-height: 1.25; }
  .content-table th { background: #f1eef6; font-weight: bold; }
  .content-table td.left, .content-table th.left { text-align: left; }
  .comm-table th, .comm-table td { font-size: 8px; text-align: left; vertical-align: top; }
  @media print {
    body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  }
</style>
</head>
<body>

  <table class="page-wrapper">
    <thead>
      <tr><td>${_letterheadHtml()}</td></tr>
    </thead>
    <tfoot>
      <tr><td>
        <div class="footer-content">
          <span>$formCode | Rev. 3 | 09/09/25</span>
          <span>Bohol Island State University - Candijay Campus</span>
        </div>
      </td></tr>
    </tfoot>
    <tbody>
      <tr><td>

        <h1>$title</h1>
        $subHeader

        <div class="section-label">A. Citizen's Charter Summary Result</div>
        ${_charterTable(rows)}

        <div class="section-label $sectionBBreak">B. CSF Monthly Rating</div>
        ${_ratingTable(rows)}

        <div class="section-label $sectionCBreak">${isSummary ? 'C. CSF Monthly Commendations & Suggestions' : 'CSF Monthly Commendations and Suggestions'}</div>
        ${_commendationsTable(breakdowns, detailSuggestions, rootCauses, actionPlans, targets, statuses)}

        $signatureSection

      </td></tr>
    </tbody>
  </table>

  <script>
    window.onload = function() {
      window.focus();
      window.print();
    };
  </script>
</body>
</html>
''';
  }

  static String _signatureBlock(String? preparedBy, String? verifiedBy, String? approvedBy) {
    String name(String? v) => (v != null && v.trim().isNotEmpty) ? _esc(v.trim()) : '&nbsp;';

    return '''
    <div class="sig-block">
      <div class="sig-row">
        <div class="sig-col">
          <div class="sig-role">Prepared:</div>
          <div class="sig-name">${name(preparedBy)}</div>
          <div class="sig-line"></div>
          <div class="sig-caption">&lt;Name &amp; Signature of Chairperson, Customer Satisfaction Assessment Team&gt;</div>
        </div>
        <div class="sig-col">
          <div class="sig-role">Verified:</div>
          <div class="sig-name">${name(verifiedBy)}</div>
          <div class="sig-line"></div>
          <div class="sig-caption">&lt;Name &amp; Signature of Campus Quality Assurance Director&gt;</div>
        </div>
      </div>
      <div class="sig-row">
        <div class="sig-col">
          <div class="sig-role">Approved:</div>
          <div class="sig-name">${name(approvedBy)}</div>
          <div class="sig-line"></div>
          <div class="sig-caption">&lt;Name &amp; Signature of Campus Director&gt;</div>
        </div>
        <div class="sig-col"></div>
      </div>
    </div>
    ''';
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('\n', '<br/>');

  static String _charterTable(List<OfficeReportBreakdown> rows) {
    if (rows.isEmpty) return '<p>No data for this period.</p>';

    const headers = [
      'Offices', 'Cust.', 'M', 'F', 'Citizen', 'Business', "Gov't", 'Student',
      'CC1-1', 'CC1-2', 'CC1-3', 'CC1-4',
      'CC2-1', 'CC2-2', 'CC2-3', 'CC2-4', 'CC2-5',
      'CC3-1', 'CC3-2', 'CC3-3', 'CC3-4',
    ];

    final headHtml = headers.map((h) => '<th${h == 'Offices' ? ' class="left"' : ''}>${_esc(h)}</th>').join();

    final bodyHtml = rows.map((b) {
      final cells = [
        b.officeName, '${b.numberOfCustomers}', '${b.sexMale}', '${b.sexFemale}',
        '${b.clientCitizen}', '${b.clientBusiness}', '${b.clientGovernment}', '${b.clientStudent}',
        '${b.cc1Counts[1] ?? 0}', '${b.cc1Counts[2] ?? 0}', '${b.cc1Counts[3] ?? 0}', '${b.cc1Counts[4] ?? 0}',
        '${b.cc2Counts[1] ?? 0}', '${b.cc2Counts[2] ?? 0}', '${b.cc2Counts[3] ?? 0}', '${b.cc2Counts[4] ?? 0}', '${b.cc2Counts[5] ?? 0}',
        '${b.cc3Counts[1] ?? 0}', '${b.cc3Counts[2] ?? 0}', '${b.cc3Counts[3] ?? 0}', '${b.cc3Counts[4] ?? 0}',
      ];
      final tds = cells.asMap().entries.map((e) =>
      '<td${e.key == 0 ? ' class="left"' : ''}>${_esc(e.value)}</td>').join();
      return '<tr>$tds</tr>';
    }).join();

    return '<table class="content-table"><thead><tr>$headHtml</tr></thead><tbody>$bodyHtml</tbody></table>';
  }

  static String _ratingTable(List<OfficeReportBreakdown> rows) {
    if (rows.isEmpty) return '<p>No data for this period.</p>';

    final headers = ['Offices', 'Cust.', ...dimLabels, 'Mean', 'Description'];
    final headHtml = headers.map((h) => '<th${h == 'Offices' ? ' class="left"' : ''}>${_esc(h)}</th>').join();

    final bodyHtml = rows.map((b) {
      final cells = [
        b.officeName,
        '${b.numberOfCustomers}',
        for (final key in dimKeys)
          b.dimensionMeans[key] == null ? '—' : b.dimensionMeans[key]!.toStringAsFixed(2),
        b.meanSatisfaction == null ? '—' : b.meanSatisfaction!.toStringAsFixed(2),
        b.description,
      ];
      final tds = cells.asMap().entries.map((e) =>
      '<td${e.key == 0 ? ' class="left"' : ''}>${_esc(e.value)}</td>').join();
      return '<tr>$tds</tr>';
    }).join();

    return '<table class="content-table"><thead><tr>$headHtml</tr></thead><tbody>$bodyHtml</tbody></table>';
  }

  static String _commendationsTable(
      List<OfficeReportBreakdown> rows,
      Map<String, String> detailSuggestions,
      Map<String, String> rootCauses,
      Map<String, String> actionPlans,
      Map<String, String> targets,
      Map<String, String> statuses,
      ) {
    if (rows.isEmpty) return '<p>No data for this period.</p>';

    const headers = [
      'Office', 'Commendations', 'Detail of Suggestions', 'Root Cause',
      'Action Plan', 'Target of Implementation', 'Status of Implementation',
    ];
    final headHtml = headers.map((h) => '<th>${_esc(h)}</th>').join();

    final bodyHtml = rows.map((b) {
      final commendations = b.commendations
          .take(3)
          .toList()
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${_esc(e.value)}')
          .join('<br/>');
      final cells = [
        _esc(b.officeName),
        commendations,
        _esc(detailSuggestions[b.officeName] ?? ''),
        _esc(rootCauses[b.officeName] ?? ''),
        _esc(actionPlans[b.officeName] ?? ''),
        _esc(targets[b.officeName] ?? ''),
        _esc(statuses[b.officeName] ?? ''),
      ];
      final tds = cells.map((c) => '<td>$c</td>').join();
      return '<tr>$tds</tr>';
    }).join();

    return '<table class="content-table comm-table"><thead><tr>$headHtml</tr></thead><tbody>$bodyHtml</tbody></table>';
  }
}