//
//  Sounds.swift
//  SpellingBee
//
//  Created by Scott Haynie on 3/22/25.
//

import AudioToolbox
import OSLog

struct Sounds {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                        category: String(describing: Sounds.self))

    static let littlefarts = [Sound.fartlittle, Sound.fartcurly]
    static let bigfarts = [Sound.fartbig]
    static let littlewins = [Sound.selectClick, Sound.woohoo, Sound.yayfunny]
    static let bigwins = [Sound.yahoo, Sound.applause]

    enum Sound: String {
        case softClick = "mixkit-typewriter-soft-click-1125.wav"
        case selectClick = "mixkit-select-click-1109.wav"
        case fartlittle = "fart-83471.mp3"
        case fartbig = "fart-5-228245.m4a"
        case fartcurly = "fart-curly.m4a"
        case fartsqueak = "fart-squeak.m4a"
        case yayfunny = "funny-yay-6273.mp3"
        case woohoo = "woohoo.m4a"
        case yahoo = "yahoo.m4a"
        case applause = "crowd-applause-113728.mp3"
        case shuffle1 = "goopy-slime-24-229640-lower2.mp3"
        case erase1 = "woop.m4a"
    }

    static var soundIds: [Sound: SystemSoundID] = [:]
    static func playRandomSound(_ sounds: [Sound]) {
        if !sounds.isEmpty {
            playSound(sounds.randomElement()!)
        }
    }
    static func playSound(_ sound: Sound) {
        if let soundId = soundIds[sound] {
            AudioServicesPlaySystemSound(soundId)
        } else {
            guard let soundURL: CFURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "") as CFURL? else {
                logger.error("Cannot find sound: \(sound.rawValue)")
                return
            }
            var soundId: SystemSoundID = 0
            let osStatus = AudioServicesCreateSystemSoundID(soundURL, &soundId)
            if osStatus == kAudioServicesNoError {
                AudioServicesPlaySystemSound(soundId)
                soundIds[sound] = soundId
            } else {
                logger.error("Could not create system sound: \(soundURL)")
            }
        }
    }
}
