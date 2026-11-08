//
//  CueMarkdown.swift
//  test_yoga_ios
//

import Foundation

/// Custom cues are stored as Markdown, one cue per line, so bold and italic are kept wherever they're shown
enum CueMarkdown {
    struct Piece {
        var text: String
        var isBold = false
        var isItalic = false
    }

    private static let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)

    /// Characters that would otherwise be read as Markdown formatting
    private static let specialCharacters: Set<Character> = ["\\", "*", "_", "`", "~", "[", "]", "<"]

    static func attributedString(from cues: [String], separator: String) -> AttributedString {
        let markdown = cues.joined(separator: separator)
        return (try? AttributedString(markdown: markdown, options: options)) ?? AttributedString(markdown)
    }

    /// Pieces of one line of text, split by formatting
    static func pieces(from cue: String) -> [Piece] {
        let text = attributedString(from: [cue], separator: "")
        return text.runs.map { run in
            let intent = run.inlinePresentationIntent ?? []
            return Piece(
                text: String(text[run.range].characters),
                isBold: intent.contains(.stronglyEmphasized),
                isItalic: intent.contains(.emphasized)
            )
        }
    }

    /// Writes one line of formatted pieces as Markdown
    static func cue(from pieces: [Piece]) -> String {
        // Neighbouring pieces with the same formatting become one, so markers aren't repeated
        var merged: [Piece] = []
        for piece in pieces where !piece.text.isEmpty {
            if let last = merged.last, last.isBold == piece.isBold, last.isItalic == piece.isItalic {
                merged[merged.count - 1].text += piece.text
            } else {
                merged.append(piece)
            }
        }

        return merged.map { piece in
            guard piece.isBold || piece.isItalic else { return escaped(piece.text) }

            // Markdown emphasis can't start or end with a space, so keep spaces outside the markers
            let leading = piece.text.prefix(while: \.isWhitespace)
            let trailing = piece.text.reversed().prefix(while: \.isWhitespace)
            let core = piece.text.dropFirst(leading.count).dropLast(trailing.count)
            guard !core.isEmpty else { return escaped(piece.text) }

            let marker = piece.isBold && piece.isItalic ? "***" : piece.isBold ? "**" : "*"
            return leading + marker + escaped(core) + marker + String(trailing.reversed())
        }
        .joined()
    }

    private static func escaped(_ text: some StringProtocol) -> String {
        var result = ""
        for character in text {
            if specialCharacters.contains(character) {
                result.append("\\")
            }
            result.append(character)
        }
        return result
    }
}
