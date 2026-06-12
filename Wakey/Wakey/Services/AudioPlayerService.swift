import Foundation
import AVFoundation
import Combine

final class AudioPlayerService: ObservableObject {
    @Published var isPlaying = false
    @Published var message: String?

    private var player: AVAudioPlayer?
    var currentTime: TimeInterval {
        player?.currentTime ?? 0
    }

    var duration: TimeInterval {
        player?.duration ?? 0
    }

    var volume: Float = 0.8 {
        didSet {
            player?.volume = volume
        }
    }

    func play(url: URL?) {
        guard let url else {
            message = "재생할 오디오가 아직 없어요."
            return
        }

        do {
            if player?.url == url {
                player?.play()
            } else {
                player = try AVAudioPlayer(contentsOf: url)
                player?.volume = volume
                player?.prepareToPlay()
                player?.play()
            }
            isPlaying = true
            message = nil
        } catch {
            isPlaying = false
            message = "오디오를 재생하지 못했어요."
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func toggle(url: URL?) {
        if isPlaying {
            pause()
        } else {
            play(url: url)
        }
    }
}
