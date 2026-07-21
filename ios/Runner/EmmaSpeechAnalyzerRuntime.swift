import UIKit
import AVFoundation
import Flutter
import Speech

@available(iOS 26.0, *)
final class EmmaSpeechAnalyzerRuntime {
    enum PrivacyMode: String {
        case transcriptOnly
        case temporaryAudioForSpeakerSeparation
        case retainedAudioArchive
    }

    enum CaptureProfile: String {
        case dictation
        case meeting
    }

    private let audioEngine = AVAudioEngine()

    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var analyzerFormat: AVAudioFormat?
    private var resultTask: Task<Void, Never>?

    private var emitHandler: (([String: Any]) -> Void)?
    private var isListening = false
    private var currentLocale = "en-US"
    private var currentPrivacyMode: PrivacyMode = .transcriptOnly
    private var currentCaptureProfile: CaptureProfile = .dictation

    private var audioFile: AVAudioFile?
    private var recordingURL: URL?

    private var currentAudioSessionModeName = "measurement"
    private var currentPreferredInputName = ""
    private var currentPreferredDataSourceName = ""
    private var currentPreferredPolarPatternName = ""
    private var currentStereoOrientationName = ""
    private var usingStereoInput = false

    func capabilities(
        localeIdentifier: String,
        permissionGranted: Bool
    ) async -> [String: Any] {
        let locale = Locale(identifier: localeIdentifier)
        let supported = await SpeechTranscriber.supportedLocales
        let installed = await Set(SpeechTranscriber.installedLocales)

        let localeSupported = supported.contains(where: { self.sameLocale($0, locale) })
        let localeInstalled = installed.contains(where: { self.sameLocale($0, locale) })

        return [
            "platform": "ios",
            "available": SpeechTranscriber.isAvailable && localeSupported,
            "onDeviceAvailable": SpeechTranscriber.isAvailable && localeSupported,
            "permissionGranted": permissionGranted,
            "locale": localeIdentifier,
            "engine": "speechAnalyzer",
            "speechAnalyzerAvailable": SpeechTranscriber.isAvailable,
            "speechAnalyzerLocaleSupported": localeSupported,
            "speechAnalyzerLocaleInstalled": localeInstalled,
            "supportsMeetingMode": true,
            "supportsTemporaryAudioCapture": true,
            "supportsSpeakerDiarization": false
        ]
    }

    func snapshot() -> [String: Any] {
        [
            "platform": "ios",
            "engine": "speechAnalyzer",
            "locale": currentLocale,
            "isListening": isListening,
            "hasAnalyzer": analyzer != nil,
            "hasTranscriber": transcriber != nil,
            "hasAnalyzerFormat": analyzerFormat != nil,
            "hasInputContinuation": inputContinuation != nil,
            "audioEngineRunning": audioEngine.isRunning,
            "privacyMode": currentPrivacyMode.rawValue,
            "captureProfile": currentCaptureProfile.rawValue,
            "audioRecordingEnabled": currentPrivacyMode != .transcriptOnly,
            "recordingURL": recordingURL?.path ?? "",
            "audioSessionMode": currentAudioSessionModeName,
            "preferredInputName": currentPreferredInputName,
            "preferredDataSourceName": currentPreferredDataSourceName,
            "preferredPolarPatternName": currentPreferredPolarPatternName,
            "stereoOrientation": currentStereoOrientationName,
            "usingStereoInput": usingStereoInput
        ]
    }

    func start(
        localeIdentifier: String,
        captureProfileRaw: String,
        privacyModeRaw: String,
        permissionGranted: Bool,
        emit: @escaping ([String: Any]) -> Void,
        result: @escaping FlutterResult
    ) {
        Task { @MainActor in
            do {
                guard permissionGranted else {
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
                currentCaptureProfile = CaptureProfile(rawValue: captureProfileRaw) ?? .dictation
                currentPrivacyMode = PrivacyMode(rawValue: privacyModeRaw) ?? .transcriptOnly
                emitHandler = emit

                let locale = Locale(identifier: localeIdentifier)
                let transcriber = SpeechTranscriber(
                    locale: locale,
                    transcriptionOptions: [],
                    reportingOptions: [.volatileResults],
                    attributeOptions: [.audioTimeRange]
                )

                try await ensureModel(transcriber: transcriber, locale: locale)

                let analyzer = SpeechAnalyzer(modules: [transcriber])
                let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
                    compatibleWith: [transcriber]
                )

                let stream = AsyncStream<AnalyzerInput>.makeStream()
                let inputSequence = stream.stream
                let inputContinuation = stream.continuation

                self.transcriber = transcriber
                self.analyzer = analyzer
                self.analyzerFormat = analyzerFormat
                self.inputContinuation = inputContinuation

                try await analyzer.start(inputSequence: inputSequence)
                startResultLoop(transcriber: transcriber)
                try startAudioSessionAndTap()

                emit([
                    "type": "availability",
                    "available": true,
                    "onDevice": true
                ])

                emitListening(true)
                result(true)
            } catch {
                teardown(deleteTemporaryAudio: currentPrivacyMode == .temporaryAudioForSpeakerSeparation)

                result(
                    FlutterError(
                        code: "speech_analyzer_start_failed",
                        message: error.localizedDescription,
                        details: nil
                    )
                )
            }
        }
    }

    func stop() {
        Task { @MainActor in
            guard isListening else { return }

            isListening = false

            audioEngine.inputNode.removeTap(onBus: 0)
            if audioEngine.isRunning {
                audioEngine.stop()
            }

            inputContinuation?.finish()

            do {
                try await analyzer?.finalizeAndFinishThroughEndOfInput()
            } catch {
                emitError(
                    code: "speech_analyzer_finalize_failed",
                    message: error.localizedDescription
                )
            }

            finishAudioSession()
            emitListening(false)
        }
    }

    func cancel() {
        Task { @MainActor in
            isListening = false

            audioEngine.inputNode.removeTap(onBus: 0)
            if audioEngine.isRunning {
                audioEngine.stop()
            }

            inputContinuation?.finish()
            await analyzer?.cancelAndFinishNow()

            finishAudioSession()
            teardown(deleteTemporaryAudio: currentPrivacyMode == .temporaryAudioForSpeakerSeparation)
            emitListening(false)
        }
    }

    func dispose() {
        cancel()
    }

    // MARK: - Internals

    private func sameLocale(_ lhs: Locale, _ rhs: Locale) -> Bool {
        lhs.identifier
            .replacingOccurrences(of: "_", with: "-")
            .lowercased() ==
        rhs.identifier
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
    }

    private func ensureModel(
        transcriber: SpeechTranscriber,
        locale: Locale
    ) async throws {
        let supported = await SpeechTranscriber.supportedLocales
        let localeSupported = supported.contains(where: { sameLocale($0, locale) })

        guard localeSupported else {
            throw NSError(
                domain: "emma.stt.analyzer",
                code: 2001,
                userInfo: [
                    NSLocalizedDescriptionKey: "SpeechAnalyzer locale not supported: \(locale.identifier)"
                ]
            )
        }

        let installed = await Set(SpeechTranscriber.installedLocales)
        let localeInstalled = installed.contains(where: { sameLocale($0, locale) })

        if localeInstalled {
            return
        }

        if let downloader = try await AssetInventory.assetInstallationRequest(
            supporting: [transcriber]
        ) {
            try await downloader.downloadAndInstall()
        }
    }

    private func startResultLoop(transcriber: SpeechTranscriber) {
        resultTask?.cancel()

        resultTask = Task { [weak self] in
            guard let self else { return }

            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                        .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                    if text.isEmpty {
                        continue
                    }

                    if result.isFinal {
                        self.emit([
                            "type": "final",
                            "text": text,
                            "isFinal": true
                        ])
                    } else {
                        self.emit([
                            "type": "partial",
                            "text": text,
                            "isFinal": false
                        ])
                    }
                }
            } catch {
                await MainActor.run {
                    self.emitError(
                        code: "speech_analyzer_runtime_error",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private func startAudioSessionAndTap() throws {
        resetAudioSelectionMetadata()

        let session = AVAudioSession.sharedInstance()

        try session.setActive(false, options: .notifyOthersOnDeactivation)

        switch currentCaptureProfile {
        case .dictation:
            currentAudioSessionModeName = "measurement"
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            do { try session.setPreferredSampleRate(48_000) } catch {}
            do { try session.setPreferredInputNumberOfChannels(1) } catch {}

        case .meeting:
            currentAudioSessionModeName = "videoRecording"
            try session.setCategory(.record, mode: .videoRecording, options: [.duckOthers, .allowBluetooth])
            do { try session.setPreferredSampleRate(48_000) } catch {}
        }

        try session.setActive(true, options: [])

        if currentCaptureProfile == .meeting {
            try configureMeetingInput(session: session)
        }

        guard session.isInputAvailable else {
            throw NSError(
                domain: "emma.stt.audio",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Microphone input is not available."
                ]
            )
        }

        let currentRouteInputs = session.currentRoute.inputs
        guard !currentRouteInputs.isEmpty else {
            throw NSError(
                domain: "emma.stt.audio",
                code: 1002,
                userInfo: [
                    NSLocalizedDescriptionKey: "No active microphone route is available."
                ]
            )
        }

        audioEngine.stop()
        audioEngine.reset()

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let hardwareInputFormat = inputNode.inputFormat(forBus: 0)
        let resolvedTapFormat = try resolveTapFormat(
            session: session,
            hardwareInputFormat: hardwareInputFormat
        )

        try prepareAudioFileIfNeeded(format: resolvedTapFormat)

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: resolvedTapFormat
        ) { [weak self] buffer, _ in
            guard let self else { return }

            if let audioFile = self.audioFile {
                try? audioFile.write(from: buffer)
            }

            Task { @MainActor in
                do {
                    try self.feedAnalyzer(buffer: buffer)
                } catch {
                    self.emitError(
                        code: "speech_analyzer_feed_error",
                        message: error.localizedDescription
                    )
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }

    private func configureMeetingInput(session: AVAudioSession) throws {
        let wantsSavedAudio = currentPrivacyMode != .transcriptOnly
        let wantsStereo = wantsSavedAudio

        if let builtInMic = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
            currentPreferredInputName = builtInMic.portName

            do {
                try session.setPreferredInput(builtInMic)
            } catch {
                // Ignore and keep current route.
            }

            guard let dataSources = builtInMic.dataSources, !dataSources.isEmpty else {
                if wantsStereo {
                    do { try session.setPreferredInputNumberOfChannels(2) } catch {}
                    usingStereoInput = session.inputNumberOfChannels >= 2
                } else {
                    do { try session.setPreferredInputNumberOfChannels(1) } catch {}
                }
                return
            }

            let selectedSource = chooseMeetingDataSource(
                from: dataSources,
                wantsStereo: wantsStereo
            ) ?? dataSources.first

            if let selectedSource {
                currentPreferredDataSourceName = selectedSource.dataSourceName

                do {
                    try builtInMic.setPreferredDataSource(selectedSource)
                } catch {
                    // Ignore and keep system choice.
                }

                if wantsStereo,
                   selectedSource.supportedPolarPatterns?.contains(.stereo) == true {
                    do {
                        try selectedSource.setPreferredPolarPattern(.stereo)
                        currentPreferredPolarPatternName = "stereo"
                    } catch {
                        currentPreferredPolarPatternName = ""
                    }

                    do {
                        try session.setPreferredInputNumberOfChannels(2)
                    } catch {}

                    do {
                        let stereoOrientation = preferredStereoOrientation()
                        try session.setPreferredInputOrientation(stereoOrientation)
                        currentStereoOrientationName = "\(stereoOrientation)"
                    } catch {
                        currentStereoOrientationName = ""
                    }
                } else if selectedSource.supportedPolarPatterns?.contains(.cardioid) == true {
                    do {
                        try selectedSource.setPreferredPolarPattern(.cardioid)
                        currentPreferredPolarPatternName = "cardioid"
                    } catch {
                        currentPreferredPolarPatternName = ""
                    }

                    do { try session.setPreferredInputNumberOfChannels(1) } catch {}
                } else {
                    do { try session.setPreferredInputNumberOfChannels(1) } catch {}
                }
            }
        } else {
            if wantsStereo {
                do { try session.setPreferredInputNumberOfChannels(2) } catch {}
            } else {
                do { try session.setPreferredInputNumberOfChannels(1) } catch {}
            }
        }

        usingStereoInput = session.inputNumberOfChannels >= 2
    }

    private func chooseMeetingDataSource(
        from sources: [AVAudioSessionDataSourceDescription],
        wantsStereo: Bool
    ) -> AVAudioSessionDataSourceDescription? {
        func score(_ source: AVAudioSessionDataSourceDescription) -> Int {
            var value = 0

            if wantsStereo, source.supportedPolarPatterns?.contains(.stereo) == true {
                value += 100
            }

            if !wantsStereo, source.supportedPolarPatterns?.contains(.cardioid) == true {
                value += 90
            }

            switch source.orientation {
            case .front:
                value += 40
            case .back:
                value += 35
            case .top:
                value += 25
            case .bottom:
                value += 10
            default:
                break
            }

            switch source.location {
            case .upper:
                value += 20
            case .lower:
                value += 5
            default:
                break
            }

            return value
        }

        return sources.max(by: { score($0) < score($1) })
    }

    private func preferredStereoOrientation() -> AVAudioSession.StereoOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .portrait:
            return .portrait
        default:
            return .portrait
        }
    }

    private func resolveTapFormat(
        session: AVAudioSession,
        hardwareInputFormat: AVAudioFormat
    ) throws -> AVAudioFormat {
        if hardwareInputFormat.sampleRate > 0 && hardwareInputFormat.channelCount > 0 {
            return hardwareInputFormat
        }

        let preferredSampleRate = session.sampleRate > 0 ? session.sampleRate : 48_000
        let preferredChannels: AVAudioChannelCount = usingStereoInput ? 2 : 1

        guard let fallbackFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: preferredSampleRate,
            channels: preferredChannels,
            interleaved: false
        ) else {
            throw NSError(
                domain: "emma.stt.audio",
                code: 1003,
                userInfo: [
                    NSLocalizedDescriptionKey: "Could not create fallback input format."
                ]
            )
        }

        return fallbackFormat
    }

    private func prepareAudioFileIfNeeded(format: AVAudioFormat) throws {
        audioFile = nil
        recordingURL = nil

        guard currentPrivacyMode != .transcriptOnly else {
            return
        }

        let baseURL: URL
        switch currentPrivacyMode {
        case .transcriptOnly:
            return
        case .temporaryAudioForSpeakerSeparation:
            baseURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        case .retainedAudioArchive:
            baseURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        }

        let fileURL = baseURL.appendingPathComponent(
            "emma_meeting_\(UUID().uuidString).caf"
        )

        audioFile = try AVAudioFile(
            forWriting: fileURL,
            settings: format.settings
        )
        recordingURL = fileURL
    }

    private func feedAnalyzer(buffer: AVAudioPCMBuffer) throws {
        guard let analyzerFormat, let inputContinuation else {
            return
        }

        let converted = try convertBuffer(buffer, to: analyzerFormat)
        let input = AnalyzerInput(buffer: converted)
        inputContinuation.yield(input)
    }

    private func convertBuffer(
        _ buffer: AVAudioPCMBuffer,
        to outputFormat: AVAudioFormat
    ) throws -> AVAudioPCMBuffer {
        let sameSampleRate = buffer.format.sampleRate == outputFormat.sampleRate
        let sameChannels = buffer.format.channelCount == outputFormat.channelCount
        let sameCommonFormat = buffer.format.commonFormat == outputFormat.commonFormat

        if sameSampleRate && sameChannels && sameCommonFormat {
            return buffer
        }

        guard let converter = AVAudioConverter(from: buffer.format, to: outputFormat) else {
            throw NSError(
                domain: "emma.stt.analyzer",
                code: 2002,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create AVAudioConverter."
                ]
            )
        }

        let ratio = outputFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(
            max(1024, Double(buffer.frameLength) * ratio + 32)
        )

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: capacity
        ) else {
            throw NSError(
                domain: "emma.stt.analyzer",
                code: 2003,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to allocate output buffer."
                ]
            )
        }

        var providedInput = false
        var conversionError: NSError?

        let status = converter.convert(
            to: outputBuffer,
            error: &conversionError
        ) { _, outStatus in
            if providedInput {
                outStatus.pointee = .endOfStream
                return nil
            }

            providedInput = true
            outStatus.pointee = .haveData
            return buffer
        }

        if status == .error, let conversionError {
            throw conversionError
        }

        return outputBuffer
    }

    private func finishAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    private func teardown(deleteTemporaryAudio: Bool) {
        resultTask?.cancel()
        resultTask = nil

        analyzer = nil
        transcriber = nil
        inputContinuation = nil
        analyzerFormat = nil
        emitHandler = nil
        isListening = false

        audioFile = nil

        if deleteTemporaryAudio, let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
            self.recordingURL = nil
        }
    }

    private func resetAudioSelectionMetadata() {
        currentAudioSessionModeName = ""
        currentPreferredInputName = ""
        currentPreferredDataSourceName = ""
        currentPreferredPolarPatternName = ""
        currentStereoOrientationName = ""
        usingStereoInput = false
    }

    private func emit(_ payload: [String: Any]) {
        emitHandler?(payload)
    }

    private func emitListening(_ listening: Bool) {
        emit([
            "type": "listening",
            "listening": listening
        ])
    }

    private func emitError(code: String, message: String) {
        emit([
            "type": "error",
            "code": code,
            "message": message
        ])
        emitListening(false)
    }
}