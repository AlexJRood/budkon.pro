import UIKit
import Flutter
import Speech
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler, SFSpeechRecognizerDelegate {
    private let methodChannelName = "hously/emma_speech/methods"
    private let eventChannelName = "hously/emma_speech/events"
    private let liveActivityMethodChannelName = "hously/emma_live_activity/methods"
    private let platformInfoChannelName = "hously/platform_info"

    private var eventSink: FlutterEventSink?
    private var pendingMeetingAction: [String: Any]?

    // MARK: - Legacy SFSpeechRecognizer state

    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var keepListening = false
    private var isStoppingGracefully = false
    private var isStartingRecognition = false
    private var isRestartScheduled = false
    private var currentLocale = "en-US"
    private var currentMode: RecognitionMode = .auto
    private var committedTranscript = ""

    private enum RecognitionMode: String {
        case auto
        case preferOnDevice
        case requireOnDevice
    }

    // MARK: - Engine selection

    private enum SelectedSpeechEngine: String {
        case sfSpeechRecognizer
        case speechAnalyzer
    }

    private var selectedSpeechEngine: SelectedSpeechEngine = .sfSpeechRecognizer

    @available(iOS 26.0, *)
    private lazy var analyzerRuntime = EmmaSpeechAnalyzerRuntime()

    // MARK: - App lifecycle

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        if let url = launchOptions?[.url] as? URL {
            _ = handleMeetingURL(url)
        }

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        setupSpeechMethodChannel(controller: controller)
        setupSpeechEventChannel(controller: controller)
        setupLiveActivityMethodChannel(controller: controller)
        setupPlatformInfoMethodChannel(controller: controller)

        registerAudioNotifications()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if handleMeetingURL(url) {
            return true
        }

        return super.application(app, open: url, options: options)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Channel setup

    private func setupSpeechMethodChannel(controller: FlutterViewController) {
        let methodChannel = FlutterMethodChannel(
            name: methodChannelName,
            binaryMessenger: controller.binaryMessenger
        )

        methodChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "app_delegate_deallocated",
                            message: "AppDelegate no longer available.",
                            details: nil
                        )
                    )
                }
                return
            }

            DispatchQueue.main.async {
                self.handleMethodCall(call, result: result)
            }
        }
    }

    private func setupSpeechEventChannel(controller: FlutterViewController) {
        let eventChannel = FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel.setStreamHandler(self)
    }

    private func setupLiveActivityMethodChannel(controller: FlutterViewController) {
        let liveActivityMethodChannel = FlutterMethodChannel(
            name: liveActivityMethodChannelName,
            binaryMessenger: controller.binaryMessenger
        )

        liveActivityMethodChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "app_delegate_deallocated",
                            message: "AppDelegate no longer available.",
                            details: nil
                        )
                    )
                }
                return
            }

            DispatchQueue.main.async {
                self.handleLiveActivityMethodCall(call, result: result)
            }
        }
    }

    private func setupPlatformInfoMethodChannel(controller: FlutterViewController) {
        let platformInfoChannel = FlutterMethodChannel(
            name: platformInfoChannelName,
            binaryMessenger: controller.binaryMessenger
        )

        platformInfoChannel.setMethodCallHandler { [weak self] call, result in
            guard self != nil else {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "app_delegate_deallocated",
                            message: "AppDelegate no longer available.",
                            details: nil
                        )
                    )
                }
                return
            }

            DispatchQueue.main.async {
                switch call.method {
                case "isIOSAppOnMac":
                    if #available(iOS 14.0, *) {
                        result(ProcessInfo.processInfo.isiOSAppOnMac)
                    } else {
                        result(false)
                    }

                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }
    }

    // MARK: - Meeting URL handling

    private func handleMeetingURL(_ url: URL) -> Bool {
        print("📩 handleMeetingURL received: \(url.absoluteString)")

        guard url.scheme == "hously", url.host == "meeting" else {
            print("⚠️ URL ignored - unexpected scheme or host")
            return false
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ URLComponents init failed")
            return false
        }

        let action = components.queryItems?.first(where: { $0.name == "action" })?.value
        let eventId = components.queryItems?.first(where: { $0.name == "eventId" })?.value

        guard
            let action,
            !action.isEmpty,
            let eventId,
            !eventId.isEmpty
        else {
            print("❌ Missing action or eventId in URL")
            return false
        }

        pendingMeetingAction = [
            "action": action,
            "eventId": eventId,
            "receivedAt": Date().timeIntervalSince1970
        ]

        print("✅ Stored pendingMeetingAction: action=\(action), eventId=\(eventId)")
        return true
    }

    // MARK: - Flutter helpers

    private func complete(_ result: @escaping FlutterResult, _ value: Any?) {
        DispatchQueue.main.async {
            result(value)
        }
    }

    private func emit(_ payload: [String: Any]) {
        DispatchQueue.main.async {
            self.eventSink?(payload)
        }
    }

    private func emitListening(_ listening: Bool) {
        emit([
            "type": "listening",
            "listening": listening
        ])
    }

    private func emitError(code: String, message: String, details: Any? = nil) {
        var payload: [String: Any] = [
            "type": "error",
            "code": code,
            "message": message
        ]

        if let details {
            payload["details"] = details
        }

        emit(payload)
        emitListening(false)
    }

    // MARK: - Flutter channels

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCapabilities":
            let args = call.arguments as? [String: Any]
            let locale = (args?["locale"] as? String) ?? currentLocale

            Task { @MainActor in
                let merged = await self.getCapabilitiesAsync(localeIdentifier: locale)
                self.complete(result, merged)
            }

        case "getActiveSessionSnapshot":
            complete(result, getActiveSessionSnapshot())

        case "requestPermissions":
            requestPermissions(result: result)

        case "start":
            let args = call.arguments as? [String: Any]
            let locale = (args?["locale"] as? String) ?? "en-US"
            let modeRaw = (args?["mode"] as? String) ?? "auto"
            let captureProfile = (args?["captureProfile"] as? String) ?? "dictation"
            let privacyMode = (args?["privacyMode"] as? String) ?? "transcriptOnly"
            let mode = RecognitionMode(rawValue: modeRaw) ?? .auto

            Task { @MainActor in
                if #available(iOS 26.0, *) {
                    let merged = await self.getCapabilitiesAsync(localeIdentifier: locale)
                    let useModern = merged["engine"] as? String == "speechAnalyzer"

                    if useModern {
                        self.selectedSpeechEngine = .speechAnalyzer
                        self.analyzerRuntime.start(
                            localeIdentifier: locale,
                            captureProfileRaw: captureProfile,
                            privacyModeRaw: privacyMode,
                            permissionGranted: merged["permissionGranted"] as? Bool == true,
                            emit: { [weak self] payload in
                                self?.emit(payload)
                            },
                            result: result
                        )
                        return
                    }
                }

                self.selectedSpeechEngine = .sfSpeechRecognizer
                self.startRecognition(localeIdentifier: locale, mode: mode, result: result)
            }

        case "stop":
            if #available(iOS 26.0, *), selectedSpeechEngine == .speechAnalyzer {
                analyzerRuntime.stop()
                complete(result, true)
            } else {
                stopRecognition()
                complete(result, true)
            }

        case "cancel":
            if #available(iOS 26.0, *), selectedSpeechEngine == .speechAnalyzer {
                analyzerRuntime.cancel()
                complete(result, true)
            } else {
                cancelRecognition()
                complete(result, true)
            }

        case "dispose":
            if #available(iOS 26.0, *), selectedSpeechEngine == .speechAnalyzer {
                analyzerRuntime.dispose()
                complete(result, true)
            } else {
                disposeRecognition()
                complete(result, true)
            }

        default:
            complete(result, FlutterMethodNotImplemented)
        }
    }

    private func handleLiveActivityMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.2, *) else {
            complete(
                result,
                FlutterError(
                    code: "unsupported_ios",
                    message: "Live Activities require iOS 16.2+",
                    details: nil
                )
            )
            return
        }

        switch call.method {
        case "startMeetingActivity":
            guard let args = call.arguments as? [String: Any] else {
                complete(
                    result,
                    FlutterError(code: "bad_args", message: "Missing args", details: nil)
                )
                return
            }
            EmmaLiveActivityManager.shared.startMeetingActivity(args: args, result: result)

        case "updateMeetingActivity":
            guard let args = call.arguments as? [String: Any] else {
                complete(
                    result,
                    FlutterError(code: "bad_args", message: "Missing args", details: nil)
                )
                return
            }
            EmmaLiveActivityManager.shared.updateMeetingActivity(args: args, result: result)

        case "endMeetingActivity":
            guard let args = call.arguments as? [String: Any] else {
                complete(
                    result,
                    FlutterError(code: "bad_args", message: "Missing args", details: nil)
                )
                return
            }
            EmmaLiveActivityManager.shared.endMeetingActivity(args: args, result: result)

        case "consumePendingMeetingAction":
            let payload = pendingMeetingAction
            print("📤 consumePendingMeetingAction payload: \(String(describing: payload))")
            pendingMeetingAction = nil
            complete(result, payload)

        case "consumePendingMeetingIntentCommand":
            let payload = MeetingIntentStore.shared.consumeDictionary()
            print("📤 consumePendingMeetingIntentCommand payload: \(String(describing: payload))")
            complete(result, payload)

        default:
            complete(result, FlutterMethodNotImplemented)
        }
    }

    // MARK: - Public status / permissions

    private func getCapabilities(localeIdentifier: String) -> [String: Any] {
        let locale = Locale(identifier: localeIdentifier)
        let recognizer = SFSpeechRecognizer(locale: locale)

        let speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let micGranted = microphonePermissionGranted()

        return [
            "platform": "ios",
            "available": recognizer?.isAvailable ?? false,
            "onDeviceAvailable": recognizer?.supportsOnDeviceRecognition ?? false,
            "permissionGranted": speechAuthorized && micGranted,
            "locale": localeIdentifier,
            "engine": "sfSpeechRecognizer",
            "speechAnalyzerAvailable": false,
            "speechAnalyzerLocaleSupported": false,
            "speechAnalyzerLocaleInstalled": false,
            "sfSpeechRecognizerAvailable": recognizer?.isAvailable ?? false,
            "supportsMeetingMode": true,
            "supportsTemporaryAudioCapture": true,
            "supportsSpeakerDiarization": false
        ]
    }

    @MainActor
    private func getCapabilitiesAsync(localeIdentifier: String) async -> [String: Any] {
        var legacy = getCapabilities(localeIdentifier: localeIdentifier)

        let permissionGranted = legacy["permissionGranted"] as? Bool ?? false

        if #available(iOS 26.0, *) {
            let modern = await analyzerRuntime.capabilities(
                localeIdentifier: localeIdentifier,
                permissionGranted: permissionGranted
            )

            let useModern = modern["available"] as? Bool == true

            legacy["speechAnalyzerAvailable"] = modern["speechAnalyzerAvailable"]
            legacy["speechAnalyzerLocaleSupported"] = modern["speechAnalyzerLocaleSupported"]
            legacy["speechAnalyzerLocaleInstalled"] = modern["speechAnalyzerLocaleInstalled"]
            legacy["supportsMeetingMode"] = modern["supportsMeetingMode"]
            legacy["supportsTemporaryAudioCapture"] = modern["supportsTemporaryAudioCapture"]
            legacy["supportsSpeakerDiarization"] = modern["supportsSpeakerDiarization"]

            if useModern {
                legacy["available"] = modern["available"]
                legacy["onDeviceAvailable"] = modern["onDeviceAvailable"]
                legacy["engine"] = "speechAnalyzer"
            }
        }

        return legacy
    }

    private func getActiveSessionSnapshot() -> [String: Any] {
        if #available(iOS 26.0, *), selectedSpeechEngine == .speechAnalyzer {
            return analyzerRuntime.snapshot()
        }

        return [
            "platform": "ios",
            "engine": "sfSpeechRecognizer",
            "locale": currentLocale,
            "mode": currentMode.rawValue,
            "keepListening": keepListening,
            "isStoppingGracefully": isStoppingGracefully,
            "isStartingRecognition": isStartingRecognition,
            "isRestartScheduled": isRestartScheduled,
            "audioEngineRunning": audioEngine.isRunning,
            "hasRecognizer": speechRecognizer != nil,
            "hasRecognitionRequest": recognitionRequest != nil,
            "hasRecognitionTask": recognitionTask != nil,
            "committedTranscriptLength": committedTranscript.count
        ]
    }

    private func microphonePermissionGranted() -> Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        } else {
            return AVAudioSession.sharedInstance().recordPermission == .granted
        }
    }

    private func requestPermissions(result: @escaping FlutterResult) {
        let group = DispatchGroup()

        var micGranted = false
        var speechGranted = false

        group.enter()
        requestMicrophonePermission { granted in
            micGranted = granted
            group.leave()
        }

        group.enter()
        SFSpeechRecognizer.requestAuthorization { status in
            speechGranted = status == .authorized
            group.leave()
        }

        group.notify(queue: .main) {
            let granted = micGranted && speechGranted

            self.emit([
                "type": "permission",
                "granted": granted
            ])

            self.complete(result, [
                "granted": granted,
                "microphoneGranted": micGranted,
                "speechGranted": speechGranted
            ])
        }
    }

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                completion(granted)
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                completion(granted)
            }
        }
    }

    // MARK: - Legacy STT start / stop

    private func startRecognition(
        localeIdentifier: String,
        mode: RecognitionMode,
        result: @escaping FlutterResult
    ) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.startRecognition(localeIdentifier: localeIdentifier, mode: mode, result: result)
            }
            return
        }

        guard !isStartingRecognition else {
            complete(result, true)
            return
        }

        isStartingRecognition = true
        defer { isStartingRecognition = false }

        let speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let micGranted = microphonePermissionGranted()

        guard speechAuthorized && micGranted else {
            complete(
                result,
                FlutterError(
                    code: "permission_denied",
                    message: "Microphone or speech recognition permission not granted.",
                    details: nil
                )
            )
            return
        }

        stopScheduledRestart()

        if audioEngine.isRunning || recognitionTask != nil || recognitionRequest != nil {
            teardownRecognitionTaskOnly(cancelTask: true)
            deactivateAudioSession()
        }

        selectedSpeechEngine = .sfSpeechRecognizer
        currentLocale = localeIdentifier
        currentMode = mode
        keepListening = true
        isStoppingGracefully = false
        committedTranscript = ""

        let locale = Locale(identifier: localeIdentifier)
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            complete(
                result,
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
            complete(
                result,
                FlutterError(
                    code: "recognizer_not_available",
                    message: "Speech recognizer is not available right now.",
                    details: nil
                )
            )
            return
        }

        if mode == .requireOnDevice && !recognizer.supportsOnDeviceRecognition {
            complete(
                result,
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

            emitListening(true)
            complete(result, true)
        } catch {
            keepListening = false
            isStoppingGracefully = false
            committedTranscript = ""

            emitError(
                code: "ios_start_failed",
                message: error.localizedDescription,
                details: (error as NSError).userInfo
            )

            complete(
                result,
                FlutterError(
                    code: "ios_start_failed",
                    message: error.localizedDescription,
                    details: (error as NSError).userInfo
                )
            )
        }
    }

    private func stopRecognition() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.stopRecognition()
            }
            return
        }

        keepListening = false
        isStoppingGracefully = true
        stopScheduledRestart()

        guard recognitionTask != nil || audioEngine.isRunning || recognitionRequest != nil else {
            emitListening(false)
            isStoppingGracefully = false
            return
        }

        recognitionRequest?.endAudio()

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        emitListening(false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.finishStopIfNeeded()
        }
    }

    private func cancelRecognition() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.cancelRecognition()
            }
            return
        }

        keepListening = false
        isStoppingGracefully = false
        committedTranscript = ""
        stopScheduledRestart()

        recognitionTask?.cancel()
        teardownRecognitionTaskOnly(cancelTask: false)
        deactivateAudioSession()
        emitListening(false)
    }

    private func disposeRecognition() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.disposeRecognition()
            }
            return
        }

        keepListening = false
        isStoppingGracefully = false
        committedTranscript = ""
        stopScheduledRestart()

        recognitionTask?.cancel()
        teardownRecognitionTaskOnly(cancelTask: false)
        deactivateAudioSession()
        emitListening(false)
    }

    private func finishStopIfNeeded() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.finishStopIfNeeded()
            }
            return
        }

        teardownRecognitionTaskOnly(cancelTask: false)
        deactivateAudioSession()
        isStoppingGracefully = false
    }

    private func teardownRecognitionTaskOnly(cancelTask: Bool) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.teardownRecognitionTaskOnly(cancelTask: cancelTask)
            }
            return
        }

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
        audioEngine.reset()
    }

    private func stopScheduledRestart() {
        isRestartScheduled = false
    }

    // MARK: - Legacy speech helpers

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

        if right == left { return left }
        if right.hasPrefix(left) { return right }

        return "\(left)\n\(right)"
    }

    private func friendlySpeechErrorMessage(_ error: Error) -> String {
        let nsError = error as NSError

        if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 203 {
            return "Speech recognition could not start correctly. Please try again."
        }

        if nsError.domain == "SiriSpeechErrorDomain", nsError.code == 102 {
            return "Speech service returned corrupt audio/session state. Please try again."
        }

        if nsError.domain == "SiriSpeechErrorDomain", nsError.code == 1 {
            return "Speech recognition is temporarily unavailable."
        }

        return error.localizedDescription
    }

    private func audioRouteSnapshot() -> [String: Any] {
        let session = AVAudioSession.sharedInstance()
        let route = session.currentRoute

        return [
            "category": session.category.rawValue,
            "mode": session.mode.rawValue,
            "sampleRate": session.sampleRate,
            "inputAvailable": session.isInputAvailable,
            "inputs": route.inputs.map { [
                "portName": $0.portName,
                "portType": $0.portType.rawValue,
                "channels": $0.channels?.count ?? 0
            ]},
            "outputs": route.outputs.map { [
                "portName": $0.portName,
                "portType": $0.portType.rawValue,
                "channels": $0.channels?.count ?? 0
            ]}
        ]
    }

    // MARK: - Legacy audio session

    private func startAudioSession(
        with recognizer: SFSpeechRecognizer,
        mode: RecognitionMode
    ) throws {
        teardownRecognitionTaskOnly(cancelTask: true)

        let audioSession = AVAudioSession.sharedInstance()

        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])

        do {
            try audioSession.setPreferredSampleRate(48000)
        } catch {
            // Ignore and use system default.
        }

        do {
            try audioSession.setPreferredInputNumberOfChannels(1)
        } catch {
            // Ignore and use available hardware default.
        }

        try audioSession.setActive(true, options: [])

        guard audioSession.isInputAvailable else {
            throw NSError(
                domain: "emma.stt.audio",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Microphone input is not available.",
                    "route": audioRouteSnapshot()
                ]
            )
        }

        let currentRouteInputs = audioSession.currentRoute.inputs
        guard !currentRouteInputs.isEmpty else {
            throw NSError(
                domain: "emma.stt.audio",
                code: 1002,
                userInfo: [
                    NSLocalizedDescriptionKey: "No active microphone route is available.",
                    "route": audioRouteSnapshot()
                ]
            )
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.requiresOnDeviceRecognition = shouldRequireOnDevice(
            recognizer: recognizer,
            mode: mode
        )

        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
        }

        recognitionRequest = request

        audioEngine.stop()
        audioEngine.reset()

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let hardwareInputFormat = inputNode.inputFormat(forBus: 0)

        let resolvedFormat: AVAudioFormat
        if hardwareInputFormat.sampleRate > 0 && hardwareInputFormat.channelCount > 0 {
            resolvedFormat = hardwareInputFormat
        } else {
            let sessionSampleRate = audioSession.sampleRate > 0 ? audioSession.sampleRate : 48000

            guard let fallbackFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sessionSampleRate,
                channels: 1,
                interleaved: false
            ) else {
                throw NSError(
                    domain: "emma.stt.audio",
                    code: 1003,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Could not create fallback input format.",
                        "route": audioRouteSnapshot()
                    ]
                )
            }

            resolvedFormat = fallbackFormat
        }

        guard resolvedFormat.sampleRate > 0, resolvedFormat.channelCount > 0 else {
            throw NSError(
                domain: "emma.stt.audio",
                code: 1004,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Invalid input format. sampleRate=\(resolvedFormat.sampleRate), channels=\(resolvedFormat.channelCount)",
                    "route": audioRouteSnapshot()
                ]
            )
        }

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: resolvedFormat
        ) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
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
                        self.emitListening(false)
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

                    let nsError = error as NSError
                    let domain = nsError.domain
                    let code = nsError.code

                    self.emitError(
                        code: "ios_runtime_error_\(domain)_\(code)",
                        message: self.friendlySpeechErrorMessage(error),
                        details: nsError.userInfo
                    )

                    self.keepListening = false
                    self.teardownRecognitionTaskOnly(cancelTask: false)
                    self.finishStopIfNeeded()
                }
            }
        }
    }

    private func scheduleRestartIfNeeded() {
        guard keepListening else { return }
        guard !isRestartScheduled else { return }

        isRestartScheduled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }

            guard self.keepListening else {
                self.isRestartScheduled = false
                return
            }

            self.isRestartScheduled = false

            if self.audioEngine.isRunning || self.recognitionTask != nil || self.recognitionRequest != nil {
                return
            }

            let locale = Locale(identifier: self.currentLocale)
            guard let recognizer = SFSpeechRecognizer(locale: locale) else {
                self.emitError(
                    code: "recognizer_unavailable",
                    message: "Cannot create speech recognizer for locale \(self.currentLocale)."
                )
                self.keepListening = false
                return
            }

            recognizer.delegate = self

            guard recognizer.isAvailable else {
                self.emitError(
                    code: "recognizer_not_available",
                    message: "Speech recognizer is not available right now."
                )
                self.keepListening = false
                return
            }

            if self.currentMode == .requireOnDevice && !recognizer.supportsOnDeviceRecognition {
                self.emitError(
                    code: "on_device_unavailable",
                    message: "On-device speech recognition became unavailable."
                )
                self.keepListening = false
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

                self.emitListening(true)
            } catch {
                self.emitError(
                    code: "ios_restart_failed",
                    message: error.localizedDescription,
                    details: (error as NSError).userInfo
                )
                self.keepListening = false
                self.finishStopIfNeeded()
            }
        }
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Notifications

    private func registerAudioNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        if selectedSpeechEngine == .speechAnalyzer {
            emitListening(false)
            return
        }

        guard
            let userInfo = notification.userInfo,
            let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else {
            return
        }

        switch type {
        case .began:
            emitListening(false)

        case .ended:
            let rawOptions = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)

            if keepListening && options.contains(.shouldResume) {
                teardownRecognitionTaskOnly(cancelTask: true)
                deactivateAudioSession()
                scheduleRestartIfNeeded()
            }

        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        if selectedSpeechEngine == .speechAnalyzer {
            emitListening(false)
            return
        }

        guard
            let userInfo = notification.userInfo,
            let rawReason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason)
        else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable, .newDeviceAvailable, .routeConfigurationChange:
            emitListening(false)

            if keepListening {
                teardownRecognitionTaskOnly(cancelTask: true)
                deactivateAudioSession()
                scheduleRestartIfNeeded()
            }

        default:
            break
        }
    }

    // MARK: - Delegate

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        guard selectedSpeechEngine == .sfSpeechRecognizer else {
            return
        }

        emit([
            "type": "availability",
            "available": available,
            "onDevice": speechRecognizer.supportsOnDeviceRecognition
        ])
    }

    // MARK: - Event channel

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}