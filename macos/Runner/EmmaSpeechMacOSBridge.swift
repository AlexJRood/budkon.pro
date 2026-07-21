import Cocoa
import FlutterMacOS
import Speech
import AVFoundation

final class EmmaSpeechMacOSBridge: NSObject, FlutterPlugin, FlutterStreamHandler, SFSpeechRecognizerDelegate {
    private let methodChannelName = "hously/emma_speech/methods"
    private let eventChannelName = "hously/emma_speech/events"

    private var eventSink: FlutterEventSink?

    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var keepListening = false
    private var isStoppingGracefully = false
    private var currentLocale = "pl-PL"
    private var currentMode: RecognitionMode = .auto

    /// Transcript z poprzednich, zamkniętych segmentów.
    private var committedTranscript = ""

    private enum RecognitionMode: String {
        case auto
        case preferOnDevice
        case requireOnDevice
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = EmmaSpeechMacOSBridge()

        let methodChannel = FlutterMethodChannel(
            name: instance.methodChannelName,
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(
            name: instance.eventChannelName,
            binaryMessenger: registrar.messenger
        )
        eventChannel.setStreamHandler(instance)
    }

    deinit {
        disposeRecognition()
    }

    // MARK: - FlutterPlugin

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCapabilities":
            let args = call.arguments as? [String: Any]
            let locale = (args?["locale"] as? String) ?? currentLocale
            result(getCapabilities(localeIdentifier: locale))

        case "getActiveSessionSnapshot":
            result(getActiveSessionSnapshot())

        case "requestPermissions":
            requestPermissions(result: result)

        case "start":
            let args = call.arguments as? [String: Any]
            let locale = (args?["locale"] as? String) ?? "pl-PL"
            let modeRaw = (args?["mode"] as? String) ?? "auto"
            let mode = RecognitionMode(rawValue: modeRaw) ?? .auto
            startRecognition(localeIdentifier: locale, mode: mode, result: result)

        case "stop":
            stopRecognition()
            result(true)

        case "cancel":
            cancelRecognition()
            result(true)

        case "dispose":
            disposeRecognition()
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Stream handler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - Capabilities / permissions

    private func getCapabilities(localeIdentifier: String) -> [String: Any] {
        let locale = Locale(identifier: localeIdentifier)
        let recognizer = SFSpeechRecognizer(locale: locale)

        let speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let micGranted = microphonePermissionGranted()

        return [
            "platform": "macos",
            "available": recognizer?.isAvailable ?? false,
            "onDeviceAvailable": recognizer?.supportsOnDeviceRecognition ?? false,
            "permissionGranted": speechAuthorized && micGranted,
            "locale": localeIdentifier
        ]
    }

    private func getActiveSessionSnapshot() -> [String: Any] {
        return [
            "platform": "macos",
            "locale": currentLocale,
            "mode": currentMode.rawValue,
            "keepListening": keepListening,
            "isStoppingGracefully": isStoppingGracefully,
            "audioEngineRunning": audioEngine.isRunning,
            "hasRecognizer": speechRecognizer != nil,
            "hasRecognitionRequest": recognitionRequest != nil,
            "hasRecognitionTask": recognitionTask != nil,
            "committedTranscriptLength": committedTranscript.count
        ]
    }

    private func requestPermissions(result: @escaping FlutterResult) {
        let group = DispatchGroup()

        var speechGranted = false
        var micGranted = false

        group.enter()
        SFSpeechRecognizer.requestAuthorization { status in
            speechGranted = (status == .authorized)
            group.leave()
        }

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch micStatus {
        case .authorized:
            micGranted = true

        case .notDetermined:
            group.enter()
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                micGranted = granted
                group.leave()
            }

        case .denied, .restricted:
            micGranted = false

        @unknown default:
            micGranted = false
        }

        group.notify(queue: .main) {
            let granted = speechGranted && micGranted

            self.emit([
                "type": "permission",
                "granted": granted
            ])

            result([
                "granted": granted,
                "speechGranted": speechGranted,
                "microphoneGranted": micGranted
            ])
        }
    }

    private func microphonePermissionGranted() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    // MARK: - Recognition lifecycle

    private func startRecognition(
        localeIdentifier: String,
        mode: RecognitionMode,
        result: @escaping FlutterResult
    ) {
        let speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let micGranted = microphonePermissionGranted()

        guard speechAuthorized && micGranted else {
            result(
                FlutterError(
                    code: "permission_denied",
                    message: "Microphone or speech recognition permission not granted.",
                    details: nil
                )
            )
            return
        }

        currentLocale = localeIdentifier
        currentMode = mode
        keepListening = true
        isStoppingGracefully = false
        committedTranscript = ""

        let locale = Locale(identifier: localeIdentifier)
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            result(
                FlutterError(
                    code: "recognizer_unavailable",
                    message: "Cannot create SFSpeechRecognizer for locale \(localeIdentifier).",
                    details: nil
                )
            )
            return
        }

        recognizer.delegate = self

        guard recognizer.isAvailable else {
            result(
                FlutterError(
                    code: "recognizer_not_available",
                    message: "Speech recognizer is not available right now.",
                    details: nil
                )
            )
            return
        }

        if mode == .requireOnDevice && !recognizer.supportsOnDeviceRecognition {
            result(
                FlutterError(
                    code: "on_device_unavailable",
                    message: "On-device speech recognition is not available for locale \(localeIdentifier).",
                    details: nil
                )
            )
            return
        }

        speechRecognizer = recognizer

        do {
            try startAudioSession(with: recognizer, mode: mode)

            emit([
                "type": "availability",
                "available": recognizer.isAvailable,
                "onDevice": recognizer.supportsOnDeviceRecognition
            ])

            emit([
                "type": "listening",
                "listening": true
            ])

            result(true)
        } catch {
            keepListening = false
            isStoppingGracefully = false
            committedTranscript = ""

            emitError(code: "macos_start_failed", message: error.localizedDescription)

            result(
                FlutterError(
                    code: "macos_start_failed",
                    message: error.localizedDescription,
                    details: nil
                )
            )
        }
    }

    private func shouldRequireOnDevice(
        recognizer: SFSpeechRecognizer,
        mode: RecognitionMode
    ) -> Bool {
        switch mode {
        case .auto:
            return false
        case .preferOnDevice:
            return recognizer.supportsOnDeviceRecognition
        case .requireOnDevice:
            return true
        }
    }

    private func mergeTranscript(committed: String, current: String) -> String {
        let left = committed.trimmingCharacters(in: .whitespacesAndNewlines)
        let right = current.trimmingCharacters(in: .whitespacesAndNewlines)

        if left.isEmpty { return right }
        if right.isEmpty { return left }
        return "\(left)\n\(right)"
    }

    private func startAudioSession(
        with recognizer: SFSpeechRecognizer,
        mode: RecognitionMode
    ) throws {
        teardownRecognitionTaskOnly(cancelTask: true)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.requiresOnDeviceRecognition = shouldRequireOnDevice(
            recognizer: recognizer,
            mode: mode
        )

        if #available(macOS 13.0, *) {
            request.addsPunctuation = true
        }

        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let currentText = result.bestTranscription.formattedString
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let fullText = self.mergeTranscript(
                    committed: self.committedTranscript,
                    current: currentText
                )

                if !fullText.isEmpty {
                    self.emit([
                        "type": result.isFinal ? "final" : "partial",
                        "text": fullText,
                        "isFinal": result.isFinal
                    ])
                }

                if result.isFinal {
                    self.committedTranscript = fullText

                    self.emit([
                        "type": "listening",
                        "listening": false
                    ])

                    self.teardownRecognitionTaskOnly(cancelTask: false)

                    if self.keepListening {
                        self.scheduleRestartIfNeeded()
                    } else {
                        self.finishStopIfNeeded()
                    }
                    return
                }
            }

            if let error = error {
                if self.isStoppingGracefully || !self.keepListening {
                    self.finishStopIfNeeded()
                    return
                }

                self.emitError(code: "macos_runtime_error", message: error.localizedDescription)
                self.teardownRecognitionTaskOnly(cancelTask: false)
                self.scheduleRestartIfNeeded()
            }
        }
    }

    private func scheduleRestartIfNeeded() {
        guard keepListening else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }
            guard self.keepListening else { return }

            let locale = Locale(identifier: self.currentLocale)
            guard let recognizer = SFSpeechRecognizer(locale: locale) else { return }

            recognizer.delegate = self

            guard recognizer.isAvailable else { return }

            if self.currentMode == .requireOnDevice && !recognizer.supportsOnDeviceRecognition {
                self.emitError(
                    code: "on_device_unavailable",
                    message: "On-device speech recognition became unavailable."
                )
                return
            }

            self.speechRecognizer = recognizer

            do {
                try self.startAudioSession(with: recognizer, mode: self.currentMode)

                self.emit([
                    "type": "availability",
                    "available": recognizer.isAvailable,
                    "onDevice": recognizer.supportsOnDeviceRecognition
                ])

                self.emit([
                    "type": "listening",
                    "listening": true
                ])
            } catch {
                self.emitError(code: "macos_restart_failed", message: error.localizedDescription)
            }
        }
    }

    private func stopRecognition() {
        guard recognitionTask != nil || audioEngine.isRunning else {
            emit([
                "type": "listening",
                "listening": false
            ])
            return
        }

        keepListening = false
        isStoppingGracefully = true

        recognitionRequest?.endAudio()

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.finish()

        emit([
            "type": "listening",
            "listening": false
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.finishStopIfNeeded()
        }
    }

    private func cancelRecognition() {
        keepListening = false
        isStoppingGracefully = false
        committedTranscript = ""

        recognitionTask?.cancel()
        teardownRecognitionTaskOnly(cancelTask: false)

        emit([
            "type": "listening",
            "listening": false
        ])
    }

    private func disposeRecognition() {
        keepListening = false
        isStoppingGracefully = false
        committedTranscript = ""

        recognitionTask?.cancel()
        teardownRecognitionTaskOnly(cancelTask: false)

        emit([
            "type": "listening",
            "listening": false
        ])
    }

    private func finishStopIfNeeded() {
        teardownRecognitionTaskOnly(cancelTask: false)
        isStoppingGracefully = false
    }

    private func teardownRecognitionTaskOnly(cancelTask: Bool) {
        if cancelTask {
            recognitionTask?.cancel()
        }

        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
    }

    // MARK: - Delegate

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        emit([
            "type": "availability",
            "available": available,
            "onDevice": speechRecognizer.supportsOnDeviceRecognition
        ])
    }

    // MARK: - Events

    private func emit(_ payload: [String: Any]) {
        DispatchQueue.main.async {
            self.eventSink?(payload)
        }
    }

    private func emitError(code: String, message: String) {
        emit([
            "type": "error",
            "code": code,
            "message": message
        ])

        emit([
            "type": "listening",
            "listening": false
        ])
    }
}