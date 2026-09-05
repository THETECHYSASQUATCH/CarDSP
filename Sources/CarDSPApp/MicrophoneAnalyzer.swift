import Foundation
import AVFoundation
import SwiftUI

@MainActor
public final class MicrophoneAnalyzer: ObservableObject {
    private let engine = AVAudioEngine()

    @Published public private(set) var isRunning = false
    @Published public private(set) var status = "Mic idle"
    @Published public private(set) var bands: [RTAFrequencyBand] = []

    public init() {}

    public func start() throws {
        try AudioSessionController.shared.configure()

        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            guard let channelData = buffer.floatChannelData else { return }
            let frameCount = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))
            let sampleRate = Float(buffer.format.sampleRate)
            let measured = RTAAnalyzer.measure(from: samples, sampleRate: sampleRate)

            DispatchQueue.main.async {
                self.bands = measured
                self.status = "Analyzing microphone"
            }
        }

        try engine.start()
        isRunning = true
        status = "Analyzing microphone"
    }

    public func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        status = "Mic idle"
        bands = []
    }
}
