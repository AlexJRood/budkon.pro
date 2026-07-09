import 'package:intl/intl.dart';

class DocumentFilter {
  final Map<String, String> filters = {};

  // Generic filters
  void addFilter(String key, dynamic value) {
    if (value != null) {
      filters[key] = value.toString();
    }
  }

  // Status filters
  void addStatus(String status) {
    if (status.isNotEmpty) {
      filters['status'] = status;
    } 
  }

  void addStatusList(List<String> statuses) {
    if (statuses.isNotEmpty) {
      filters['status_in'] = statuses.join(',');
    }
  }

  // Date range filters
  void addDateCreatedRange(DateTime? after, DateTime? before) {
    if (after != null) {
      filters['date_created_after'] = DateFormat('yyyy-MM-dd').format(after);
    }
    if (before != null) {
      filters['date_created_before'] = DateFormat('yyyy-MM-dd').format(before);
    }
  }

  void addDateUpdatedRange(DateTime? after, DateTime? before) {
    if (after != null) {
      filters['date_updated_after'] = DateFormat('yyyy-MM-dd').format(after);
    }
    if (before != null) {
      filters['date_updated_before'] = DateFormat('yyyy-MM-dd').format(before);
    }
  }

  // Search
  void addSearch(String searchTerm) {
    if (searchTerm.isNotEmpty) {
      filters['search'] = searchTerm;
    }
  }

  // Ordering
  void addOrdering(String field, bool descending) {
    if (field.isNotEmpty) {
      filters['ordering'] = '${descending ? '-' : ''}$field';
    }
  }

  // Multiple ordering
  void addMultiOrdering(List<String> fields) {
    if (fields.isNotEmpty) {
      filters['ordering'] = fields.join(',');
    }
  }

  // Build query string
  String buildQuery() {
    if (filters.isEmpty) return '';
    
    final queryParams = filters.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    
    return '?$queryParams';
  }

  // Clear filters
  void clear() {
    filters.clear();
  }
}