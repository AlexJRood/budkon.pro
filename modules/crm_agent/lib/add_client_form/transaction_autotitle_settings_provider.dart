import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which tab/transaction kind we are configuring
enum TransactionKind { sell, buy }

/// Which address chunk should be used in auto title
enum AddressPart {
  none,
  city,
  street,
  cityStreet,
  district,
  full,
}

String addressPartLabel(AddressPart p) {
  switch (p) {
    case AddressPart.none:
      return 'None';
    case AddressPart.city:
      return 'City';
    case AddressPart.street:
      return 'Street';
    case AddressPart.cityStreet:
      return 'City + Street';
    case AddressPart.district:
      return 'District';
    case AddressPart.full:
      return 'Full';
  }
}

enum NameOrder {
  firstLast,
  lastFirst,
}

String nameOrderLabel(NameOrder o) {
  switch (o) {
    case NameOrder.firstLast:
      return 'Name Lastname';
    case NameOrder.lastFirst:
      return 'Lastname Name';
  }
}

enum CommissionDefaultType {
  percent,
  amount,
}

String commissionDefaultLabel(CommissionDefaultType t) {
  switch (t) {
    case CommissionDefaultType.percent:
      return 'Percent';
    case CommissionDefaultType.amount:
      return 'Static amount';
  }
}

@immutable
class AutoTitleRule {
  final bool enabled;

  /// Optional prefix e.g. "SELL" / "BUY"
  final bool includePrefix;
  final String prefixText;

  /// Name formatting
  final NameOrder nameOrder;

  /// Address formatting
  final bool includeAddress;
  final AddressPart addressPart;

  /// Separators
  final String nameAddressSeparator; // e.g. " — "
  final String partsSeparator; // e.g. " "

  const AutoTitleRule({
    required this.enabled,
    required this.includePrefix,
    required this.prefixText,
    required this.nameOrder,
    required this.includeAddress,
    required this.addressPart,
    required this.nameAddressSeparator,
    required this.partsSeparator,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'includePrefix': includePrefix,
        'prefixText': prefixText,
        'nameOrder': nameOrder.index,
        'includeAddress': includeAddress,
        'addressPart': addressPart.index,
        'nameAddressSeparator': nameAddressSeparator,
        'partsSeparator': partsSeparator,
      };

  factory AutoTitleRule.fromJson(Map<String, dynamic> j) => AutoTitleRule(
        enabled: j['enabled'] as bool? ?? true,
        includePrefix: j['includePrefix'] as bool? ?? false,
        prefixText: j['prefixText'] as String? ?? '',
        nameOrder: NameOrder.values[j['nameOrder'] as int? ?? 0],
        includeAddress: j['includeAddress'] as bool? ?? true,
        addressPart: AddressPart.values[j['addressPart'] as int? ?? 1],
        nameAddressSeparator: j['nameAddressSeparator'] as String? ?? ' — ',
        partsSeparator: j['partsSeparator'] as String? ?? ' ',
      );

  AutoTitleRule copyWith({
    bool? enabled,
    bool? includePrefix,
    String? prefixText,
    NameOrder? nameOrder,
    bool? includeAddress,
    AddressPart? addressPart,
    String? nameAddressSeparator,
    String? partsSeparator,
  }) {
    return AutoTitleRule(
      enabled: enabled ?? this.enabled,
      includePrefix: includePrefix ?? this.includePrefix,
      prefixText: prefixText ?? this.prefixText,
      nameOrder: nameOrder ?? this.nameOrder,
      includeAddress: includeAddress ?? this.includeAddress,
      addressPart: addressPart ?? this.addressPart,
      nameAddressSeparator: nameAddressSeparator ?? this.nameAddressSeparator,
      partsSeparator: partsSeparator ?? this.partsSeparator,
    );
  }

  static const AutoTitleRule defaultSell = AutoTitleRule(
    enabled: true,
    includePrefix: false,
    prefixText: 'SELL',
    nameOrder: NameOrder.firstLast,
    includeAddress: true,
    addressPart: AddressPart.city,
    nameAddressSeparator: ' — ',
    partsSeparator: ' ',
  );

  static const AutoTitleRule defaultBuy = AutoTitleRule(
    enabled: true,
    includePrefix: false,
    prefixText: 'BUY',
    nameOrder: NameOrder.firstLast,
    includeAddress: true,
    addressPart: AddressPart.city,
    nameAddressSeparator: ' — ',
    partsSeparator: ' ',
  );
}

@immutable
class TransactionDefaults {
  final String defaultCurrency; // e.g. "PLN"
  final String defaultPaymentMethod; // e.g. "Transfer"
  final CommissionDefaultType defaultCommissionType;
  final bool? isCommissionNetValue;

  const TransactionDefaults({
    required this.defaultCurrency,
    required this.defaultPaymentMethod,
    required this.defaultCommissionType,
    required this.isCommissionNetValue,
  });

  Map<String, dynamic> toJson() => {
        'defaultCurrency': defaultCurrency,
        'defaultPaymentMethod': defaultPaymentMethod,
        'defaultCommissionType': defaultCommissionType.index,
        'isCommissionNetValue': isCommissionNetValue,
      };

  factory TransactionDefaults.fromJson(Map<String, dynamic> j) =>
      TransactionDefaults(
        defaultCurrency: j['defaultCurrency'] as String? ?? 'PLN',
        defaultPaymentMethod: j['defaultPaymentMethod'] as String? ?? 'Transfer',
        defaultCommissionType: CommissionDefaultType
            .values[j['defaultCommissionType'] as int? ?? 0],
        isCommissionNetValue: j['isCommissionNetValue'] as bool?,
      );

  TransactionDefaults copyWith({
    String? defaultCurrency,
    String? defaultPaymentMethod,
    CommissionDefaultType? defaultCommissionType,
    bool? isCommissionNetValue,
  }) {
    return TransactionDefaults(
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      defaultCommissionType: defaultCommissionType ?? this.defaultCommissionType,
          isCommissionNetValue: isCommissionNetValue ?? this.isCommissionNetValue,
    );
  }

  static const TransactionDefaults defaultSell = TransactionDefaults(
    defaultCurrency: 'PLN',
    defaultPaymentMethod: 'Transfer',
    defaultCommissionType: CommissionDefaultType.percent,
    isCommissionNetValue: true,
  );

  static const TransactionDefaults defaultBuy = TransactionDefaults(
    defaultCurrency: 'PLN',
    defaultPaymentMethod: 'Transfer',
    defaultCommissionType: CommissionDefaultType.percent,
    isCommissionNetValue: true,
  );
}

@immutable
class TransactionUiSettingsState {
  final AutoTitleRule sellAutoTitle;
  final AutoTitleRule buyAutoTitle;

  final TransactionDefaults sellDefaults;
  final TransactionDefaults buyDefaults;

  const TransactionUiSettingsState({
    required this.sellAutoTitle,
    required this.buyAutoTitle,
    required this.sellDefaults,
    required this.buyDefaults,
  });

  Map<String, dynamic> toJson() => {
        'sellAutoTitle': sellAutoTitle.toJson(),
        'buyAutoTitle': buyAutoTitle.toJson(),
        'sellDefaults': sellDefaults.toJson(),
        'buyDefaults': buyDefaults.toJson(),
      };

  factory TransactionUiSettingsState.fromJson(Map<String, dynamic> j) =>
      TransactionUiSettingsState(
        sellAutoTitle: AutoTitleRule.fromJson(
            j['sellAutoTitle'] as Map<String, dynamic>? ?? {}),
        buyAutoTitle: AutoTitleRule.fromJson(
            j['buyAutoTitle'] as Map<String, dynamic>? ?? {}),
        sellDefaults: TransactionDefaults.fromJson(
            j['sellDefaults'] as Map<String, dynamic>? ?? {}),
        buyDefaults: TransactionDefaults.fromJson(
            j['buyDefaults'] as Map<String, dynamic>? ?? {}),
      );

  TransactionUiSettingsState copyWith({
    AutoTitleRule? sellAutoTitle,
    AutoTitleRule? buyAutoTitle,
    TransactionDefaults? sellDefaults,
    TransactionDefaults? buyDefaults,
  }) {
    return TransactionUiSettingsState(
      sellAutoTitle: sellAutoTitle ?? this.sellAutoTitle,
      buyAutoTitle: buyAutoTitle ?? this.buyAutoTitle,
      sellDefaults: sellDefaults ?? this.sellDefaults,
      buyDefaults: buyDefaults ?? this.buyDefaults,
    );
  }

  static const initial = TransactionUiSettingsState(
    sellAutoTitle: AutoTitleRule.defaultSell,
    buyAutoTitle: AutoTitleRule.defaultBuy,
    sellDefaults: TransactionDefaults.defaultSell,
    buyDefaults: TransactionDefaults.defaultBuy,
  );
}

const _kTransactionSettingsKey = 'transaction_ui_settings_v1';

class TransactionUiSettingsNotifier
    extends StateNotifier<TransactionUiSettingsState> {
  TransactionUiSettingsNotifier() : super(TransactionUiSettingsState.initial) {
    unawaited(_load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTransactionSettingsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && mounted) {
        state = TransactionUiSettingsState.fromJson(decoded);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTransactionSettingsKey, jsonEncode(state.toJson()));
  }

  AutoTitleRule ruleFor(TransactionKind kind) =>
      kind == TransactionKind.sell ? state.sellAutoTitle : state.buyAutoTitle;

  TransactionDefaults defaultsFor(TransactionKind kind) =>
      kind == TransactionKind.sell ? state.sellDefaults : state.buyDefaults;

  void updateRule(TransactionKind kind, AutoTitleRule rule) {
    state = kind == TransactionKind.sell
        ? state.copyWith(sellAutoTitle: rule)
        : state.copyWith(buyAutoTitle: rule);
    unawaited(_save());
  }

  void updateDefaults(TransactionKind kind, TransactionDefaults defaults) {
    state = kind == TransactionKind.sell
        ? state.copyWith(sellDefaults: defaults)
        : state.copyWith(buyDefaults: defaults);
    unawaited(_save());
  }
}

final transactionUiSettingsProvider = StateNotifierProvider<
    TransactionUiSettingsNotifier, TransactionUiSettingsState>(
  (ref) => TransactionUiSettingsNotifier(),
);

/// Local-only flag: user manually edited title (so AutoTitle should stop)
final transactionTitleManuallyEditedProvider =
    StateProvider<bool>((ref) => false);
