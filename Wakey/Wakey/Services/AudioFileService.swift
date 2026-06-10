import Foundation
import AVFoundation

struct AudioFileService {
    static let supportedAlarmSoundExtensions = ["wav", "caf", "aiff", "aif"]

    static func bundledAlarmSoundURLs() -> [URL] {
        let nestedURLs = supportedAlarmSoundExtensions.flatMap { fileExtension in
            Bundle.main.urls(forResourcesWithExtension: fileExtension, subdirectory: "AlarmSounds") ?? []
        }
        let rootURLs = supportedAlarmSoundExtensions.flatMap { fileExtension in
            Bundle.main.urls(forResourcesWithExtension: fileExtension, subdirectory: nil) ?? []
        }
        let urls = nestedURLs.isEmpty ? rootURLs : nestedURLs
        return urls.sorted { $0.deletingPathExtension().lastPathComponent.localizedStandardCompare($1.deletingPathExtension().lastPathComponent) == .orderedAscending }
    }

    func copyBundledAlarmSoundToLibrary(fileName: String) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let resourceName = (fileName as NSString).deletingPathExtension
            let resourceExtension = (fileName as NSString).pathExtension
            guard let source = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension, subdirectory: "AlarmSounds")
                ?? Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
                throw AudioError.soundNotFound
            }
            let destination = try Self.librarySoundsDirectory().appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            return destination
        }.value
    }

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
        case soundNotFound
        case conversionFailed

        var errorDescription: String? {
            switch self {
            case .soundNotFound:
                "알림 사운드 파일을 찾지 못했습니다."
            case .conversionFailed:
                "알림용 오디오 파일을 만들지 못했습니다."
            }
        }
    }
}
