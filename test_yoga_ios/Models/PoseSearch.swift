//
//  PoseSearch.swift
//  test_yoga_ios
//

import Foundation

/// Finds poses by English or Sanskrit name, forgiving the ways people actually type:
/// any case, accents, hyphens and punctuation ("knees chest chin" finds Knees-Chest-Chin),
/// words in any order, numbers for Roman numerals ("warrior 2"), the different ways Sanskrit
/// is spelled in English letters ("shirshasana" finds Sirsasana), and small typos ("warrier")
enum PoseSearch {

    /// Poses matching `query`, best matches first; every pose when there's nothing to search for
    static func results(for query: String, in poses: [Pose]) -> [Pose] {
        let queryWords = words(in: query)
        guard !queryWords.isEmpty else { return poses }

        let names = poses.map(names(of:))
        var search = Search(queryWords: queryWords, library: names)

        return zip(poses, names).enumerated()
            .compactMap { index, entry -> (pose: Pose, score: Int, length: Int, index: Int)? in
                guard let score = search.score(of: entry.1) else { return nil }
                return (entry.0, score, entry.0.nameEnglish.count + entry.0.nameSanskrit.count, index)
            }
            // Among equally good matches, shorter names are closer to what was typed
            .sorted { ($0.score, $0.length, $0.index) < ($1.score, $1.length, $1.index) }
            .map(\.pose)
    }

    /// Names already broken into words, since search runs on every keystroke
    private static var namesCache: [String: Names] = [:]

    private static func names(of pose: Pose) -> Names {
        let key = pose.nameEnglish + "\n" + pose.nameSanskrit
        if let names = namesCache[key] { return names }
        let names = Names(pose)
        namesCache[key] = names
        return names
    }

    /// Comparing by Sanskrit sound only from this many letters, since short English words
    /// can sound like Sanskrit ("tree" like "tri")
    private static let minimumSoundLength = 6

    /// A pose's names, broken into words to compare
    private struct Names {
        /// English and Sanskrit words
        let words: [String]
        /// Each name run together, without spaces or punctuation
        let compact: [String]
        /// The Sanskrit words, and the Sanskrit name run together, by how they sound
        let sanskritSounds: [String]
        let compactSanskritSound: String

        init(_ pose: Pose) {
            let english = PoseSearch.words(in: pose.nameEnglish)
            let sanskrit = PoseSearch.words(in: pose.nameSanskrit)
            words = english + sanskrit
            compact = [english.joined(), sanskrit.joined()]
            sanskritSounds = sanskrit.map(PoseSearch.sound(of:))
            compactSanskritSound = PoseSearch.sound(of: sanskrit.joined())
        }
    }

    private struct Search {
        let queryWords: [String]
        /// The sound of each search word, or nil when it's too short to compare by sound
        let querySounds: [String?]
        let compactQuery: String
        let compactQuerySound: String?
        /// Search words found somewhere in the library, as typed or by sound, are spelled the way the library
        /// spells them, so they get fewer typos (otherwise "pose" would also find "Paschimottanasana"): none
        /// for short words, one for long ones since the library itself spells some Sanskrit more than one way
        let correctlySpelled: Set<String>
        /// Typos between a search word and a library word, worked out once per pair
        private var typoCache: [String: [String: Int?]] = [:]

        init(queryWords: [String], library: [Names]) {
            self.queryWords = queryWords
            querySounds = queryWords.map { $0.count >= PoseSearch.minimumSoundLength ? PoseSearch.sound(of: $0) : nil }
            compactQuery = queryWords.joined()
            compactQuerySound = compactQuery.count >= PoseSearch.minimumSoundLength ? PoseSearch.sound(of: compactQuery) : nil
            let vocabulary = Set(library.flatMap(\.words))
            let sounds = Set(library.flatMap(\.sanskritSounds))
            correctlySpelled = Set(zip(queryWords, querySounds)
                .filter { word, sound in
                    vocabulary.contains { PoseSearch.word($0, matches: word) } ||
                        sound.map { sound in sounds.contains { $0.contains(sound) } } == true
                }
                .map(\.0))
        }

        /// Lower is a better match, nil is no match: 0 when a name starts with the search, 1 when a name
        /// contains it, and from 2 when every search word is in the names in some order, plus 1 per typo
        mutating func score(of names: Names) -> Int? {
            if names.compact.contains(where: { $0.hasPrefix(compactQuery) }) ||
                compactQuerySound.map(names.compactSanskritSound.hasPrefix) == true { return 0 }
            if names.compact.contains(where: { $0.contains(compactQuery) }) ||
                compactQuerySound.map(names.compactSanskritSound.contains) == true { return 1 }

            var totalTypos = 0
            for (queryWord, querySound) in zip(queryWords, querySounds) {
                if names.words.contains(where: { PoseSearch.word($0, matches: queryWord) }) { continue }
                if let querySound, names.sanskritSounds.contains(where: { $0.contains(querySound) }) { continue }
                let limit = correctlySpelled.contains(queryWord)
                    ? (queryWord.count >= 8 ? 1 : 0)
                    : PoseSearch.allowedTypos(in: queryWord)
                var candidates = names.words.compactMap { typos(between: queryWord, and: $0, limit: limit) }
                if let querySound {
                    candidates += names.sanskritSounds.compactMap { typos(between: querySound, and: $0, limit: limit) }
                }
                guard let fewest = candidates.min() else { return nil }
                totalTypos += fewest
            }
            return 2 + totalTypos
        }

        private mutating func typos(between queryWord: String, and word: String, limit: Int) -> Int? {
            if let known = typoCache[queryWord]?[word] { return known }
            let typos = PoseSearch.typos(Array(queryWord), startOf: Array(word), limit: limit)
            typoCache[queryWord, default: [:]][word] = typos
            return typos
        }
    }

    /// Whether a name word contains a search word. One or two letters ("ii") only count at the start of a word
    private static func word(_ word: String, matches queryWord: String) -> Bool {
        queryWord.count <= 2 ? word.hasPrefix(queryWord) : word.contains(queryWord)
    }

    /// Short words must be typed exactly, or nearly every pose would match
    private static func allowedTypos(in word: String) -> Int {
        switch word.count {
        case ..<4: 0
        case ..<8: 1
        default: 2
        }
    }

    /// Pose names number their variations with Roman numerals
    private static let romanNumerals = ["1": "i", "2": "ii", "3": "iii", "4": "iv"]

    /// Lowercase words without accents or punctuation; "Runner's Lunge" → ["runners", "lunge"]
    private static func words(in text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { romanNumerals[String($0)] ?? String($0) }
    }

    private static let vowels: Set<Character> = ["a", "e", "i", "o", "u"]

    /// A Sanskrit word as it sounds, so the different ways of writing it in English letters match:
    /// Shirshasana and Sirsasana, Vrikshasana and Vrksasana, Utthita and Uttita, Pawan and Pavan
    private static func sound(of word: String) -> String {
        let letters = Array(word
            .replacingOccurrences(of: "w", with: "v")
            .replacingOccurrences(of: "ee", with: "i")
            .replacingOccurrences(of: "oo", with: "u"))
        var sound: [Character] = []
        for (index, letter) in letters.enumerated() {
            let previous = sound.last
            // The h in sh, ch, th, dh, bh, kh, ph, gh and jh
            if letter == "h", let previous, !vowels.contains(previous) { continue }
            // The i in "ri" before a consonant, which some spellings leave out: Parivritta, Parivrtta
            if letter == "i", previous == "r", index + 1 < letters.count, !vowels.contains(letters[index + 1]) { continue }
            // Doubled letters: Uttanasana, Utanasana
            if letter == previous { continue }
            sound.append(letter)
        }
        return String(sound)
    }

    /// The fewest typos (a missing, extra, wrong, or swapped letter each count as one) between
    /// `query` and the start of `word`, since the rest of the word may not have been typed yet.
    /// Nil when there are more than `limit`
    private static func typos(_ query: [Character], startOf word: [Character], limit: Int) -> Int? {
        guard limit > 0, !query.isEmpty, !word.isEmpty, word.count >= query.count - limit else { return nil }
        // Rows of the table: row i holds the typos between the first i letters of the query
        // and the first j letters of the word, for each j
        var twoBack = [Int](repeating: 0, count: word.count + 1)
        var previous = Array(0...word.count)
        var current = [Int](repeating: 0, count: word.count + 1)
        for i in 1...query.count {
            current[0] = i
            for j in 1...word.count {
                let wrong = query[i - 1] == word[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + wrong)
                if i > 1, j > 1, query[i - 1] == word[j - 2], query[i - 2] == word[j - 1] {
                    current[j] = min(current[j], twoBack[j - 2] + 1)
                }
            }
            // Typos only add up from here, so stop once every way through is over the limit
            guard let fewest = current.min(), fewest <= limit else { return nil }
            (twoBack, previous, current) = (previous, current, twoBack)
        }
        return previous.min()
    }
}
