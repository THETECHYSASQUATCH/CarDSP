import Foundation
import MusicKit
import SwiftUI

@MainActor
final class MusicPlaybackCoordinator: ObservableObject {
    @Published private(set) var authorization: MusicAuthorization.Status = .notDetermined
    @Published private(set) var status = "Not initialized"

    let player = ApplicationMusicPlayer.shared

    func requestAccess() async {
        authorization = await MusicAuthorization.request()
        status = "Authorization: \(authorization)"
    }

    func play(song: Song) async {
        do {
            player.queue = [song]
            try await player.play()
            status = "Playing \(song.title)"
        } catch {
            status = "Playback error: \(error.localizedDescription)"
        }
    }

    func pause() {
        player.pause()
        status = "Paused"
    }
}
