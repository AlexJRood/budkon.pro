import 'package:flutter/material.dart';

class SingleReportResultPc extends StatelessWidget {
  final int reportId;
  final Map<String, dynamic> reportPdfData;

  const SingleReportResultPc({
    super.key,
    required this.reportId,
    required this.reportPdfData,
  });

  @override
  Widget build(BuildContext context) {
    final report = Map<String, dynamic>.from(reportPdfData['report'] ?? {});
    final estimation = Map<String, dynamic>.from(reportPdfData['estimation'] ?? {});
    final pricesInArea = Map<String, dynamic>.from(reportPdfData['prices_in_area'] ?? {});
    final accuracyIndex = Map<String, dynamic>.from(reportPdfData['accuracy_index'] ?? {});
    final comparable = List<Map<String, dynamic>>.from(
      (reportPdfData['comparable'] ?? []).map((e) => Map<String, dynamic>.from(e)),
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report #$reportId',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    report['street_address'],
                    report['city'],
                    report['zipcode'],
                    report['country'],
                  ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', '),
                ),
                const SizedBox(height: 24),

                _SectionCard(
                  title: 'Estimation',
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _MetricItem(
                        label: 'Estimated value',
                        value: '${estimation['estimated_value'] ?? '-'} ${estimation['currency'] ?? ''}',
                      ),
                      _MetricItem(
                        label: 'Price per m²',
                        value: '${estimation['price_per_m2'] ?? '-'} ${estimation['currency'] ?? ''}',
                      ),
                      _MetricItem(
                        label: 'Confidence',
                        value: '${estimation['confidence'] ?? '-'}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _SectionCard(
                  title: 'Prices in area',
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _MetricItem(
                        label: 'Min',
                        value: '${pricesInArea['min_price'] ?? '-'} ${pricesInArea['currency'] ?? ''}',
                      ),
                      _MetricItem(
                        label: 'Avg',
                        value: '${pricesInArea['average_price'] ?? '-'} ${pricesInArea['currency'] ?? ''}',
                      ),
                      _MetricItem(
                        label: 'Max',
                        value: '${pricesInArea['max_price'] ?? '-'} ${pricesInArea['currency'] ?? ''}',
                      ),
                      _MetricItem(
                        label: 'Sample size',
                        value: '${pricesInArea['sample_size'] ?? '-'}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _SectionCard(
                  title: 'Accuracy',
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _MetricItem(
                        label: 'Accuracy',
                        value: '${accuracyIndex['percentage'] ?? '-'}%',
                      ),
                      _MetricItem(
                        label: 'Offers count',
                        value: '${accuracyIndex['offers_count'] ?? '-'}',
                      ),
                      _MetricItem(
                        label: 'Area m²',
                        value: '${accuracyIndex['area_m2'] ?? '-'}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _SectionCard(
                  title: 'Comparable offers',
                  child: comparable.isEmpty
                      ? const Text('No comparable offers')
                      : Column(
                          children: comparable.map((item) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['title']?.toString() ?? 'Untitled'),
                              subtitle: Text(
                                [
                                  item['city'],
                                  item['street'],
                                  item['district'],
                                ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', '),
                              ),
                              trailing: Text(
                                '${item['price'] ?? '-'} ${item['currency'] ?? ''}',
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}