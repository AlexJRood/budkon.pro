import 'package:crm/data/finance/transaction_provider.dart';
import 'package:crm_agent/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/url.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';

import 'package:crm_agent/add_client_form/provider/overlay_picker_provider.dart';

const txConfigUrl = URLs.baseUrl;
const txDefaultAvatarUrl = '$txConfigUrl/media/avatars/avatar.jpg';

final selectedTransactionProvider = StateProvider<AgentTransactionModel?>(
  (ref) => null,
);

final showSelectTransactionProvider = StateProvider((ref) => false);

/// Set this before opening AddClientFormScreen from a specific transaction context.
/// TransactionListPicker will auto-select the matching transaction on mount.
final crmPreSelectTransactionIdProvider = StateProvider<int?>((ref) => null);

class TransactionListPicker extends ConsumerStatefulWidget {
  const TransactionListPicker({super.key});

  @override
  ConsumerState<TransactionListPicker> createState() =>
      _TransactionListPickerState();
}

class _TransactionListPickerState extends ConsumerState<TransactionListPicker> {
  late final TextEditingController searchController;
  late final ScrollController _scrollController;
  final FocusNode _searchFocusNode = FocusNode();

  final LayerLink _layerLink = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();
  final Object _textFieldTapRegionGroupId = Object();

  OverlayEntry? _overlayEntry;
  ProviderSubscription<String?>? _activeOverlaySubscription;

  String get _pickerId => 'transaction_picker';

  bool get _isOverlayOpen => _overlayEntry != null;

  @override
  void initState() {
    super.initState();

    searchController = TextEditingController();
    _scrollController = ScrollController();

    _searchFocusNode.addListener(_handleFocusChanged);

    _activeOverlaySubscription = ref.listenManual<String?>(
      activeOverlayPickerProvider,
      (previous, next) {
        if (next != _pickerId) {
          _hideOverlay(clearActiveProvider: false, unfocus: true);
        }
      },
    );

    final preSelectId = ref.read(crmPreSelectTransactionIdProvider);
    if (preSelectId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final txAsync = ref.read(transactionProvider);
        final tx = txAsync.value?.transactions
            .where((t) => t.id == preSelectId)
            .firstOrNull;
        if (tx != null) {
          ref.read(selectedTransactionProvider.notifier).state = tx;
        }
        ref.read(crmPreSelectTransactionIdProvider.notifier).state = null;
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleFocusChanged);
    _hideOverlay(clearActiveProvider: false, unfocus: false);
    _activeOverlaySubscription?.close();
    searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      ref.read(activeOverlayPickerProvider.notifier).state = _pickerId;
      _showOverlay();
    } else {
      if (ref.read(activeOverlayPickerProvider) == _pickerId) {
        ref.read(activeOverlayPickerProvider.notifier).state = null;
      }
      _hideOverlay(clearActiveProvider: false, unfocus: false);
    }
  }

  void _markOverlayNeedsBuild() {
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _markOverlayNeedsBuild();
      return;
    }

    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);

    if (mounted) {
      setState(() {});
    }
  }

  void _hideOverlay({
    bool clearActiveProvider = true,
    bool unfocus = true,
  }) {
    if (unfocus && _searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }

    _overlayEntry?.remove();
    _overlayEntry = null;

    if (clearActiveProvider &&
        ref.read(activeOverlayPickerProvider) == _pickerId) {
      ref.read(activeOverlayPickerProvider.notifier).state = null;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _focusSearchField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  void _clearSelectedTransaction() {
    ref.read(selectedTransactionProvider.notifier).state = null;
    searchController.clear();
    _hideOverlay();
  }

  void _editSelectedTransaction() {
    ref.read(selectedTransactionProvider.notifier).state = null;
    searchController.clear();
    _focusSearchField();
  }

  void _selectTransaction(AgentTransactionModel tx) {
    ref.read(selectedTransactionProvider.notifier).state = tx;
    searchController.clear();
    _hideOverlay();
  }

  void _clearSearch() {
    searchController.clear();

    if (mounted) {
      setState(() {});
    }
    _markOverlayNeedsBuild();
    _focusSearchField();
  }

  String _titleFor(AgentTransactionModel tx) {
    final base = tx.name.trim().isNotEmpty ? tx.name.trim() : 'Transaction'.tr;
    return '$base #${tx.id}';
  }

  String _subtitleFor(AgentTransactionModel tx) {
    final email = (tx.client.email ?? '').trim();
    final phone = (tx.client.phoneNumber ?? '').trim();

    if (email.isNotEmpty) return email;
    if (phone.isNotEmpty) return phone;
    return '#${tx.id}';
  }

  List<AgentTransactionModel> _filterTransactions(
    List<AgentTransactionModel> all,
  ) {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return all;

    return all.where((t) {
      final title = t.name.toLowerCase();
      final idValue = t.id.toString();
      final email = (t.client.email ?? '').toLowerCase();
      final phone = (t.client.phoneNumber ?? '').toLowerCase();

      return title.contains(query) ||
          idValue.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (overlayContext) {
        final renderBox =
            _anchorKey.currentContext?.findRenderObject() as RenderBox?;
        final anchorSize = renderBox?.size ?? const Size(320, 56);

        return Positioned.fill(
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 8),
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: anchorSize.width,
                    child: Consumer(
                      builder: (context, ref, _) {
                        return TextFieldTapRegion(
                          groupId: _textFieldTapRegionGroupId,
                          child: _buildOverlayPanel(context, ref),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final selectedTx = ref.watch(selectedTransactionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            key: _anchorKey,
            margin: const EdgeInsets.all(4),
            child: selectedTx != null
                ? _buildSelectedTransactionCard(context, ref, selectedTx)
                : TextFieldTapRegion(
                    groupId: _textFieldTapRegionGroupId,
                    child: _buildSearchAnchor(context, ref, theme),
                  ),
          ),
        ),
        if (selectedTx == null && !_isOverlayOpen) ...[
          const SizedBox(height: 6),
          _buildQuickTransactionsSection(context, ref),
        ],
      ],
    );
  }

  Widget _buildSelectedTransactionCard(
    BuildContext context,
    WidgetRef ref,
    AgentTransactionModel tx,
  ) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(125),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              tx.client.avatar ?? txDefaultAvatarUrl,
              width: 38,
              height: 38,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleFor(tx),
                  style: AppTextStyles.interRegular14.copyWith(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitleFor(tx),
                  style: AppTextStyles.interRegular12.copyWith(
                    color: theme.textColor.withOpacity(0.62),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildSmallIconButton(
            ref: ref,
            icon: Icons.search_rounded,
            onTap: _editSelectedTransaction,
          ),
          const SizedBox(width: 6),
          _buildSmallIconButton(
            ref: ref,
            icon: Icons.close_rounded,
            onTap: _clearSelectedTransaction,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAnchor(
    BuildContext context,
    WidgetRef ref,
    ThemeColors theme,
  ) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(125),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: TextField(
            controller: searchController,
            focusNode: _searchFocusNode,
            groupId: _textFieldTapRegionGroupId,
            onChanged: (_) {
              if (mounted) {
                setState(() {});
              }
              _markOverlayNeedsBuild();
            },
            onTap: () {
              ref.read(activeOverlayPickerProvider.notifier).state = _pickerId;
            },
            onTapOutside: (_) {
              _searchFocusNode.unfocus();
            },
            decoration: InputDecoration(
              hintText: 'search_or_choose_transaction'.tr,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: theme.textColor.withOpacity(0.72),
              ),
              suffixIcon: searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: _clearSearch,
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.textColor.withOpacity(0.72),
                      ),
                    ),
              hintStyle: AppTextStyles.interRegular14.copyWith(
                color: theme.textColor.withOpacity(0.55),
              ),
              filled: true,
              fillColor: theme.textFieldColor.withOpacity(0.45),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.bordercolor.withOpacity(0.18),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.transparent
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.themeColor.withOpacity(0.65),
                ),
              ),
            ),
            style: AppTextStyles.interRegular14.copyWith(
              color: theme.textColor,
            ),
            cursorColor: theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayPanel(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 400,
        minHeight: 120,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.bordercolor.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transactions'.tr,
                  style: AppTextStyles.interRegular12.copyWith(
                    color: theme.textColor.withOpacity(0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildSmallIconButton(
                ref: ref,
                icon: Icons.close_rounded,
                onTap: () {
                  _searchFocusNode.unfocus();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildOverlayQuickTransactionsRow(context, ref),
          const SizedBox(height: 10),
          Expanded(
            child: _transactionsList(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton({
    required WidgetRef ref,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.textFieldColor.withOpacity(0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.bordercolor.withOpacity(0.18),
          ),
        ),
        child: Icon(
          icon,
          color: theme.textColor.withOpacity(0.85),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildQuickTransactionsSection(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final txStateAsync = ref.watch(transactionProvider);

    return txStateAsync.when(
      data: (data) {
        final transactions = data.transactions;
        if (transactions.isEmpty) return const SizedBox.shrink();

        final quickItems = transactions.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'quick_select'.tr,
                style: AppTextStyles.interRegular12.copyWith(
                  color: theme.textColor.withOpacity(0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: quickItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final tx = quickItems[index];
                  return _buildQuickTransactionTile(context, ref, tx);
                },
              ),
            ),
          ],
        );
      },
      loading: () => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, __) => _buildQuickTransactionShimmer(context, ref),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOverlayQuickTransactionsRow(
    BuildContext context,
    WidgetRef ref,
  ) {
    final theme = ref.watch(themeColorsProvider);
    final txStateAsync = ref.watch(transactionProvider);

    return txStateAsync.when(
      data: (data) {
        final items = _filterTransactions(data.transactions).take(6).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final tx = items[index];
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _selectTransaction(tx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: CustomBackgroundGradients.crmClientAppbarGradient(
                      context,
                      ref,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          tx.client.avatar ?? txDefaultAvatarUrl,
                          width: 22,
                          height: 22,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          _titleFor(tx),
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.interRegular12.copyWith(
                            color: theme.mobileTextcolor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickTransactionTile(
    BuildContext context,
    WidgetRef ref,
    AgentTransactionModel tx,
  ) {
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _selectTransaction(tx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: CustomBackgroundGradients.crmClientAppbarGradient(
            context,
            ref,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                tx.client.avatar ?? txDefaultAvatarUrl,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 145),
              child: Text(
                _titleFor(tx),
                style: AppTextStyles.interRegular12.copyWith(
                  color: theme.mobileTextcolor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTransactionShimmer(BuildContext context, WidgetRef ref) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: CustomBackgroundGradients.crmClientAppbarGradient(
          context,
          ref,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _transactionsList(BuildContext context, WidgetRef ref) {
    final txStateAsync = ref.watch(transactionProvider);

    return txStateAsync.when(
      data: (data) {
        final items = _filterTransactions(data.transactions);

        if (items.isEmpty) {
          return _buildNoTransactionsMessage(context, ref);
        }

        return _buildTransactionList(context, ref, items);
      },
      loading: () => _buildLoadingState(context, ref),
      error: (_, __) => _buildErrorState(context, ref),
    );
  }

  Widget _buildNoTransactionsMessage(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: CustomBackgroundGradients.adGradient1(context, ref),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'no_transactions_available'.tr,
          style: AppTextStyles.interRegular12.copyWith(
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    WidgetRef ref,
    List<AgentTransactionModel> transactions,
  ) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _buildTransactionCard(context, ref, tx);
      },
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    WidgetRef ref,
    AgentTransactionModel tx,
  ) {
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _selectTransaction(tx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: CustomBackgroundGradients.crmadgradient(context, ref),
          border: Border.all(
            color: theme.bordercolor.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                tx.client.avatar ?? txDefaultAvatarUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleFor(tx),
                    style: AppTextStyles.interRegular14.copyWith(
                      color: theme.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitleFor(tx),
                    style: AppTextStyles.interRegular12.copyWith(
                      color: theme.textColor.withOpacity(0.62),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: theme.textColor.withOpacity(0.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, WidgetRef ref) {
    return _buildShimmerLoading(context, ref);
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return _buildShimmerLoading(context, ref, showErrorIcon: true);
  }

  Widget _buildShimmerLoading(
    BuildContext context,
    WidgetRef ref, {
    bool showErrorIcon = false,
  }) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) {
        return Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: CustomBackgroundGradients.crmadgradient(context, ref),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Stack(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  if (showErrorIcon)
                    const Positioned(
                      left: 12,
                      top: 12,
                      child: Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    margin: const EdgeInsets.only(right: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}