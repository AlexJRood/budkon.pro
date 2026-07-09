import 'package:core/platform/url.dart';
import 'package:get/get_utils/get_utils.dart';

const configUrl = URLs.baseUrl;
const defaultAvatarUrl = '$configUrl/media/avatars/avatar.jpg';

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class ClientTransactionPreviewModel {
  final int id;
  final String title;
  final String? transactionName;
  final String? name;
  final String? transactionType;
  final String? status;
  final double? amount;
  final String? currency;
  final DateTime? dateCreate;
  final DateTime? dateUpdate;
  final bool isComplete;
  final bool? isTransactionSuccess;
  final bool isArchive;
  final String? serviceTypeLabel;

  const ClientTransactionPreviewModel({
    required this.id,
    required this.title,
    this.transactionName,
    this.name,
    this.transactionType,
    this.status,
    this.amount,
    this.currency,
    this.dateCreate,
    this.dateUpdate,
    required this.isComplete,
    this.isTransactionSuccess,
    required this.isArchive,
    this.serviceTypeLabel,
  });

  factory ClientTransactionPreviewModel.fromJson(Map<String, dynamic> json) {
    return ClientTransactionPreviewModel(
      id: json['id'] ?? 0,
      title: (json['title'] ?? '').toString(),
      transactionName: json['transaction_name']?.toString(),
      name: json['name']?.toString(),
      transactionType: json['transaction_type']?.toString(),
      status: json['status']?.toString(),
      amount: _toDouble(json['amount']),
      currency: json['currency']?.toString(),
      dateCreate: json['date_create'] != null
          ? DateTime.tryParse(json['date_create'].toString())
          : null,
      dateUpdate: json['date_update'] != null
          ? DateTime.tryParse(json['date_update'].toString())
          : null,
      isComplete: json['isComplete'] == true,
      isTransactionSuccess: json['isTransactionSuccess'] as bool?,
      isArchive: json['is_archive'] == true,
      serviceTypeLabel: json['service_type_label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'transaction_name': transactionName,
      'name': name,
      'transaction_type': transactionType,
      'status': status,
      'amount': amount,
      'currency': currency,
      'date_create': dateCreate?.toIso8601String(),
      'date_update': dateUpdate?.toIso8601String(),
      'isComplete': isComplete,
      'isTransactionSuccess': isTransactionSuccess,
      'is_archive': isArchive,
      'service_type_label': serviceTypeLabel,
    };
  }
}

class ClientTransactionsPreviewModel {
  final int count;
  final int limit;
  final int offset;
  final bool hasMore;
  final List<ClientTransactionPreviewModel> results;

  const ClientTransactionsPreviewModel({
    required this.count,
    required this.limit,
    required this.offset,
    required this.hasMore,
    required this.results,
  });

  factory ClientTransactionsPreviewModel.fromJson(Map<String, dynamic> json) {
    return ClientTransactionsPreviewModel(
      count: json['count'] ?? 0,
      limit: json['limit'] ?? 0,
      offset: json['offset'] ?? 0,
      hasMore: json['has_more'] == true,
      results: ((json['results'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ClientTransactionPreviewModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'limit': limit,
      'offset': offset,
      'has_more': hasMore,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}

class InvoiceDataModel {
  final int id;
  final String? notes;
  final String? legalName;
  final String? nip;
  final String? regon;
  final String? website;
  final String? contactPerson;
  final String? bankAccount;
  final String? country;
  final String? city;
  final String? street;
  final String? postalCode;
  final String? registeredCountry;
  final String? registeredCity;
  final String? registeredStreet;
  final String? registeredPostalCode;
  final DateTime? dateCreated;
  final DateTime? lastUpdated;
  final bool? isVerified;
  final int? user;
  final int? client;

  const InvoiceDataModel({
    required this.id,
    this.notes,
    this.legalName,
    this.nip,
    this.regon,
    this.website,
    this.contactPerson,
    this.bankAccount,
    this.country,
    this.city,
    this.street,
    this.postalCode,
    this.registeredCountry,
    this.registeredCity,
    this.registeredStreet,
    this.registeredPostalCode,
    this.dateCreated,
    this.lastUpdated,
    this.isVerified,
    this.user,
    this.client,
  });

  factory InvoiceDataModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDataModel(
      id: json['id'] ?? 0,
      notes: json['notes'],
      legalName: json['legal_name'],
      nip: json['nip'],
      regon: json['regon'],
      website: json['website'],
      contactPerson: json['contact_person'],
      bankAccount: json['bank_account'],
      country: json['country'],
      city: json['city'],
      street: json['street'],
      postalCode: json['postal_code'],
      registeredCountry: json['registered_country'],
      registeredCity: json['registered_city'],
      registeredStreet: json['registered_street'],
      registeredPostalCode: json['registered_postal_code'],
      dateCreated: json['date_created'] != null
          ? DateTime.tryParse(json['date_created'])
          : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'])
          : null,
      isVerified: json['is_verified'],
      user: json['user'],
      client: json['client'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notes': notes,
      'legal_name': legalName,
      'nip': nip,
      'regon': regon,
      'website': website,
      'contact_person': contactPerson,
      'bank_account': bankAccount,
      'country': country,
      'city': city,
      'street': street,
      'postal_code': postalCode,
      'registered_country': registeredCountry,
      'registered_city': registeredCity,
      'registered_street': registeredStreet,
      'registered_postal_code': registeredPostalCode,
      'date_created': dateCreated?.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
      'is_verified': isVerified,
      'user': user,
      'client': client,
    };
  }
}

class UserContactModel {
  final int id;
  final List<int> favoriteBoards;
  final InvoiceDataModel? invoiceData;
  final dynamic secureData;
  final bool? isStar;
  final String? avatar;
  final String name;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? gender;
  final DateTime? birthDate;
  final String? nationality;
  final String? description;
  final String? note;
  final DateTime? dateCreated;
  final DateTime? lastUpdated;
  final int? contactType;
  final String? contactStatus;
  final String? serviceType;
  final int? createdBy;
  final String? responsiblePerson;
  final ClientTransactionsPreviewModel? transactionsPreview;

  // NEW
  final DateTime? lastViewedAtMe;
  final int? viewsCountMe;

  const UserContactModel({
    required this.id,
    this.favoriteBoards = const [],
    this.invoiceData,
    this.secureData,
    this.isStar,
    this.avatar,
    required this.name,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.gender,
    this.birthDate,
    this.nationality,
    this.description,
    this.note,
    this.dateCreated,
    this.lastUpdated,
    this.contactType,
    this.contactStatus,
    this.serviceType,
    this.createdBy,
    this.responsiblePerson,
    this.transactionsPreview,
    this.lastViewedAtMe,
    this.viewsCountMe,
  });

  factory UserContactModel.fromJson(Map<String, dynamic> json) {
    return UserContactModel(
      id: json['id'] ?? 0,
      favoriteBoards:
          (json['favorite_boards'] as List?)?.map((e) => e as int).toList() ??
              [],
      invoiceData: json['invoice_data'] != null
          ? InvoiceDataModel.fromJson(json['invoice_data'])
          : null,
      secureData: json['secure_data'],
      isStar: json['star'] ?? false,
      avatar: json['avatar'] ?? defaultAvatarUrl,
      name: json['name'] ?? 'Unknown'.tr,
      lastName: json['last_name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      gender: json['gender'],
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'])
          : null,
      nationality: json['nationality'],
      description: json['description'],
      note: json['note'],
      dateCreated: json['date_created'] != null
          ? DateTime.tryParse(json['date_created'])
          : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'])
          : null,
      contactType: json['contact_type'],
      contactStatus: json['contact_status']?.toString(),
      serviceType: json['service_type'],
      createdBy: json['created_by'],
      responsiblePerson: json['responsible_person']?.toString(),
      transactionsPreview: json['transactions_preview'] != null
          ? ClientTransactionsPreviewModel.fromJson(
              Map<String, dynamic>.from(json['transactions_preview']),
            )
          : null,
      lastViewedAtMe: json['last_viewed_at_me'] != null
          ? DateTime.tryParse(json['last_viewed_at_me'].toString())
          : null,
      viewsCountMe: json['views_count_me'] is int
          ? json['views_count_me'] as int
          : int.tryParse('${json['views_count_me'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'favorite_boards': favoriteBoards,
      'invoice_data': invoiceData?.toJson(),
      'secure_data': secureData,
      'star': isStar,
      'avatar': avatar,
      'name': name,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String(),
      'nationality': nationality,
      'description': description,
      'note': note,
      'date_created': dateCreated?.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
      'contact_type': contactType,
      'contact_status': contactStatus,
      'service_type': serviceType,
      'created_by': createdBy,
      'responsible_person': responsiblePerson,
      'transactions_preview': transactionsPreview?.toJson(),
      'last_viewed_at_me': lastViewedAtMe?.toIso8601String(),
      'views_count_me': viewsCountMe,
    };
  }

  /// Slim payload for POST /contacts/create/ — sends only writable fields,
  /// FK relations as integer IDs. Avoids sending id:0, read-only computed
  /// fields, and nested objects the create endpoint doesn't accept.
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (lastName != null && lastName!.isNotEmpty) 'last_name': lastName,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (phoneNumber != null && phoneNumber!.isNotEmpty) 'phone_number': phoneNumber,
      if (contactType != null) 'contact_type': contactType,
      if (contactStatus != null) 'contact_status': int.tryParse(contactStatus!) ?? contactStatus,
      if (serviceType != null) 'service_type': int.tryParse(serviceType!) ?? serviceType,
      if (gender != null) 'gender': gender,
      if (description != null) 'description': description,
      if (note != null) 'note': note,
    };
  }

  UserContactModel copyWith({
    int? id,
    List<int>? favoriteBoards,
    InvoiceDataModel? invoiceData,
    dynamic secureData,
    bool? isStar,
    String? avatar,
    String? name,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? gender,
    DateTime? birthDate,
    String? nationality,
    String? description,
    String? note,
    DateTime? dateCreated,
    DateTime? lastUpdated,
    int? contactType,
    String? contactStatus,
    String? serviceType,
    int? createdBy,
    String? responsiblePerson,
    ClientTransactionsPreviewModel? transactionsPreview,
    DateTime? lastViewedAtMe,
    int? viewsCountMe,
  }) {
    return UserContactModel(
      id: id ?? this.id,
      favoriteBoards: favoriteBoards ?? this.favoriteBoards,
      invoiceData: invoiceData ?? this.invoiceData,
      secureData: secureData ?? this.secureData,
      isStar: isStar ?? this.isStar,
      avatar: avatar ?? this.avatar,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      nationality: nationality ?? this.nationality,
      description: description ?? this.description,
      note: note ?? this.note,
      dateCreated: dateCreated ?? this.dateCreated,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      contactType: contactType ?? this.contactType,
      contactStatus: contactStatus ?? this.contactStatus,
      serviceType: serviceType ?? this.serviceType,
      createdBy: createdBy ?? this.createdBy,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      transactionsPreview: transactionsPreview ?? this.transactionsPreview,
      lastViewedAtMe: lastViewedAtMe ?? this.lastViewedAtMe,
      viewsCountMe: viewsCountMe ?? this.viewsCountMe,
    );
  }
}