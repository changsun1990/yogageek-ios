//
//  CueEditorView.swift
//  test_yoga_ios
//

import SwiftUI
import CoreText

/// Cues can only store bold and italic, so the editor doesn't offer underline, colors, and so on
private struct CueAttributes: AttributeScope {
    let font: AttributeScopes.SwiftUIAttributes.FontAttribute
}

struct CueEditorView: View {
    let poseName: String
    @Binding var cues: [String]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.fontResolutionContext) private var fontResolutionContext
    @State private var text: AttributedString
    @State private var selection = AttributedTextSelection()
    @FocusState private var isFocused: Bool
    private let originalText: AttributedString

    private static let bullet = "• "

    init(poseName: String, defaultCues: [String], cues: Binding<[String]>) {
        self.poseName = poseName
        _cues = cues
        // With no cues of their own yet, start from the pose's library cues as a bulleted list
        let initialText = cues.wrappedValue.isEmpty
            ? AttributedString(defaultCues.map { Self.bullet + $0 }.joined(separator: "\n"))
            : Self.editableText(from: cues.wrappedValue)
        originalText = initialText
        _text = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $text, selection: $selection)
                .font(.body)
                .attributedTextFormattingDefinition(CueAttributes.self)
                .focused($isFocused)
                .padding(.horizontal)
                .overlay(alignment: .topLeading) {
                    if text.characters.isEmpty {
                        Text("Type your teaching cues, one per line.")
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.horizontal, 21)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: text) { oldText, _ in
                    continueBulletList(from: oldText)
                }
                .navigationTitle("Cues")
                .navigationSubtitle(poseName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            if hasChanges {
                                cues = markdownCues(from: text)
                            }
                            dismiss()
                        }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        let style = typingStyle
                        Toggle("Bold", systemImage: "bold", isOn: Binding(
                            get: { style.isBold },
                            set: { setStyle(bold: $0) }
                        ))
                        .toggleStyle(.button)

                        Toggle("Italic", systemImage: "italic", isOn: Binding(
                            get: { style.isItalic },
                            set: { setStyle(italic: $0) }
                        ))
                        .toggleStyle(.button)

                        Toggle("Bullets", systemImage: "list.bullet", isOn: Binding(
                            get: { selectedLinesHaveBullets },
                            set: { _ in toggleBullets() }
                        ))
                        .toggleStyle(.button)

                        Spacer()
                    }
                }
                // Swiping down would throw away what was typed
                .interactiveDismissDisabled(hasChanges)
                .onAppear {
                    isFocused = true
                }
        }
    }

    private var hasChanges: Bool {
        markdownCues(from: text) != markdownCues(from: originalText)
    }

    // MARK: - Bold and italic

    private var typingStyle: (isBold: Bool, isItalic: Bool) {
        style(of: selection.typingAttributes(in: text).font)
    }

    private func setStyle(bold: Bool? = nil, italic: Bool? = nil) {
        text.transformAttributes(in: &selection) { container in
            let current = style(of: container.font)
            container.font = Self.font(bold: bold ?? current.isBold, italic: italic ?? current.isItalic)
        }
    }

    private static func font(bold: Bool, italic: Bool) -> Font? {
        bold || italic ? Font.body.bold(bold).italic(italic) : nil
    }

    private func style(of font: Font?) -> (isBold: Bool, isItalic: Bool) {
        guard let font else { return (false, false) }
        let resolved = font.resolve(in: fontResolutionContext)
        // Compare weights with plain body text instead of using isBold, so a heavier
        // system font (like the Bold Text accessibility setting) isn't mistaken for bold
        let isBold = weight(of: resolved) > weight(of: Font.body.resolve(in: fontResolutionContext))
        return (isBold, resolved.isItalic)
    }

    private func weight(of font: Font.Resolved) -> Double {
        let traits = CTFontCopyTraits(font.ctFont) as NSDictionary
        return (traits[kCTFontWeightTrait] as? NSNumber)?.doubleValue ?? 0
    }

    // MARK: - Bullets

    private var selectedLinesHaveBullets: Bool {
        let characters = Array(text.characters)
        return selectedLineStarts().allSatisfy { Self.hasBullet(at: $0, in: characters) }
    }

    /// Adds a bullet to every selected line, or removes them if they all have one
    private func toggleBullets() {
        let characters = Array(text.characters)
        let starts = selectedLineStarts()
        let removing = starts.allSatisfy { Self.hasBullet(at: $0, in: characters) }

        text.transform(updating: &selection) { text in
            // Work from the last line up so the earlier line offsets stay valid
            for start in starts.reversed() {
                let index = text.characters.index(text.startIndex, offsetBy: start)
                if removing {
                    text.removeSubrange(index..<text.characters.index(index, offsetBy: Self.bullet.count))
                } else if !Self.hasBullet(at: start, in: characters) {
                    text.insert(AttributedString(Self.bullet), at: index)
                }
            }
        }
    }

    /// Pressing Return on a bulleted line starts the next line with a bullet; on an empty bullet it ends the list
    private func continueBulletList(from oldText: AttributedString) {
        let old = Array(oldText.characters)
        let new = Array(text.characters)

        // Only a single typed line break
        guard new.count == old.count + 1 else { return }
        let firstDifference = old.indices.first { old[$0] != new[$0] } ?? old.count
        guard new[firstDifference].isNewline, new[(firstDifference + 1)...].elementsEqual(old[firstDifference...]) else { return }

        // Next to other line breaks, any of them could be the new one; the cursor sits just after it.
        // Comparing indices (rather than measuring with the cursor) stays safe if the selection lags behind.
        var earliest = firstDifference
        while earliest > 0 && new[earliest - 1].isNewline {
            earliest -= 1
        }
        var inserted = earliest
        if case .insertionPoint(let cursor) = selection.indices(in: text),
           let match = (earliest...firstDifference).first(where: { text.characters.index(text.startIndex, offsetBy: $0 + 1) == cursor }) {
            inserted = match
        }

        let lineStart = new[..<inserted].lastIndex(where: \.isNewline).map { $0 + 1 } ?? 0
        let line = String(new[lineStart..<inserted])
        guard line.hasPrefix(Self.bullet) else { return }

        if line == Self.bullet {
            replaceCharacters(in: lineStart..<(inserted + 1), with: "", cursor: lineStart)
        } else {
            replaceCharacters(in: (inserted + 1)..<(inserted + 1), with: Self.bullet, cursor: inserted + 1 + Self.bullet.count)
        }
    }

    private func replaceCharacters(in offsets: Range<Int>, with replacement: String, cursor: Int) {
        let lower = text.characters.index(text.startIndex, offsetBy: offsets.lowerBound)
        let upper = text.characters.index(lower, offsetBy: offsets.count)
        text.replaceSubrange(lower..<upper, with: AttributedString(replacement))
        selection = AttributedTextSelection(insertionPoint: text.characters.index(text.startIndex, offsetBy: cursor))
    }

    /// Character offsets where each line touched by the selection starts
    private func selectedLineStarts() -> [Int] {
        let characters = Array(text.characters)
        let bounds: Range<Int>
        switch selection.indices(in: text) {
        case .insertionPoint(let index):
            let offset = text.characters.distance(from: text.startIndex, to: index)
            bounds = offset..<offset
        case .ranges(let ranges):
            guard let first = ranges.ranges.first, let last = ranges.ranges.last else { return [] }
            bounds = text.characters.distance(from: text.startIndex, to: first.lowerBound)
                ..< text.characters.distance(from: text.startIndex, to: last.upperBound)
        }

        let firstStart = characters[..<bounds.lowerBound].lastIndex(where: \.isNewline).map { $0 + 1 } ?? 0
        // A line break at the very end of the selection doesn't pull in the next line
        let laterStarts = bounds.dropLast().filter { characters[$0].isNewline }.map { $0 + 1 }
        return [firstStart] + laterStarts
    }

    private static func hasBullet(at offset: Int, in characters: [Character]) -> Bool {
        characters[offset...].starts(with: bullet)
    }

    // MARK: - Markdown

    /// Shows stored Markdown emphasis as fonts, which is what the editor's formatting controls change
    private static func editableText(from cues: [String]) -> AttributedString {
        var text = AttributedString()
        for (index, cue) in cues.enumerated() {
            if index > 0 {
                text += AttributedString("\n")
            }
            for piece in CueMarkdown.pieces(from: cue) {
                var run = AttributedString(piece.text)
                run.font = font(bold: piece.isBold, italic: piece.isItalic)
                text += run
            }
        }
        return text
    }

    private func markdownCues(from text: AttributedString) -> [String] {
        var lines: [[CueMarkdown.Piece]] = [[]]
        for run in text.runs {
            let style = style(of: run.font)
            let segments = String(text[run.range].characters).split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            for (index, segment) in segments.enumerated() {
                if index > 0 {
                    lines.append([])
                }
                lines[lines.count - 1].append(CueMarkdown.Piece(text: String(segment), isBold: style.isBold, isItalic: style.isItalic))
            }
        }

        let emptyBullet = Self.bullet.trimmingCharacters(in: .whitespaces)
        return lines
            .map { CueMarkdown.cue(from: $0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0 != emptyBullet }
    }
}
