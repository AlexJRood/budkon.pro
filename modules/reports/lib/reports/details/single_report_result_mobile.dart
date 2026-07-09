import 'package:flutter/material.dart';

class SingleReportResultMobile extends StatelessWidget {
  final int reportId;
  final Map<String, dynamic> reportPdfData;

  const SingleReportResultMobile({
    super.key,
    required this.reportId,
    required this.reportPdfData,
  });

  @override
  Widget build(BuildContext context) {
    final report = Map<String, dynamic>.from(reportPdfData['report'] ?? {});
    final estimation = Map<String, dynamic>.from(reportPdfData['estimation'] ?? {});

    return Scaffold(
      appBar: AppBar(
        title: Text('Report #$reportId'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                report['street_address'],
                report['city'],
                report['zipcode'],
                report['country'],
              ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', '),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimation'),
                    const SizedBox(height: 8),
                    Text('Estimated value: ${estimation['estimated_value'] ?? '-'} ${estimation['currency'] ?? ''}'),
                    Text('Price per m²: ${estimation['price_per_m2'] ?? '-'} ${estimation['currency'] ?? ''}'),
                    Text('Confidence: ${estimation['confidence'] ?? '-'}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}