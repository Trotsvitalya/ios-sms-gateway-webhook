import Foundation
import AVFoundation
import UIKit

public class BackgroundKeeper {
    public static let shared = BackgroundKeeper()
    private var audioPlayer: AVAudioPlayer?
    private var bgTaskId: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    public func start() {
        setupAudioSession()
        playSilentSound()
        startBackgroundTask()
    }

    public func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        endBackgroundTask()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Помилка налаштування AVAudioSession: \(error)")
        }
    }

    private func playSilentSound() {
        let wavData = createSilentWav()
        do {
            audioPlayer = try AVAudioPlayer(data: wavData)
            audioPlayer?.numberOfLoops = -1 // Нескінченний повтор
            audioPlayer?.volume = 0.01 // Мінімальна гучність
            audioPlayer?.play()
        } catch {
            print("Помилка відтворення silent sound: \(error)")
        }
    }

    private func startBackgroundTask() {
        if bgTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(bgTaskId)
        }
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "SMSGatewayBackground") { [weak self] in
            self?.startBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if bgTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(bgTaskId)
            bgTaskId = .invalid
        }
    }

    /// Повертає валідний 44-байтний WAV файл (PCM 44.1kHz, 16-bit Mono) з 1 секундою тиші
    private func createSilentWav() -> Data {
        let header: [UInt8] = [
            0x52, 0x49, 0x46, 0x46, // "RIFF"
            0x24, 0x58, 0x01, 0x00, // Chunk size: 88236 bytes
            0x57, 0x41, 0x56, 0x45, // "WAVE"
            0x66, 0x6d, 0x74, 0x20, // "fmt "
            0x10, 0x00, 0x00, 0x00, // Subchunk1Size (16 bytes)
            0x01, 0x00,             // AudioFormat (1 = PCM)
            0x01, 0x00,             // NumChannels (1 = Mono)
            0x44, 0xac, 0x00, 0x00, // SampleRate (44100 Hz)
            0x88, 0x58, 0x01, 0x00, // ByteRate (88200 B/s)
            0x02, 0x00,             // BlockAlign (2 bytes)
            0x10, 0x00,             // BitsPerSample (16 bits)
            0x64, 0x61, 0x74, 0x61, // "data"
            0x00, 0x58, 0x01, 0x00  // Subchunk2Size (88200 bytes)
        ]
        var data = Data(header)
        data.append(Data(repeating: 0, count: 88200))
        return data
    }
}
