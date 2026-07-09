import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:emma/automation/emma_automation_service.dart';
import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class AutomationConnectorBlockDefinition extends EmmaBlockDefinition {
  const AutomationConnectorBlockDefinition();

  @override
  String get key => 'automation_connector';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.automationConnector;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _AutomationConnectorCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

// ---------------------------------------------------------------------------

enum _ConnectorSetupStep { form, testing, done, error }

class _AuthTypeOption {
  final String id;
  final String label;
  final String icon;
  final List<_CredentialField> fields;

  const _AuthTypeOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.fields,
  });
}

class _CredentialField {
  final String key;
  final String label;
  final bool isSecret;
  final String hint;

  const _CredentialField({
    required this.key,
    required this.label,
    this.isSecret = false,
    this.hint = '',
  });
}

const _authTypes = [
  _AuthTypeOption(
    id: 'none',
    label: 'Brak auth',
    icon: '🔓',
    fields: [],
  ),
  _AuthTypeOption(
    id: 'api_key_header',
    label: 'API Key (nagłówek)',
    icon: '🔑',
    fields: [
      _CredentialField(key: 'header_name', label: 'Nazwa nagłówka', hint: 'X-Api-Key'),
      _CredentialField(key: 'api_key', label: 'Klucz API', isSecret: true),
    ],
  ),
  _AuthTypeOption(
    id: 'bearer',
    label: 'Bearer token',
    icon: '🎫',
    fields: [
      _CredentialField(key: 'token', label: 'Token', isSecret: true),
    ],
  ),
  _AuthTypeOption(
    id: 'basic',
    label: 'HTTP Basic',
    icon: '🔐',
    fields: [
      _CredentialField(key: 'username', label: 'Użytkownik'),
      _CredentialField(key: 'password', label: 'Hasło', isSecret: true),
    ],
  ),
  _AuthTypeOption(
    id: 'oauth2_client',
    label: 'OAuth 2.0 Client Credentials',
    icon: '🛡️',
    fields: [
      _CredentialField(key: 'client_id', label: 'Client ID'),
      _CredentialField(key: 'client_secret', label: 'Client Secret', isSecret: true),
      _CredentialField(key: 'token_url', label: 'Token URL', hint: 'https://...'),
    ],
  ),
];

// ---------------------------------------------------------------------------

class _AutomationConnectorCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _AutomationConnectorCard({
    required this.block,
    required this.maxWidth,
  });

  @override
  ConsumerState<_AutomationConnectorCard> createState() =>
      _AutomationConnectorCardState();
}

class _AutomationConnectorCardState
    extends ConsumerState<_AutomationConnectorCard> {
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final Map<String, TextEditingController> _credCtrl = {};

  _ConnectorSetupStep _step = _ConnectorSetupStep.form;
  _AuthTypeOption _selectedAuth = _authTypes.first;
  String? _errorMessage;
  Map<String, dynamic>? _testResult;
  String? _connectorId;

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty && _urlCtrl.text.trim().isNotEmpty;

  Color get _accent => const Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    final raw = widget.block.raw;
    _nameCtrl.text = (raw['connector_name'] ?? '').toString();
    _urlCtrl.text = (raw['base_url'] ?? '').toString();
    _nameCtrl.addListener(() => setState(() {}));
    _urlCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    for (final c in _credCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(String key) {
    return _credCtrl.putIfAbsent(key, TextEditingController.new);
  }

  Map<String, String> get _credentials {
    final result = <String, String>{};
    for (final field in _selectedAuth.fields) {
      result[field.key] = _ctrlFor(field.key).text.trim();
    }
    return result;
  }

  Future<void> _saveAndTest() async {
    setState(() {
      _step = _ConnectorSetupStep.testing;
      _errorMessage = null;
    });

    try {
      final svc = ref.read(emmaAutomationServiceProvider);

      final connector = await svc.createConnector(
        name: _nameCtrl.text.trim(),
        baseUrl: _urlCtrl.text.trim(),
        authType: _selectedAuth.id,
        credentials:
            _credentials.isEmpty ? null : Map<String, dynamic>.from(_credentials),
      );

      _connectorId = connector['id']?.toString();

      if (_connectorId != null) {
        final testRes = await svc.testConnector(_connectorId!);
        setState(() {
          _testResult = {
            'ok': testRes.ok,
            'latency_ms': testRes.latencyMs,
            'error': testRes.errorMessage,
          };
          _step = testRes.ok
              ? _ConnectorSetupStep.done
              : _ConnectorSetupStep.error;
          _errorMessage = testRes.errorMessage;
        });
      } else {
        setState(() {
          _step = _ConnectorSetupStep.done;
        });
      }
    } catch (e) {
      setState(() {
        _step = _ConnectorSetupStep.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmmaBlockCardShell(
      maxWidth: widget.maxWidth,
      borderColor: _accent,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _ConnectorSetupStep.testing:
        return _buildTesting();
      case _ConnectorSetupStep.done:
        return _buildDone();
      case _ConnectorSetupStep.error:
        return _buildError();
      case _ConnectorSetupStep.form:
        return _buildForm();
    }
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cable_outlined, size: 13, color: _accent),
            const SizedBox(width: 5),
            Text(
              'automation_connect_api'.tr,
              style: TextStyle(
                color: _accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _TextField(
          controller: _nameCtrl,
          label: 'automation_connector_name'.tr,
          hint: 'np. Slack, Jira, Stripe...',
        ),

        const SizedBox(height: 8),

        _TextField(
          controller: _urlCtrl,
          label: 'automation_connector_url'.tr,
          hint: 'https://api.example.com',
          keyboardType: TextInputType.url,
        ),

        const SizedBox(height: 12),

        Text(
          'automation_auth_type'.tr,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _authTypes.map((auth) {
            final selected = _selectedAuth.id == auth.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedAuth = auth),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? _accent.withAlpha(40)
                      : Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? _accent : Colors.white.withAlpha(40),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  '${auth.icon} ${auth.label}',
                  style: TextStyle(
                    color: selected ? _accent : Colors.white70,
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        if (_selectedAuth.fields.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._selectedAuth.fields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TextField(
                controller: _ctrlFor(field.key),
                label: field.label,
                hint: field.hint,
                isSecret: field.isSecret,
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _canSave ? _saveAndTest : null,
            icon: const Icon(Icons.link, size: 16),
            label: Text('automation_connect_and_test'.tr),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              disabledBackgroundColor: _accent.withAlpha(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTesting() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: CircularProgressIndicator(
            color: _accent,
            strokeWidth: 2,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'automation_testing_connection'.tr,
            style: TextStyle(color: _accent, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDone() {
    final latency = _testResult?['latency_ms'] as int? ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_outline,
                size: 16, color: Colors.greenAccent),
            const SizedBox(width: 6),
            Text(
              'automation_connector_ok'.tr,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _nameCtrl.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          _urlCtrl.text,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        if (latency > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${'automation_latency'.tr}: ${latency}ms',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'automation_connector_ready_info'.tr,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
            const SizedBox(width: 6),
            Text(
              'automation_connector_error'.tr,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        EmmaActionPill(
          label: 'automation_retry'.tr,
          icon: Icons.refresh,
          onTap: () => setState(() {
            _step = _ConnectorSetupStep.form;
            _errorMessage = null;
          }),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _TextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isSecret;
  final TextInputType keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    this.hint = '',
    this.isSecret = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: widget.controller,
          obscureText: widget.isSecret && _obscure,
          keyboardType: widget.keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withAlpha(12),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withAlpha(30)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withAlpha(30)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00BCD4)),
            ),
            suffixIcon: widget.isSecret
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: Colors.white38,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
