import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/contact_panel/navigation/enum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientDashboardScopeProvider = Provider<ClientDashboardScope>((ref) {
  throw UnimplementedError(
    'clientDashboardScopeProvider must be overridden inside ClientDashboardSection.',
  );
});

class ClientDashboardScope {
  final UserContactModel clientViewPop;
  final String clientId;
  final ContactType contactType;
  final String panelMode;

  const ClientDashboardScope({
    required this.clientViewPop,
    required this.clientId,
    this.contactType = ContactType.client,
    this.panelMode = 'client',
  });

  bool get isClient => contactType == ContactType.client;
  bool get isCrmUser => contactType == ContactType.crmUser;
  bool get isLead => contactType == ContactType.lead;
  bool get isOwner => contactType == ContactType.owner;
  bool get isCompany => contactType == ContactType.company;
  bool get isAssociationMember =>
      contactType == ContactType.associationMember;
}