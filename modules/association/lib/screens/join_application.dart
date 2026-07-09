import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/back_button.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dio/dio.dart';
// budkon: dynamic_app removed
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

// ── API ─────────────────────────────────────────────────────────────────────

class JoinAssociationApi {
  static const _base = 'https://www.superbee.cloud';

  static Future<String> uploadDocument(Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await ApiServices.post(
      '$_base/association/applications/upload_document/',
      formData: formData,
      hasToken: true,
    );
    if (res == null || (res.statusCode != 200 && res.statusCode != 201)) {
      throw Exception('Upload failed (${res?.statusCode})');
    }
    final url = (res.data as Map)['file_url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('No file_url in upload response');
    }
    return url;
  }

  static Future<Map<String, dynamic>> create({
    required int associationId,
    required String applicantType,
    String? companyName,
    required String info,
    List<Map<String, String>> documents = const [],
  }) async {
    final payload = <String, dynamic>{
      'association_id': associationId,
      'info': info,
      if (companyName != null && companyName.trim().isNotEmpty)
        'company_name': companyName.trim(),
      'applicant_type': applicantType,
      'documents': documents,
    };
    final res = await ApiServices.post(
      '$_base/association/applications/apply/',
      hasToken: true,
      data: payload,
    );
    if (res == null) throw Exception('No response from server');
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Create failed (${res.statusCode})');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }
}

// ── Document upload model ────────────────────────────────────────────────────

class _UploadedDoc {
  _UploadedDoc({required this.fileUrl, required this.filename});
  final String fileUrl;
  final String filename;
  final TextEditingController desc = TextEditingController();

  void dispose() => desc.dispose();

  Map<String, String> toPayload() => {
        'file_url': fileUrl,
        if (desc.text.trim().isNotEmpty) 'description': desc.text.trim(),
      };
}

// ── Page ─────────────────────────────────────────────────────────────────────

class JoinAssociationPage extends ConsumerStatefulWidget {
  const JoinAssociationPage({super.key, this.prefilledAssociationId});

  final int? prefilledAssociationId;

  @override
  ConsumerState<JoinAssociationPage> createState() =>
      _JoinAssociationPageState();
}

class _JoinAssociationPageState extends ConsumerState<JoinAssociationPage> {
  final _formKey = GlobalKey<FormState>();
  final _assocCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _infoCtrl = TextEditingController();
  final _sideMenuKey = GlobalKey<SideMenuState>();

  String _applicantType = 'person';
  bool _submitting = false;
  bool _uploadingDoc = false;
  bool _docDragging = false;

  final List<_UploadedDoc> _docs = [];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAssociationId != null) {
      _assocCtrl.text = widget.prefilledAssociationId!.toString();
    }
  }

  @override
  void dispose() {
    _assocCtrl.dispose();
    _companyCtrl.dispose();
    _infoCtrl.dispose();
    for (final d in _docs) {
      d.dispose();
    }
    super.dispose();
  }

  // ── Document upload ──────────────────────────────────────────────────────

  Future<void> _pickDocument() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    for (final f in res.files) {
      if (f.bytes != null) await _doUpload(f.bytes!, f.name);
    }
  }

  Future<void> _dropDocuments(List<XFile> files) async {
    for (final f in files) {
      final bytes = await f.readAsBytes();
      await _doUpload(bytes, f.name);
    }
  }

  Future<void> _doUpload(Uint8List bytes, String filename) async {
    if (!mounted) return;
    setState(() => _uploadingDoc = true);
    try {
      final url = await JoinAssociationApi.uploadDocument(bytes, filename);
      if (!mounted) return;
      setState(() => _docs.add(_UploadedDoc(fileUrl: url, filename: filename)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'Upload error'.tr}: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingDoc = false);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final assocId = int.tryParse(_assocCtrl.text.trim());
    if (assocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Podaj poprawne ID stowarzyszenia.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await JoinAssociationApi.create(
        associationId: assocId,
        applicantType: _applicantType,
        companyName:
            _applicantType == 'company' ? _companyCtrl.text.trim() : null,
        info: _infoCtrl.text.trim(),
        documents: _docs.map((d) => d.toPayload()).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wniosek wysłany.')),
      );
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd wysyłki: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _infoCtrl.clear();
    _companyCtrl.clear();
    for (final d in _docs) {
      d.dispose();
    }
    setState(() {
      _docs.clear();
      _applicantType = 'person';
      if (widget.prefilledAssociationId == null) {
        _assocCtrl.clear();
      } else {
        _assocCtrl.text = widget.prefilledAssociationId!.toString();
      }
    });
  }

  // ── Field decoration (themed) ────────────────────────────────────────────

  InputDecoration _fieldDecoration(
    ThemeColors theme, {
    required String label,
    String? hint,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.dashboardBoarder),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle:
          TextStyle(color: theme.textColor.withAlpha(180), fontSize: 13),
      hintStyle: TextStyle(color: theme.textColor.withAlpha(100), fontSize: 13),
      floatingLabelStyle: TextStyle(
        color: theme.themeColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: theme.adPopBackground.withAlpha(80),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.themeColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildAssocHeader(ThemeColors theme) {
    final id = widget.prefilledAssociationId;
    if (id == null) return const SizedBox.shrink();

    // budkon: associationProfileBootstrapProvider removed (dynamic_app)
    final value = const AsyncValue<Object?>.data(null);

    return value.when(
      loading: () => Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 140,
        decoration: BoxDecoration(
          color: theme.adPopBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.themeColor,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (bootstrap) {
        final profile = bootstrap.profile;
        final hasCover =
            profile.coverUrl != null && profile.coverUrl!.isNotEmpty;
        final hasLogo = profile.logoUrl != null && profile.logoUrl!.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 140,
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: BorderRadius.circular(16),
            image: hasCover
                ? DecorationImage(
                    image: NetworkImage(profile.coverUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withAlpha(80),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Stack(
            children: [
              if (!hasCover)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          theme.themeColor.withAlpha(60),
                          theme.themeColor.withAlpha(20),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.dashboardContainer,
                        border: Border.all(
                          color: Colors.white.withAlpha(80),
                          width: 2,
                        ),
                        image: hasLogo
                            ? DecorationImage(
                                image: NetworkImage(profile.logoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: hasLogo
                          ? null
                          : Icon(
                              Icons.groups_outlined,
                              color: theme.themeColor,
                              size: 30,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile.name.isNotEmpty)
                            Text(
                              profile.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      color: Colors.black54, blurRadius: 4),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (profile.headline.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              profile.headline,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withAlpha(220),
                                shadows: const [
                                  Shadow(
                                      color: Colors.black45, blurRadius: 3),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocDropZone(ThemeColors theme) {
    final dndSupported = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    final zone = GestureDetector(
      onTap: _uploadingDoc ? null : _pickDocument,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: _docDragging
              ? theme.themeColor.withAlpha(20)
              : theme.adPopBackground.withAlpha(60),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _docDragging
                ? theme.themeColor
                : theme.textColor.withAlpha(60),
            width: _docDragging ? 2 : 1.5,
          ),
        ),
        child: MouseRegion(
          cursor: _uploadingDoc
              ? SystemMouseCursors.wait
              : SystemMouseCursors.click,
          child: Center(
            child: _uploadingDoc
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: theme.themeColor,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'uploading'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(160),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.upload_file_outlined,
                        size: 26,
                        color: _docDragging
                            ? theme.themeColor
                            : theme.textColor.withAlpha(100),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kliknij lub przeciągnij pliki tutaj',
                        style: TextStyle(
                          fontSize: 12,
                          color: _docDragging
                              ? theme.themeColor
                              : theme.textColor.withAlpha(140),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (!dndSupported) return zone;

    return DropTarget(
      onDragEntered: (_) => setState(() => _docDragging = true),
      onDragExited: (_) => setState(() => _docDragging = false),
      onDragDone: (details) async {
        setState(() => _docDragging = false);
        if (!mounted || _uploadingDoc) return;
        await _dropDocuments(details.files);
      },
      child: zone,
    );
  }

  Widget _buildDocList(ThemeColors theme) {
    if (_docs.isEmpty) return const SizedBox.shrink();
    return Column(
      children: List.generate(_docs.length, (i) {
        final doc = _docs[i];
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.attach_file_rounded,
                  size: 18, color: theme.textColor.withAlpha(160)),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  doc.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: doc.desc,
                  style: TextStyle(color: theme.textColor, fontSize: 13),
                  decoration: _fieldDecoration(
                    theme,
                    label: 'Opis (opcjonalnie)',
                  ).copyWith(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: theme.textColor.withAlpha(160),
                ),
                tooltip: 'Usuń',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  doc.dispose();
                  setState(() => _docs.removeAt(i));
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildForm(ThemeColors theme, {required bool showInlineActions}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Association header (when prefilled)
              _buildAssocHeader(theme),

              // ── Association ID (only when not prefilled)
              if (widget.prefilledAssociationId == null) ...[
                TextFormField(
                  controller: _assocCtrl,
                  style: TextStyle(color: theme.textColor),
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(
                    theme,
                    label: 'ID stowarzyszenia',
                    hint: 'np. 42',
                  ),
                  validator: (v) =>
                      (v == null || int.tryParse(v.trim()) == null)
                          ? 'Podaj poprawne ID'
                          : null,
                ),
                const SizedBox(height: 14),
              ],

              // ── Applicant type + company name row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: CoreDropdown<String>(
                      label: 'Rodzaj wniosku',
                      value: _applicantType,
                      options: const ['person', 'company'],
                      display: (v) => v == 'company' ? 'Firma' : 'Osoba',
                      onChanged: (v) {
                        if (v != null) setState(() => _applicantType = v);
                      },
                    ),
                  ),
                  if (_applicantType == 'company') ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _companyCtrl,
                        style: TextStyle(color: theme.textColor),
                        decoration: _fieldDecoration(
                          theme,
                          label: 'Nazwa firmy (etykieta na liście członków)',
                        ),
                        validator: (v) {
                          if (_applicantType == 'company' &&
                              (v == null || v.trim().isEmpty)) {
                            return 'Wymagane dla firmy';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // ── Justification
              TextFormField(
                controller: _infoCtrl,
                style: TextStyle(color: theme.textColor),
                minLines: 5,
                maxLines: 10,
                decoration: _fieldDecoration(
                  theme,
                  label: 'Uzasadnienie / Informacje',
                  hint: 'Napisz kilka zdań dlaczego chcesz dołączyć…',
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Minimum 10 znaków'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Documents section
              Row(
                children: [
                  Icon(Icons.attach_file_rounded,
                      size: 16, color: theme.themeColor),
                  const SizedBox(width: 8),
                  Text(
                    'Załączniki (opcjonalnie)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildDocDropZone(theme),
              _buildDocList(theme),

              const SizedBox(height: 28),

              if (showInlineActions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildClearButton(theme),
                    const SizedBox(width: 10),
                    _buildSubmitButton(theme),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeColors theme) {
    return FilledButton.icon(
      onPressed: _submitting ? null : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: theme.themeColor,
        foregroundColor: theme.themeColorText,
        disabledBackgroundColor: theme.themeColor.withAlpha(100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      icon: _submitting
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.themeColorText,
              ),
            )
          : const Icon(Icons.send_rounded, size: 18),
      label: Text(_submitting ? 'Wysyłanie…' : 'Wyślij wniosek'),
    );
  }

  Widget _buildClearButton(ThemeColors theme) {
    return OutlinedButton.icon(
      onPressed: _submitting ? null : _clearForm,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        side: BorderSide(color: theme.dashboardBoarder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      icon: const Icon(Icons.clear_rounded, size: 18),
      label: const Text('Wyczyść'),
    );
  }

  Widget _buildActionPanel(ThemeColors theme) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSubmitButton(theme),
          const SizedBox(height: 8),
          _buildClearButton(theme),
        ],
      ),
    );
  }

  Widget _buildPageTitle(ThemeColors theme, {required bool mobile}) {
    return Row(
      children: [
        BackButtonHously(isNamedRoute: true,),
        const SizedBox(width: 10),
        Icon(Icons.how_to_reg_outlined, color: theme.themeColor, size: 22),
        const SizedBox(width: 10),
        Text(
          'Dołącz do stowarzyszenia',
          style: TextStyle(
            fontSize: mobile ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        return BarManager(
          sideMenuKey: _sideMenuKey,
          appModule: AppModule.association,
          paddingPc: 10,
          paddingMobile: 8,
          verticalButtonsPc: _buildActionPanel(theme),
          childrenPc: [
            const SizedBox(height: 8),
            _buildPageTitle(theme, mobile: false),
            const SizedBox(height: 8),
            Expanded(
              child: _buildForm(theme, showInlineActions: false),
            ),
          ],
          childrenMobile: [
            const SizedBox(height: 8),
            _buildPageTitle(theme, mobile: true),
            const SizedBox(height: 8),
            Expanded(
              child: _buildForm(theme, showInlineActions: true),
            ),
          ],
        );
      },
    );
  }
}
