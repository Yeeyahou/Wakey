import Foundation
import AVFoundation

struct AudioFileService {
    func createShortNotificationAudio(from sourceURL: URL, alarmId: UUID) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let soundsDirectory = try Self.librarySoundsDirectory()
            let destination = soundsDirectory.appendingPathComponent("alarm_\(alarmId.uuidString).caf")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }

            // iOS local notification custom sounds must be short and stored in Library/Sounds.
            // They cannot play a full background MP3 like a traditional alarm app.
            // This converts the first 28 seconds into a CAF file when AVFoundation can decode the source.
            let inputFile = try AVAudioFile(forReading: sourceURL)
            let format = inputFile.processingFormat
            let maxFrames = AVAudioFramePosition(format.sampleRate * 28.0)
            let framesToRead = min(inputFile.length, maxFrames)
            let outputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: format.channelCount,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
            let outputFile = try AVAudioFile(forWriting: destination, settings: outputSettings)

            let bufferFrameCapacity: AVAudioFrameCount = 4096
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferFrameCapacity) else {
                throw AudioError.conversionFailed
            }

            var remaining = framesToRead
            while remaining > 0 {
                let count = min(bufferFrameCapacity, AVAudioFrameCount(remaining))
                try inputFile.read(into: buffer, frameCount: count)
                if buffer.frameLength == 0 { break }
                try outputFile.write(from: buffer)
                remaining -= AVAudioFramePosition(buffer.frameLength)
            }

            return destination
        }.value
    }

    nonisolated static func librarySoundsDirectory() throws -> URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let sounds = library.appendingPathComponent("Sounds", isDirectory: true)
        try FileManager.default.createDirectory(at: sounds, withIntermediateDirectories: true)
        return sounds
    }

    enum AudioError: LocalizedError {
        case conversionFailed

        var errorDescription: String? {
            "알림용 오디오 파일을 만들지 못했습니다."
        }
    }
}
