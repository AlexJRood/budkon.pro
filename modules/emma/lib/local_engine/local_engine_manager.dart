import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final localEngineManagerProvider = ChangeNotifierProvider<LocalEngineManager>(
  (ref) => LocalEngineManager(),
);

// ── State ─────────────────────────────────────────────────────────────────────

enum LocalEngineStatus { stopped, starting, running, stopping, error }

class LocalEngineState {
  final LocalEngineStatus status;
  final String? token;
  final String? errorMessage;
  final DateTime? startedAt;
  final int restartCount;

  const LocalEngineState({
    required this.status,
    this.token,
    this.errorMessage,
    this.startedAt,
    this.restartCount = 0,
  });

  static const initial = LocalEngineState(status: LocalEngineStatus.stopped);

  bool get isRunning => status == LocalEngineStatus.running;
  bool get isBusy    => status == LocalEngineStatus.starting ||
                        status == LocalEngineStatus.stopping;

  LocalEngineState copyWith({
    LocalEngineStatus? status,
    String? token,
    String? errorMessage,
    DateTime? startedAt,
    int? restartCount,
  }) => LocalEngineState(
    status:       status       ?? this.status,
    token:        token        ?? this.token,
    errorMessage: errorMessage ?? this.errorMessage,
    startedAt:    startedAt   ?? this.startedAt,
    restartCount: restartCount ?? this.restartCount,
  );
}

// ── Manager ───────────────────────────────────────────────────────────────────

const _kHost           = '127.0.0.1';
const _kPort           = 43890;
const _kTimeout        = Duration(seconds: 40);
const _kPoll           = Duration(milliseconds: 800);
const _kWatchdogPeriod = Duration(seconds: 10);
const _kMaxRestarts    = 3;
const _kRestartCooldown = Duration(minutes: 2);

class LocalEngineManager extends ChangeNotifier {
  LocalEngineState _state = LocalEngineState.initial;
  Process?  _process;
  Timer?    _watchdog;
  DateTime? _lastRestartAt;
  bool      _intentionalStop = false;

  LocalEngineState get state => _state;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_state.isBusy || _state.isRunning) return;

    _intentionalStop = false;
    _set(_state.copyWith(status: LocalEngineStatus.starting, errorMessage: null));

    // Already running (survived an app restart)?
    if (await _alive()) {
      final token = await _readToken();
      _set(_state.copyWith(
        status: LocalEngineStatus.running,
        token: token,
        startedAt: DateTime.now(),
      ));
      _startWatchdog();
      return;
    }

    if (!_binaryExists) {
      _set(_state.copyWith(
        status: LocalEngineStatus.error,
        errorMessage: 'Superbee binary not found. Please reinstall.',
      ));
      return;
    }

    final launched = await _launch();
    if (!launched) return;

    _startWatchdog();
  }

  Future<void> stop() async {
    _intentionalStop = true;
    _stopWatchdog();
    if (!_state.isRunning && !_state.isBusy) return;
    _set(_state.copyWith(status: LocalEngineStatus.stopping));
    await _kill();
    _set(LocalEngineState.initial);
  }

  // ── Launch ─────────────────────────────────────────────────────────────────

  Future<bool> _launch() async {
    try {
      _process = await Process.start(
        _binaryPath,
        [],
        workingDirectory: File(_binaryPath).parent.path,
        mode: ProcessStartMode.detachedWithStdio,
      );
    } catch (e) {
      _set(_state.copyWith(
        status: LocalEngineStatus.error,
        errorMessage: 'Failed to launch: $e',
      ));
      return false;
    }

    final ready = await _waitReady();
    if (!ready) {
      await _kill();
      _set(_state.copyWith(
        status: LocalEngineStatus.error,
        errorMessage: 'Engine did not respond within ${_kTimeout.inSeconds}s.',
      ));
      return false;
    }

    final token = await _readToken();
    _set(_state.copyWith(
      status:    LocalEngineStatus.running,
      token:     token,
      startedAt: DateTime.now(),
    ));
    return true;
  }

  // ── Watchdog ───────────────────────────────────────────────────────────────

  void _startWatchdog() {
    _stopWatchdog();
    _watchdog = Timer.periodic(_kWatchdogPeriod, (_) => _watchdogTick());
  }

  void _stopWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  Future<void> _watchdogTick() async {
    if (_intentionalStop || !_state.isRunning) return;

    if (await _alive()) return; // engine healthy

    // Engine unreachable — attempt restart with rate-limit
    if (kDebugMode) debugPrint('SuperbeeClient: watchdog detected crash, restarting…');

    final now = DateTime.now();
    final restartCount = _state.restartCount;

    if (restartCount >= _kMaxRestarts) {
      final cooldownOver = _lastRestartAt == null ||
          now.difference(_lastRestartAt!) >= _kRestartCooldown;
      if (!cooldownOver) {
        _set(_state.copyWith(
          status: LocalEngineStatus.error,
          errorMessage:
              'Local engine crashed $_kMaxRestarts times. '
              'Will retry after ${_kRestartCooldown.inMinutes} min.',
        ));
        _stopWatchdog();
        return;
      }
      // Cooldown passed — reset counter and try again
      _set(_state.copyWith(restartCount: 0));
    }

    _lastRestartAt = now;
    _set(_state.copyWith(
      status:       LocalEngineStatus.starting,
      errorMessage: null,
      restartCount: restartCount + 1,
    ));

    await _launch();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<bool> _waitReady() async {
    final deadline = DateTime.now().add(_kTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await _alive()) return true;
      await Future.delayed(_kPoll);
    }
    return false;
  }

  Future<bool> _alive() async {
    try {
      final client = HttpClient();
      final req = await client
          .getUrl(Uri.parse('http://$_kHost:$_kPort/llm/health'))
          .timeout(const Duration(seconds: 2));
      req.headers.set('Connection', 'close');
      final resp = await req.close().timeout(const Duration(seconds: 2));
      await resp.drain<void>();
      client.close(force: true);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _readToken() async {
    try {
      final file = File(_configPath);
      if (!file.existsSync()) return null;
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return raw['token'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _kill() async {
    final proc = _process;
    _process = null;
    if (proc == null) return;
    try {
      proc.kill();
      await proc.exitCode.timeout(const Duration(seconds: 5));
    } catch (_) {
      try { Process.killPid(proc.pid, ProcessSignal.sigkill); } catch (_) {}
    }
  }

  void _set(LocalEngineState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopWatchdog();
    _kill();
    super.dispose();
  }
}

// ── Platform paths ────────────────────────────────────────────────────────────

String get _binaryPath {
  final base = File(Platform.resolvedExecutable).parent.path;
  if (Platform.isWindows) {
    return '$base\\data\\flutter_assets\\assets\\superbee\\superbee-win.exe';
  }
  if (Platform.isMacOS) {
    return '$base/../Resources/flutter_assets/assets/superbee/superbee-macos';
  }
  return '$base/data/flutter_assets/assets/superbee/superbee-linux';
}

bool get _binaryExists => File(_binaryPath).existsSync();

String get _configDir {
  if (Platform.isWindows) {
    return '${Platform.environment['LOCALAPPDATA'] ?? ''}\\Superbee\\LocalEngine';
  }
  if (Platform.isMacOS) {
    return '${Platform.environment['HOME']}/Library/Application Support/Superbee/LocalEngine';
  }
  final xdg = Platform.environment['XDG_DATA_HOME'] ??
               '${Platform.environment['HOME']}/.local/share';
  return '$xdg/Superbee/LocalEngine';
}

String get _configPath =>
    Platform.isWindows ? '$_configDir\\config.json' : '$_configDir/config.json';
