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
        // Генеруємо 1 секунду тиші у форматі WAV в пам'яті
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

    /// Створює 44-байтний заголовок та кілька мілісекунд тиші PCM WAV
    private func createSilentWav() -> Data {
        var data = Data()
        let sampleRate: Int32 = 44100
        let channels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = sampleRate * Int32(channels) * Int32(bitsPerSample / 8)
        let blockAlign = channels * (bitsPerSample / 8)
        let durationSeconds = 1
        let subchunk2Size = Int32(durationSeconds) * byteRate
        let chunkSize = 36 + subchunk2Size

        data.append("RIFF".data(using: .ascii)!)
        var chunkSizeLE = chunkSize.littleEndian
        data.append(Data(bytes: &chunkSizeLE, count: 4))
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        var subchunk1Size: Int32 = 16
        data.append(Data(bytes: &subchunk1Size.littleEndian, count: 4))
        var audioFormat: Int16 = 1
        data.append(Data(bytes: &audioFormat.littleEndian, count: 2))
        var numChannels = channels.littleEndian
        data.append(Data(bytes: &numChannels, count: 2))
        var sampleRateLE = sampleRate.littleEndian
        data.append(Data(bytes: &sampleRateLE, count: 4))
        var byteRateLE = byteRate.littleEndian
        data.append(Data(bytes: &byteRateLE, count: 4))
        var blockAlignLE = blockAlign.littleEndian
        data.append(Data(bytes: &blockAlignLE, count: 2))
        var bpsLE = bitsPerSample.littleEndian
        data.append(Data(bytes: &bpsLE, count: 2))
        data.append("data".data(using: .ascii)!)
        var subchunk2SizeLE = subchunk2Size.littleEndian
        data.append(Data(bytes: &subchunk2SizeLE, count: 4))

        // Заповнюємо нулями (тиша)
        let silence = [UInt8](repeating: 0, count: Int(subchunk2Size))
        data.append(contentsOf: silence)
        return data
    }
}
