import 'package:core/platform/url.dart';

/// crm feature API endpoints, decentralized out of core's URLs God-package.
class CrmUrls {
  const CrmUrls._();

static final addFinanceAppExpenses = URLs.appendBaseUrl(
    '/finance/expenses/create/',
  );
static String addPlanExpenseFinancialPlans(String planId) =>
      URLs.appendBaseUrl('/financial-plans/expenses/add_plan_to/$planId/');
static String addPlanRevenueFinancialPlans(String planId) =>
      URLs.appendBaseUrl('/financial-plans/revenues/add_plan_to/$planId');
static String advertiseOffer(String offerId) =>
      URLs.appendBaseUrl('/portal/advertisements/$offerId/');
static final agentDashboard = URLs.appendBaseUrl('/agent/dashboard/');
static String agentKwStatus(int txId) =>
      URLs.appendBaseUrl('/agent/transaction/$txId/kw/status/');
static String agentKwTrigger(int txId) =>
      URLs.appendBaseUrl('/agent/transaction/$txId/kw/trigger/');
static String agentTransactionByUserContact(String clientId) =>
      URLs.appendBaseUrl('/agent/transaction/$clientId/');
static final agentTransactionUpdateColumnIndexes = URLs.appendBaseUrl(
    '/agent/status/update-column-indexes/',
  );
static final agentTransactionsCrm = URLs.appendBaseUrl('/agent/transaction/');
static final availableYearsExpensesFinancialPlans = URLs.appendBaseUrl(
    '/financial-plans/expenses/available_years/',
  );
static final availableYearsRevenueFinancialPlans = URLs.appendBaseUrl(
    '/financial-plans/revenues/available_years/',
  );
static final clientDetails = URLs.appendBaseUrl('/agent/client/summary/');
static String clientSearches(String clientId) =>
      URLs.appendBaseUrl('/contacts/$clientId/saved_searches/');
static String commentsByUserContacts(String clientId) =>
      URLs.appendBaseUrl('/contacts/$clientId/comments/');
static final contactServiceType = URLs.appendBaseUrl('/agent/service-types/');
static final contactType = URLs.appendBaseUrl('/contacts/types/');
static final createCrm = URLs.appendBaseUrl('/agent/transaction/create/');
static String deleteFinanceAppExpenses(String financeAppExpensesId) =>
      URLs.appendBaseUrl('/finance/expenses/delete/$financeAppExpensesId');
static String deleteRevenuesCrm(String id) =>
      URLs.appendBaseUrl('/agent/transaction/delete/$id/');
static String draftAdvertisement(String adId) =>
      URLs.appendBaseUrl('/portal/draft/advertisements/$adId/');
static final estateAgentAddViewer = URLs.appendBaseUrl('/agent/add/viewer/');
static final expensesFinancialPlans = URLs.appendBaseUrl(
    '/financial-plans/expenses/',
  );
static final expensesUpdateColumn = URLs.appendBaseUrl(
    '/finance/expenses/update-column-indexes/',
  );
static final expensesUpdateTransaction = URLs.appendBaseUrl(
    '/finance/expenses/update-statuses/',
  );
static String favoriteSetStatus(int favoriteId) =>
      URLs.appendBaseUrl('/networkmonitoring/favorites/$favoriteId/status/');
static String favoriteStatusTypesReorder = URLs.appendBaseUrl(
    '/networkmonitoring/favorite/statuses/reorder/',
  );
static String favoriteTxSetStatus(int favoriteId, int txId) => URLs.appendBaseUrl(
    '/networkmonitoring/favorites/$favoriteId/transactions/$txId/status/',
  );
static String filterTaskByClient(String clientId) =>
      URLs.appendBaseUrl('/tms/task/tasks-by-client/$clientId/');
static final financeAppExpenses = URLs.appendBaseUrl('/finance/expenses/');
static final financeAppExpensesStatus = URLs.appendBaseUrl(
    '/finance/expenses/statuses/',
  );
static final financeAppRevenues = URLs.appendBaseUrl('/finance/revenues/');
static final financeAppRevenuesStatus = URLs.appendBaseUrl(
    '/finance/revenues/statuses/',
  );
static final getAgentTransactionStatus = URLs.appendBaseUrl(
    '/agent/transaction/statuses/',
  );
static final hideMonitoring = URLs.appendBaseUrl('/networkmonitoring/hide/');
static final payedStatusExpensesFinancialPlans = URLs.appendBaseUrl(
    '/financial-plans/expenses/toggle_is_payed_status/',
  );
static final payedStatusRevenueFinancialPlans = URLs.appendBaseUrl(
    '/financial-plans/revenues/toggle_is_payed_status/',
  );
static final revenueFinancialPlans = URLs.appendBaseUrl(
    '/financial-plans/revenues/',
  );
static final revenuesUpdateColumn = URLs.appendBaseUrl(
    '/finance/revenues/update-column-indexes/',
  );
static final revenuesUpdateTransaction = URLs.appendBaseUrl(
    '/finance/revenues/update-statuses/',
  );
static String singleEstateAgentAdvertismentDraft(String offerId) =>
      URLs.appendBaseUrl('/portal/draft/advertisements/$offerId/');
static String singleExpensesFinancialPlans(String planId) =>
      URLs.appendBaseUrl('/financial-plans/expenses/$planId');
static String singleRevenueFinancialPlans(String planId) =>
      URLs.appendBaseUrl('/financial-plans/revenues/$planId/');
static String singleUserContacts(String clientId) =>
      URLs.appendBaseUrl('/contacts/$clientId/');
static final summaryFinancialPlans = URLs.appendBaseUrl(
    '/financial-plans/summary/',
  );
static String transActionByClient(String clientId) =>
      URLs.appendBaseUrl('/agent/transaction/$clientId/');
static String transactionSearches(String transactionId) =>
      URLs.appendBaseUrl('/transaction/$transactionId/saved_searches/');
static String transactionViewerEvents(int txId, int viewerId) =>
      URLs.appendBaseUrl('/contacts/transactions/$txId/viewers/$viewerId/events/');
static String transactionViewerEventsLink(int txId, int viewerId) =>
      URLs.appendBaseUrl(
        '/contacts/transactions/$txId/viewers/$viewerId/events/link/',
      );
static String transactionViewersDetail(int txId, int viewerId) =>
      URLs.appendBaseUrl('/contacts/transactions/$txId/viewers/$viewerId/');
static String transactionViewersList(int txId) =>
      URLs.appendBaseUrl('/contacts/transactions/$txId/viewers/');
static String transactionViewersSetHideViewer(int txId, int viewerId) =>
      URLs.appendBaseUrl('/contacts/transactions/$txId/viewers/$viewerId/is_hide/');
static String transactionViewersSetLastContact(int txId, int viewerId) =>
      URLs.appendBaseUrl(
        '/contacts/transactions/$txId/viewers/$viewerId/set_last_contact/',
      );
static String transactionViewersSetNote(int txId, int viewerId) =>
      URLs.appendBaseUrl('/contacts/transactions/$txId/viewers/$viewerId/set_note/');
static String transactionViewersSetStatus(int txId, int viewerId) =>
      URLs.appendBaseUrl(
        '/contacts/transactions/$txId/viewers/$viewerId/set_status/',
      );
static String transactionViewersStatusTypesReorder = URLs.appendBaseUrl(
    '/contacts/viewers/statuses/reorder/',
  );
static String updateAdvertise(String offerId) =>
      URLs.appendBaseUrl('/portal/advertisements/update/$offerId/');
static final updateAgentTransactionStatus = URLs.appendBaseUrl(
    '/agent/status/update-statuses/',
  );
static String updateEstateAgentAdvertismentDraft(String offerId) =>
      URLs.appendBaseUrl('/portal/draft/advertisements/update/$offerId/');
static String updateFinanceAppExpenses(String financeAppExpensesId) =>
      URLs.appendBaseUrl('/finance/expenses/update/$financeAppExpensesId');
static String updateInvoiceData(String clientId) =>
      URLs.appendBaseUrl('/contacts/invoice-data/$clientId/');
static String updateUserContactData(String clientId) =>
      URLs.appendBaseUrl('/contacts/$clientId/update/');
static final userContactStatusUpdateColumns = URLs.appendBaseUrl(
    '/contacts/status/update-status-list/',
  );
static final userContactStatusUpdateStatusesIndexes = URLs.appendBaseUrl(
    '/contacts/status/update-column-indexes/',
  );
static String userContactsCommentDetails(String commentId) =>
      URLs.appendBaseUrl('/contacts/comments/$commentId/');
static final userContactsStatuses = URLs.appendBaseUrl('/contacts/statuses/');
}
