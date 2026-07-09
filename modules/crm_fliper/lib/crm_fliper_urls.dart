import 'package:core/platform/url.dart';

/// crm_fliper feature API endpoints, decentralized out of core's URLs God-package.
class CrmFliperUrls {
  const CrmFliperUrls._();

static final createExpenses = URLs.appendBaseUrl('/fliper/fliper/expenses/');
static final createFlipperSale = URLs.appendBaseUrl('/fliper/fliper/sales/');
static final createNegotiationHistory = URLs.appendBaseUrl(
    '/fliper/fliper/negotiation-history/',
  );
static final createRevenue = URLs.appendBaseUrl('/fliper/fliper/revenues/');
static final createSaleClient = URLs.appendBaseUrl('/fliper/fliper/sale-clients/');
static final createSaleDocument = URLs.appendBaseUrl(
    '/fliper/fliper/sale-documents/',
  );
static final createTransactionChecklistCopyPredefined = URLs.appendBaseUrl(
    '/fliper/fliper/transaction-checklists/copy-predefined/',
  );
static final fetchActivityTimeLine = URLs.appendBaseUrl(
    '/fliper/fliper/activity-timeline/',
  );
static String fetchActivityTimeLineById(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/activity-timeline/$id/');
static final fetchDraftAdvertisements = URLs.appendBaseUrl(
    '/fliper/fliper/draft-advertisments/',
  );
static final fetchExpenses = URLs.appendBaseUrl('/fliper/fliper/expenses/');
static final fetchFlipCalculation = URLs.appendBaseUrl(
    '/fliper/fliper/flip-calculations/',
  );
static final fetchFlipperEvents = URLs.appendBaseUrl('/fliper/fliper/events/');
static final fetchFlipperSales = URLs.appendBaseUrl('/fliper/fliper/sales');
static final fetchNegotiationHistory = URLs.appendBaseUrl(
    '/fliper/fliper/negotiation-history/',
  );
static final fetchNegotiationStatuses = URLs.appendBaseUrl(
    '/fliper/fliper/negotiations-statuses/',
  );
static final fetchPredefinedChecklist = URLs.appendBaseUrl(
    '/fliper/fliper/predefined-checklists/',
  );
static final fetchQuickFlipCosts = URLs.appendBaseUrl(
    '/fliper/fliper/quick-flip-costs/',
  );
static final fetchRenovationCosts = URLs.appendBaseUrl(
    '/fliper/fliper/renovation-costs/',
  );
static final fetchRenovationProgress = URLs.appendBaseUrl(
    '/fliper/fliper/renovation-progress/',
  );
static final fetchRenovationSchedules = URLs.appendBaseUrl(
    '/fliper/fliper/renovation-schedules/',
  );
static final fetchRenovationTask = URLs.appendBaseUrl(
    '/fliper/fliper/renovation-tasks/',
  );
static final fetchRevenues = URLs.appendBaseUrl('/fliper/fliper/revenues/');
static final fetchSaleClient = URLs.appendBaseUrl('/fliper/fliper/sale-clients');
static final fetchSaleClients = URLs.appendBaseUrl('/fliper/fliper/sale-clients/');
static final fetchSaleDocument = URLs.appendBaseUrl(
    '/fliper/fliper/sale-documents/',
  );
static final fetchSales = URLs.appendBaseUrl('/fliper/fliper/sales/');
static String fetchSingleDraftAdvertisements(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/draft-advertisments/$id/');
static String fetchSingleExpenses(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/expenses/$id/');
static String fetchSingleFlipCalculation(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/flip-calculations/$id');
static String fetchSingleFlipperEvents(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/events/$id');
static String fetchSingleNegotiationHistory(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/negotiation-history/$id/');
static String fetchSingleNegotiationStatuses(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/negotiations-statuses/$id/');
static String fetchSinglePredefinedChecklist(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/predefined-checklists/$id/');
static String fetchSingleQuickFlipCosts(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/quick-flip-costs/$id/');
static String fetchSingleRenovationCosts(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/renovation-costs/$id/');
static String fetchSingleRenovationProgress(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/renovation-progress/$id/');
static String fetchSingleRenovationSchedules(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/renovation-schedules/$id/');
static String fetchSingleRenovationTask(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/renovation-tasks/$id/');
static String fetchSingleRevenues(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/revenues/$id/');
static String fetchSingleSaleClients(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/sale-clients/$id/');
static String fetchSingleSaleDocument(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/sale-document/$id/');
static String fetchSingleSales(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/sales/$id/');
static String fetchSingleTransactionDocument(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/transaction-documents/$id/');
static String fetchSingleTransactions(String id) =>
      URLs.appendBaseUrl('/fliper/fliper/transactions/$id/');
static String fetchSingleViewerStatus(String id) =>
      URLs.appendBaseUrl('fliper/fliper/viewer-statuses/$id/');
static final fetchTransactionDocument = URLs.appendBaseUrl(
    '/fliper/fliper/transaction-documents/',
  );
static final fetchTransactions = URLs.appendBaseUrl(
    '/fliper/fliper/transactions/',
  );
static final fetchViewerStatus = URLs.appendBaseUrl(
    'fliper/fliper/viewer-statuses/',
  );
static final refurbishmentCreateProgress = URLs.appendBaseUrl(
    '/fliper/fliper/renovation-progress/',
  );
static final refurbishmentCreateTask = URLs.appendBaseUrl(
    '/fliper/fliper/renovation-tasks/',
  );
static final refurbishmentFetchProgress = URLs.appendBaseUrl(
    '/fliper/fliper/renovation-progress/',
  );
static final refurbishmentFetchTasks = URLs.appendBaseUrl(
    '/fliper/fliper/renovation-tasks',
  );
}
