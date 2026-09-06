import Foundation
import AVFoundation
import SwiftUI
import CarDSPCore

@MainActor
final class MicrophoneAnalyzer: ObservableObject {
    private let engine = AVAudioEngine()

    @Published private(set) var isRunning = false
    @Published private(set) var status = "Mic idle"
    @Published private(set) var bands: [RTAFrequencyBand] = []

    func start() throws {
        try AudioSessionController.shared.configureForMeasurement()

        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        guard inputFormat.channelCount > 0 else {
            status = "No microphone input"
            return
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData else { return }
            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0 else { return }
            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))
            let sampleRate = Float(buffer.format.sampleRate)
            let measured = RTAAnalyzer.measure(from: samples, sampleRate: sampleRate)

            Task { @MainActor [weak self] in
                guard let self else { return }
                self.bands = measured
                self.status = "Analyzing microphone"
            }
        }

        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            status = "Microphone error: \(error.localizedDescription)"
            throw error
        }

        isRunning = true
        status = "Analyzing microphone"
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        status = "Mic idle"
        bands = []
        AudioSessionController.shared.deactivate()
    }
}
