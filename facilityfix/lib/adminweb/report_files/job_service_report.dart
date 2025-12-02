import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/services.dart' show rootBundle;

class JobServiceReport {
  /// Generate and download a PDF report for a single job service
  static Future<void> generateAndDownloadSinglePDF({
    required Map<String, dynamic> jobServiceData,
    required String userName,
    String? location,
    String? contactNumber,
    String? email,
  }) async {
    final pdf = pw.Document();

    // Load logo image
    final logoBytes = await rootBundle.load('assets/images/logo.png');
    final logo = pw.Container(
      width: 80,
      height: 80,
      child: pw.Image(pw.MemoryImage(logoBytes.buffer.asUint8List())),
    );

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    // Extract job service details
    final serviceId =
        jobServiceData['serviceId'] ??
        jobServiceData['formatted_id'] ??
        jobServiceData['id'] ??
        'N/A';
    final title =
        jobServiceData['title'] ??
        jobServiceData['description'] ??
        'Job Service Request';
    final status = jobServiceData['status'] ?? 'Pending';
    final priority = jobServiceData['priority'] ?? 'Medium';
    final category =
        jobServiceData['category'] ?? jobServiceData['department'] ?? 'General';
    final requestedBy =
        jobServiceData['requestedBy'] ??
        jobServiceData['requested_by_name'] ??
        jobServiceData['created_by'] ??
        'Unknown';
    final assignedTo =
        jobServiceData['assigned_to_name'] ??
        jobServiceData['assigned_to'] ??
        'Unassigned';
    final buildingUnit =
        jobServiceData['buildingUnit'] ??
        jobServiceData['location'] ??
        jobServiceData['unit_id'] ??
        'N/A';

    // Parse dates
    final createdAt = _parseDate(
      jobServiceData['dateRequested'] ??
          jobServiceData['created_at'] ??
          jobServiceData['date_requested'],
    );
    final scheduledDate = _parseDate(
      jobServiceData['schedule'] ??
          jobServiceData['scheduled_date'] ??
          jobServiceData['date_scheduled'],
    );
    final completedAt = _parseDate(
      jobServiceData['completed_at'] ?? jobServiceData['updated_at'],
    );

    // Calculate time spent
    String timeSpent = 'N/A';
    if (createdAt != null && completedAt != null) {
      final duration = completedAt.difference(createdAt);
      timeSpent = _formatDuration(duration);
    }

    // Get additional details from raw data
    final rawData = jobServiceData['rawData'] ?? jobServiceData;
    final description = rawData['description'] ?? title;
    final additionalNotes =
        jobServiceData['additionalNotes'] ??
        rawData['additional_notes'] ??
        rawData['notes'] ??
        'No additional notes';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(
          8.5 * PdfPageFormat.inch,
          11 * PdfPageFormat.inch,
        ),
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // ===== HEADER SECTION =====
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                logo,
                pw.SizedBox(height: 4),
                pw.Text(
                  'Facility: Smart Maintenance and Repair Analytics Management System',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: [pw.Font.helvetica()],
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  location ?? 'Location: Not Specified',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '${contactNumber ?? 'Contact: N/A'} | ${email ?? 'Email: N/A'}',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Job Service Report - Work Order',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Official Job Service Documentation',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated by: $userName',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Generated at: $formattedDate',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ===== JOB SERVICE DETAILS SECTION =====
            pw.Container(
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'JOB SERVICE DETAILS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(height: 12),

            // ===== BASIC INFO GRID =====
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoField('Job Service ID', serviceId),
                      pw.SizedBox(height: 8),
                      _buildInfoField('Status', _colorizedStatus(status)),
                      pw.SizedBox(height: 8),
                      _buildInfoField('Priority', priority.toUpperCase()),
                      pw.SizedBox(height: 8),
                      _buildInfoField('Category', category),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoField('Building & Unit', buildingUnit),
                      pw.SizedBox(height: 8),
                      _buildInfoField('Requested By', requestedBy),
                      pw.SizedBox(height: 8),
                      _buildInfoField('Assigned To', assignedTo),
                      pw.SizedBox(height: 8),
                      _buildInfoField(
                        'Scheduled Date',
                        _formatDateTime(scheduledDate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ===== JOB DESCRIPTION =====
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Job Service Title',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    title,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ===== DESCRIPTION & NOTES =====
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Description',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    description,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Additional Notes',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    additionalNotes,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ===== TIMELINE SECTION =====
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TIMELINE & TRACKING',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildTimelineField(
                              'Date Requested',
                              _formatDateTime(createdAt),
                            ),
                            pw.SizedBox(height: 10),
                            _buildTimelineField(
                              'Scheduled Date',
                              _formatDateTime(scheduledDate),
                            ),
                            pw.SizedBox(height: 10),
                            _buildTimelineField('Total Time Spent', timeSpent),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildTimelineField(
                              'Completion Date',
                              _formatDateTime(completedAt),
                            ),
                            pw.SizedBox(height: 10),
                            _buildTimelineField(
                              'Current Status',
                              status.toUpperCase(),
                            ),
                            pw.SizedBox(height: 10),
                            _buildTimelineField(
                              'Priority Level',
                              priority.toUpperCase(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ===== SUMMARY TABLE =====
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Table.fromTextArray(
                headers: ['Field', 'Value'],
                data: [
                  ['Job Service ID', serviceId],
                  [
                    'Title',
                    title.length > 50 ? '${title.substring(0, 50)}...' : title,
                  ],
                  ['Status', status],
                  ['Priority', priority],
                  ['Category', category],
                  ['Building & Unit', buildingUnit],
                  ['Requested By', requestedBy],
                  ['Assigned To', assignedTo],
                  ['Date Requested', _formatDateTime(createdAt)],
                  ['Scheduled Date', _formatDateTime(scheduledDate)],
                  ['Time Spent', timeSpent],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4),
                  ),
                ),
                cellStyle: pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
                cellAlignment: pw.Alignment.topLeft,
                cellPadding: pw.EdgeInsets.all(8),
                columnWidths: {
                  0: pw.FlexColumnWidth(1.2),
                  1: pw.FlexColumnWidth(2.0),
                },
                border: pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                tableWidth: pw.TableWidth.max,
                oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey50),
              ),
            ),
            pw.SizedBox(height: 20),

            // ===== FOOTER SECTION =====
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'This is a confidential job service report. Print date: ${_formatDateTime(now)}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page 1 of 1',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Download the PDF for web
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'job_service_${serviceId}.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Generate and download a PDF report for multiple job services
  static Future<void> generateAndDownloadBulkPDF({
    List<Map<String, dynamic>>? jobServices,
    required String userName,
    String? location,
    String? contactNumber,
    String? email,
  }) async {
    final pdf = pw.Document();

    // Use empty list if no services provided
    final services = jobServices ?? [];

    // Load logo image
    final logoBytes = await rootBundle.load('assets/images/logo.png');
    final logo = pw.Container(
      width: 80,
      height: 80,
      child: pw.Image(pw.MemoryImage(logoBytes.buffer.asUint8List())),
    );

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final summaryStats = _calculateSummaryStatistics(services);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(
          8.5 * PdfPageFormat.inch,
          11 * PdfPageFormat.inch,
        ),
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                logo,
                pw.SizedBox(height: 4),
                pw.Text(
                  'Facility: Smart Maintenance and Repair Analytics Management System',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: [pw.Font.helvetica()],
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  location ?? 'Location: Not Specified',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '${contactNumber ?? 'Contact: N/A'} | ${email ?? 'Email: N/A'}',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Job Service Summary Report',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated by: $userName',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Generated at: $formattedDate',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // ===== SUMMARY SECTION =====
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SUMMARY SECTION',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Total Number of Job Service or Repair Tasks: ${services.length}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Date Range: ${summaryStats['dateRange']}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Location Coverage: ${summaryStats['locationCoverage']} unique building(s)/unit(s)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Outstanding Actions: ${summaryStats['outstandingActions']} task(s) requiring immediate attention or follow-up',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ===== TASK STATUS BREAKDOWN =====
            pw.Text(
              'Task Status Breakdown',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Table.fromTextArray(
                headers: ['Status', 'Count', 'Percentage'],
                data: (summaryStats['statusBreakdown'] as List<List<String>>),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4),
                  ),
                ),
                cellStyle: pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
                cellAlignment: pw.Alignment.topLeft,
                cellPadding: pw.EdgeInsets.all(6),
                columnWidths: {
                  0: pw.FlexColumnWidth(1.5),
                  1: pw.FlexColumnWidth(0.8),
                  2: pw.FlexColumnWidth(1),
                },
                border: pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey50),
              ),
            ),
            pw.SizedBox(height: 16),

            // ===== PRIORITY DISTRIBUTION =====
            pw.Text(
              'Priority Distribution',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Table.fromTextArray(
                headers: ['Priority Level', 'Count', 'Percentage'],
                data:
                    (summaryStats['priorityDistribution']
                        as List<List<String>>),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4),
                  ),
                ),
                cellStyle: pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
                cellAlignment: pw.Alignment.topLeft,
                cellPadding: pw.EdgeInsets.all(6),
                columnWidths: {
                  0: pw.FlexColumnWidth(1.5),
                  1: pw.FlexColumnWidth(0.8),
                  2: pw.FlexColumnWidth(1),
                },
                border: pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey50),
              ),
            ),
            pw.SizedBox(height: 16),

            // ===== CATEGORY OVERVIEW =====
            pw.Text(
              'Category Overview',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Table.fromTextArray(
                headers: ['Category', 'Count', 'Percentage'],
                data: (summaryStats['categoryOverview'] as List<List<String>>),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4),
                  ),
                ),
                cellStyle: pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
                cellAlignment: pw.Alignment.topLeft,
                cellPadding: pw.EdgeInsets.all(6),
                columnWidths: {
                  0: pw.FlexColumnWidth(1.5),
                  1: pw.FlexColumnWidth(0.8),
                  2: pw.FlexColumnWidth(1),
                },
                border: pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey50),
              ),
            ),
            pw.SizedBox(height: 16),

            // ===== CORE REPORT CONTENTS =====
            pw.Text(
              'JOB SERVICE DETAILS',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Table.fromTextArray(
                headers: [
                  'Job Service ID',
                  'Job Service Title',
                  'Date Requested',
                  'Building & Unit',
                  'Priority Level',
                  'Category',
                  'Status',
                ],
                data:
                    services
                        .map(
                          (service) => [
                            service['serviceId'] ??
                                service['formatted_id'] ??
                                service['id'] ??
                                '',
                            (service['title'] ?? service['description'] ?? '')
                                        .length >
                                    30
                                ? '${(service['title'] ?? service['description'] ?? '').substring(0, 30)}...'
                                : service['title'] ??
                                    service['description'] ??
                                    '',
                            _formatDateTime(
                              _parseDate(
                                service['dateRequested'] ??
                                    service['created_at'] ??
                                    service['date_requested'],
                              ),
                            ),
                            service['buildingUnit'] ??
                                service['location'] ??
                                service['unit_id'] ??
                                'N/A',
                            service['priority'] ?? 'Medium',
                            service['department'] ?? service['category'] ?? '',
                            service['status'] ?? 'Pending',
                          ],
                        )
                        .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4),
                  ),
                ),
                cellStyle: pw.TextStyle(fontSize: 7, color: PdfColors.grey900),
                cellAlignment: pw.Alignment.topLeft,
                cellPadding: pw.EdgeInsets.all(5),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(0.9),
                  4: pw.FlexColumnWidth(0.7),
                  5: pw.FlexColumnWidth(0.9),
                  6: pw.FlexColumnWidth(0.9),
                },
                border: pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                tableWidth: pw.TableWidth.max,
                oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey50),
              ),
            ),
          ];
        },
      ),
    );

    // Download the PDF for web
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'job_service_summary_${DateTime.now().millisecondsSinceEpoch}.pdf',
      )
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ===== HELPER METHODS =====

  static Map<String, dynamic> _calculateSummaryStatistics(
    List<Map<String, dynamic>> services,
  ) {
    if (services.isEmpty) {
      return {
        'dateRange': 'N/A',
        'locationCoverage': 0,
        'outstandingActions': 0,
        'statusBreakdown': [
          ['No Data', '0', '0%'],
        ],
        'priorityDistribution': [
          ['No Data', '0', '0%'],
        ],
        'categoryOverview': [
          ['No Data', '0', '0%'],
        ],
      };
    }

    // Calculate date range
    final dates =
        services
            .map(
              (service) => _parseDate(
                service['dateRequested'] ??
                    service['created_at'] ??
                    service['date_requested'],
              ),
            )
            .whereType<DateTime>()
            .toList();
    String dateRange = 'N/A';
    if (dates.isNotEmpty) {
      dates.sort();
      final earliest = DateFormat('MMM dd, yyyy').format(dates.first);
      final latest = DateFormat('MMM dd, yyyy').format(dates.last);
      dateRange = '$earliest - $latest';
    }

    // Calculate location coverage
    final locations =
        services
            .map(
              (service) =>
                  service['buildingUnit'] ??
                  service['location'] ??
                  service['unit_id'],
            )
            .toSet()
            .length;

    // Calculate outstanding actions (non-completed tasks)
    final outstanding =
        services.where((service) {
          final status = (service['status'] ?? '').toString().toLowerCase();
          return !status.contains('completed') &&
              !status.contains('done') &&
              !status.contains('resolved');
        }).length;

    // Status breakdown
    final statusMap = <String, int>{};
    for (final service in services) {
      final status = service['status'] ?? 'Unknown';
      statusMap[status] = (statusMap[status] ?? 0) + 1;
    }
    final statusBreakdown =
        statusMap.entries
            .map(
              (e) => [
                e.key,
                e.value.toString(),
                '${((e.value / services.length) * 100).toStringAsFixed(1)}%',
              ],
            )
            .toList();

    // Priority distribution
    final priorityMap = <String, int>{};
    for (final service in services) {
      final priority = service['priority'] ?? 'Medium';
      priorityMap[priority] = (priorityMap[priority] ?? 0) + 1;
    }
    final priorityDistribution =
        priorityMap.entries
            .map(
              (e) => [
                e.key,
                e.value.toString(),
                '${((e.value / services.length) * 100).toStringAsFixed(1)}%',
              ],
            )
            .toList();

    // Category overview
    final categoryMap = <String, int>{};
    for (final service in services) {
      final category =
          service['department'] ?? service['category'] ?? 'Uncategorized';
      categoryMap[category] = (categoryMap[category] ?? 0) + 1;
    }
    final categoryOverview =
        categoryMap.entries
            .map(
              (e) => [
                e.key,
                e.value.toString(),
                '${((e.value / services.length) * 100).toStringAsFixed(1)}%',
              ],
            )
            .toList();

    return {
      'dateRange': dateRange,
      'locationCoverage': locations,
      'outstandingActions': outstanding,
      'statusBreakdown': statusBreakdown,
      'priorityDistribution': priorityDistribution,
      'categoryOverview': categoryOverview,
    };
  }

  static pw.Widget _buildInfoField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
        ),
      ],
    );
  }

  static pw.Widget _buildTimelineField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
        ),
      ],
    );
  }

  static String _colorizedStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('pending')) return '🔵 Pending';
    if (normalized.contains('to inspect') || normalized.contains('assigned'))
      return '🟡 To Inspect';
    if (normalized.contains('in progress')) return '🟠 In Progress';
    if (normalized.contains('assessed')) return '🟣 Assessed';
    if (normalized.contains('approved')) return '🟢 Approved';
    if (normalized.contains('completed') || normalized.contains('done'))
      return '✅ Completed';
    return status;
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String && dateValue.isNotEmpty) {
        return DateTime.parse(dateValue);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }

  static String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final days = duration.inDays;

    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''}, $hours hour${hours != 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hour${hours != 1 ? 's' : ''} $minutes minute${minutes != 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    }
  }
}
