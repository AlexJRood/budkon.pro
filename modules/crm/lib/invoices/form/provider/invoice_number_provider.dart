import 'package:crm/invoices/form/models/invoice_number_preview_model.dart';
import 'package:crm/invoices/form/provider/form_provider.dart';
import 'package:crm/invoices/form/provider/invoice_number_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoiceNumberApiProvider = Provider<InvoiceNumberApi>((ref) {
  return InvoiceNumberApi();
});

class InvoiceNumberNotifier extends StateNotifier<AsyncValue<InvoiceNumberPreview?>> {
  InvoiceNumberNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  String _mapInvoiceTypeToKind(String invoiceType) {
    final t = (invoiceType).trim().toLowerCase();
    if (t == 'proforma') return 'proforma';
    return 'invoice';
  }

  InvoiceNumberPreview? _previewFromForm() {
    final form = ref.read(revenueFormProvider);

    final invoiceNumber = form.invoiceNumberController.text.trim();
    final reservationId = (form.invoiceNumberReservationId ?? '').trim();
    final expiresAt = form.invoiceNumberReservationExpiresAt;

    if (invoiceNumber.isEmpty || reservationId.isEmpty || expiresAt == null) {
      return null;
    }

    return InvoiceNumberPreview(
      invoiceNumber: invoiceNumber,
      reservationId: reservationId,
      expiresAt: expiresAt,
    );
  }

  bool _isValidFormReservation(InvoiceNumberPreview p) {
    // Comments in English.
    // Consider reservation valid if not expired.
    return !p.isExpired;
  }

  /// Fetches preview from backend only when needed.
  /// - force=false: reuse existing valid reservation in form/state.
  /// - force=true: request new reservation from backend.
  Future<void> refreshFromForm({bool force = false}) async {
    final kind = _mapInvoiceTypeToKind(ref.read(revenueFormProvider).invoiceType);

    // ✅ Reuse existing reservation (do NOT burn a new number)
    final cached = state.valueOrNull ?? _previewFromForm();
    if (!force && cached != null && _isValidFormReservation(cached)) {
      // Keep provider state consistent (no network call).
      state = AsyncValue.data(cached);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final api = ref.read(invoiceNumberApiProvider);
      final json = await api.preview(kind: kind, ref: ref);
      final preview = InvoiceNumberPreview.fromJson(json);

      // Persist into form state (controllers + reservation id)
      ref.read(revenueFormProvider.notifier).setInvoiceNumberPreview(
            invoiceNumber: preview.invoiceNumber,
            reservationId: preview.reservationId,
            expiresAt: preview.expiresAt,
          );

      state = AsyncValue.data(preview);
    } catch (e, st) {
      // If request fails but we have a valid cached reservation, keep it.
      if (!force && cached != null && _isValidFormReservation(cached)) {
        state = AsyncValue.data(cached);
        return;
      }
      state = AsyncValue.error(e, st);
    }
  }

  /// Ensures the reservation is valid right before submit.
  /// Uses cached reservation if still valid; otherwise fetches a fresh one.
  Future<void> ensureValidReservation() async {
    final cached = state.valueOrNull ?? _previewFromForm();
    if (cached != null && _isValidFormReservation(cached)) {
      state = AsyncValue.data(cached);
      return;
    }
    await refreshFromForm(force: false);
  }

  /// Explicitly request a NEW number (burn next sequence).
  Future<void> forceNewNumber() async {
    await refreshFromForm(force: true);
  }

  void clear() {
    state = const AsyncValue.data(null);
    ref.read(revenueFormProvider.notifier).clearInvoiceNumberPreview();
  }
}

final invoiceNumberProvider =
    StateNotifierProvider<InvoiceNumberNotifier, AsyncValue<InvoiceNumberPreview?>>(
  (ref) => InvoiceNumberNotifier(ref),
);
