export 'package:crm/data/clients/client_selection_provider.dart' show selectedClientProvider;
import 'package:crm/data/clients/client_selection_provider.dart';
import 'dart:async';

import 'package:crm/data/clients/client_provider.dart';
import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';
import 'package:crm_agent/add_invoice_form/provider/form_provider.dart';
import 'package:crm_agent/add_client_form/provider/overlay_picker_provider.dart';
import 'package:crm_agent/models/clients_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/url.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';


const configUrl = URLs.baseUrl;
const defaultAvatarUrl = '$configUrl/media/avatars/avatar.jpg';


/// Przechowuje imię nowo tworzonego klienta (mini-create flow).
/// null = brak oczekującego klienta.
final pendingNewClientNameProvider = StateProvider<String?>((ref) => null);

/// Ostatnio wybrani klienci (max 6 ID, najnowszy na początku).
final recentClientIdsProvider = StateProvider<List<int>>((ref) => []);

class ClientListAddFormCrm extends ConsumerStatefulWidget {
  final bool isAddInvoice;
  final int? initialClientId;

  const ClientListAddFormCrm({
    super.key,
    this.isAddInvoice = false,
    this.initialClientId,
  });

  @override
  ConsumerState<ClientListAddFormCrm> createState() =>
      _ClientListAddFormCrmState();
}

class _ClientListAddFormCrmState extends ConsumerState<ClientListAddFormCrm> {
  late final TextEditingController searchController;
  late final ScrollController _scrollController;
  final FocusNode _searchFocusNode = FocusNode();

  final LayerLink _layerLink = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();
  final Object _textFieldTapRegionGroupId = Object();

  OverlayEntry? _overlayEntry;
  ProviderSubscription<String?>? _activeOverlaySubscription;

  Timer? _searchDebounce;
  bool _prefillDone = false;

  String get _pickerId => 'client_picker';

  bool get _isOverlayOpen => _overlayEntry != null;

  @override
  void initState() {
    super.initState();

    searchController = TextEditingController();
    _scrollController = ScrollController();

    _searchFocusNode.addListener(_handleFocusChanged);

    ref.listenManual<AsyncValue<List<UserContactModel>>>(
      clientProvider,
      (prev, next) {
        _tryPrefillFromClients(next);
        _markOverlayNeedsBuild();
      },
    );

    _activeOverlaySubscription = ref.listenManual<String?>(
      activeOverlayPickerProvider,
      (previous, next) {
        if (next != _pickerId) {
          _hideOverlay(clearActiveProvider: false, unfocus: true);
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(clientProvider);
      _tryPrefillFromClients(current);
      // ② Autofocus: otwórz overlay natychmiast gdy nie ma pre-fill
      if (widget.initialClientId == null && mounted) {
        _focusSearchField();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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

  void _resetClientSearch() {
    ref.read(clientProvider.notifier).fetchClients(searchQuery: '');
    _markOverlayNeedsBuild();
  }

  void _clearSelectedClient() {
    ref.read(selectedClientProvider.notifier).state = null;
    searchController.clear();
    _resetClientSearch();
    _hideOverlay();
  }

  void _editSelectedClient() {
    ref.read(selectedClientProvider.notifier).state = null;
    searchController.clear();
    _resetClientSearch();
    _focusSearchField();
  }

  void _setSelectedClient(UserContactModel client) {
    if (widget.isAddInvoice) {
      ref.read(revenueFormProvider.notifier).setClient(client.id);
      ref.read(selectedClientProvider.notifier).state = client;
    } else {
      ref.read(selectedClientProvider.notifier).state = client;
      ref.read(addClientFormProvider.notifier).setSelectedClientId(client.id);
    }

    // ③ Aktualizuj kolejność ostatnio używanych
    final recent = ref.read(recentClientIdsProvider);
    final updated = [client.id, ...recent.where((id) => id != client.id)]
        .take(6)
        .toList();
    ref.read(recentClientIdsProvider.notifier).state = updated;

    // Wyczyść oczekującego nowego klienta jeśli był
    ref.read(pendingNewClientNameProvider.notifier).state = null;

    searchController.clear();
    _resetClientSearch();
    _hideOverlay();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    if (mounted) {
      setState(() {});
    }
    _markOverlayNeedsBuild();

    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(clientProvider.notifier).fetchClients(
            searchQuery: value.trim(),
          );
      _markOverlayNeedsBuild();
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    searchController.clear();
    _resetClientSearch();

    if (mounted) {
      setState(() {});
    }

    _focusSearchField();
  }

  UserContactModel? _findClientById(List<UserContactModel> clients, int id) {
    for (final client in clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  void _tryPrefillFromClients(AsyncValue<List<UserContactModel>> value) {
    if (_prefillDone) return;

    final wantedId = widget.initialClientId;
    if (wantedId == null) return;

    value.whenOrNull(
      data: (clients) {
        final match = _findClientById(clients, wantedId);
        if (match != null) {
          _prefillDone = true;
          _setSelectedClient(match);
        }
      },
    );
  }

  String _clientFullName(UserContactModel client) {
    final lastName = (client.lastName ?? '').trim();
    if (lastName.isEmpty) return client.name;
    return '${client.name} $lastName';
  }

  // ④ Mini-create: otwiera bottom sheet z 2 polami zamiast pełnego formularza
  void _openAddClientFlow() {
    _hideOverlay();
    _showMiniCreateSheet();
  }

  void _showMiniCreateSheet() {
    final theme = ref.read(themeColorsProvider);
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.textFieldColor.withOpacity(0.45),
      hintStyle: AppTextStyles.interRegular14.copyWith(
        color: theme.textColor.withOpacity(0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.themeColor.withOpacity(0.65)),
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.dashboardContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add_rounded, color: theme.themeColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'new_client'.tr,
                    style: AppTextStyles.interRegular14.copyWith(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: theme.textColor.withOpacity(0.7)),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.interRegular14.copyWith(color: theme.textColor),
                decoration: inputDecoration.copyWith(hintText: 'Name'.tr),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                style: AppTextStyles.interRegular14.copyWith(color: theme.textColor),
                onSubmitted: (_) => _confirmMiniCreate(nameCtrl, phoneCtrl, sheetCtx),
                decoration: inputDecoration.copyWith(hintText: 'Phone'.tr),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _confirmMiniCreate(nameCtrl, phoneCtrl, sheetCtx),
                  child: Text(
                    'confirm'.tr,
                    style: AppTextStyles.interRegular14.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  void _confirmMiniCreate(
    TextEditingController nameCtrl,
    TextEditingController phoneCtrl,
    BuildContext sheetCtx,
  ) {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    final phone = phoneCtrl.text.trim();
    final formNotifier = ref.read(addClientFormProvider.notifier);
    final formState = ref.read(addClientFormProvider);

    formNotifier.updateTextField(formState.clientNameController, name);
    if (phone.isNotEmpty) {
      formNotifier.updateTextField(formState.clientPhoneNumberController, phone);
    }

    ref.read(pendingNewClientNameProvider.notifier).state = name;
    Navigator.of(sheetCtx).pop();
  }

  void _clearPendingClient() {
    ref.read(pendingNewClientNameProvider.notifier).state = null;
    final formState = ref.read(addClientFormProvider);
    formState.clientNameController.clear();
    formState.clientPhoneNumberController.clear();
  }

  // ③ Sortuj quick clients: ostatnio używane pierwsze
  List<UserContactModel> _sortedQuickClients(List<UserContactModel> clients) {
    final recentIds = ref.read(recentClientIdsProvider);
    if (recentIds.isEmpty) return clients.take(6).toList();

    final recentClients = recentIds
        .map((id) {
          for (final c in clients) {
            if (c.id == id) return c;
          }
          return null;
        })
        .whereType<UserContactModel>()
        .toList();
    final rest = clients.where((c) => !recentIds.contains(c.id)).toList();
    return [...recentClients, ...rest].take(6).toList();
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
    final selectedClient = ref.watch(selectedClientProvider);
    final pendingName = ref.watch(pendingNewClientNameProvider);
    final theme = ref.watch(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            key: _anchorKey,
            margin: const EdgeInsets.all(4),
            child: selectedClient != null
                ? _buildSelectedClientCard(context, ref, selectedClient)
                : pendingName != null
                    ? _buildPendingClientCard(context, ref, pendingName)
                    : TextFieldTapRegion(
                        groupId: _textFieldTapRegionGroupId,
                        child: _buildSearchAnchor(context, ref, theme),
                      ),
          ),
        ),
        if (selectedClient == null && pendingName == null && !_isOverlayOpen) ...[
          const SizedBox(height: 6),
          _buildQuickClientsSection(context, ref),
        ],
      ],
    );
  }

  Widget _buildSelectedClientCard(
    BuildContext context,
    WidgetRef ref,
    UserContactModel selectedClient,
  ) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      height: 58,
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
          CircleAvatar(
            backgroundImage: NetworkImage(
              selectedClient.avatar ?? defaultAvatarUrl,
            ),
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _clientFullName(selectedClient),
              style: AppTextStyles.interRegular14.copyWith(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildSmallIconButton(
            ref: ref,
            icon: Icons.search_rounded,
            onTap: _editSelectedClient,
          ),
          const SizedBox(width: 6),
          _buildSmallIconButton(
            ref: ref,
            icon: Icons.close_rounded,
            onTap: _clearSelectedClient,
          ),
        ],
      ),
    );
  }

  // ④ Karta oczekującego nowego klienta (mini-create)
  Widget _buildPendingClientCard(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(125),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.themeColor.withOpacity(0.45)),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.themeColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_add_rounded, color: theme.themeColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: AppTextStyles.interRegular14.copyWith(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'new_contact'.tr,
                  style: AppTextStyles.interRegular12.copyWith(
                    color: theme.themeColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _buildSmallIconButton(
            ref: ref,
            icon: Icons.edit_rounded,
            onTap: () {
              _clearPendingClient();
              _focusSearchField();
            },
          ),
          const SizedBox(width: 6),
          _buildSmallIconButton(
            ref: ref,
            icon: Icons.close_rounded,
            onTap: _clearPendingClient,
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
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: _searchFocusNode,
              groupId: _textFieldTapRegionGroupId,
              onChanged: _onSearchChanged,
              onTap: () {
                ref.read(activeOverlayPickerProvider.notifier).state = _pickerId;
              },
              onTapOutside: (_) {
                _searchFocusNode.unfocus();
              },
              decoration: InputDecoration(
                hintText: 'search_or_choose_client'.tr,
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
                  borderSide: const BorderSide(
                    color: Colors.transparent,
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
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _openAddClientFlow,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.themeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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
                  'Clients'.tr,
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
          // ⑤ Deduplicated: używa wspólnego _buildQuickClientChips
          _buildQuickClientChipsFromProvider(context, ref, height: 40),
          const SizedBox(height: 10),
          Expanded(
            child: _clientList(context, ref),
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

  // ⑤ Deduplicated quick-clients widget — używany zarówno w overlay jak i poniżej search
  Widget _buildQuickClientChips({
    required BuildContext context,
    required WidgetRef ref,
    required List<UserContactModel> clients,
    double height = 42,
  }) {
    final theme = ref.watch(themeColorsProvider);
    final quickClients = _sortedQuickClients(clients);

    if (quickClients.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: quickClients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final client = quickClients[index];
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _setSelectedClient(client),
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
                  CircleAvatar(
                    radius: height / 3.6,
                    backgroundImage: NetworkImage(
                      client.avatar ?? defaultAvatarUrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      _clientFullName(client),
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
  }

  Widget _buildQuickClientChipsFromProvider(
    BuildContext context,
    WidgetRef ref, {
    double height = 42,
  }) {
    final asyncClients = ref.watch(clientProvider);

    return asyncClients.when(
      data: (clients) => _buildQuickClientChips(
        context: context,
        ref: ref,
        clients: clients,
        height: height,
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickClientsSection(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final clientListAsyncValue = ref.watch(clientProvider);

    return clientListAsyncValue.when(
      data: (clients) {
        if (clients.isEmpty) return const SizedBox.shrink();

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
            // ⑤ Używa wspólnego widgetu
            _buildQuickClientChips(
              context: context,
              ref: ref,
              clients: clients,
              height: 42,
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
          itemBuilder: (_, __) => _buildQuickClientShimmer(context, ref),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickClientShimmer(BuildContext context, WidgetRef ref) {
    return Container(
      width: 118,
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

  Widget _clientList(BuildContext context, WidgetRef ref) {
    final clientListAsyncValue = ref.watch(clientProvider);

    return clientListAsyncValue.when(
      data: (clients) {
        if (clients.isEmpty) {
          return _buildNoClientsMessage(context, ref);
        }
        return _buildClientList(context, ref, clients);
      },
      loading: () => _buildLoadingState(context, ref),
      error: (_, __) => _buildErrorState(context, ref),
    );
  }

  Widget _buildNoClientsMessage(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: CustomBackgroundGradients.adGradient1(context, ref),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No clients available'.tr,
          style: AppTextStyles.interRegular12.copyWith(
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildClientList(
    BuildContext context,
    WidgetRef ref,
    List<UserContactModel> clients,
  ) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: clients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final client = clients[index];
        return _buildClientCard(context, ref, client);
      },
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    WidgetRef ref,
    UserContactModel client,
  ) {
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _setSelectedClient(client),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: CustomBackgroundGradients.crmadgradient(context, ref),
          border: Border.all(
            color: theme.bordercolor.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(client.avatar ?? defaultAvatarUrl),
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _clientFullName(client),
                style: AppTextStyles.interRegular14.copyWith(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
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
          height: 58,
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
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  if (showErrorIcon)
                    const Positioned(
                      left: 10,
                      top: 10,
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
