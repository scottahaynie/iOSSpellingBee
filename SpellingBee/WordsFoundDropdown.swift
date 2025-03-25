//
//  WordsFoundDropdown.swift
//  SpellingBee
//
//  Created by Scott Haynie on 3/25/25.
//

import SwiftUI

struct WordsFoundDropdown: View {
    var words: [String]
    @Binding var showWordsFound: Bool

    let PADDING_HORIZONTAL = 8.0

    private func getWordsByRecent() -> [String] {
        return words.reversed().compactMap { $0.capitalized }
    }
    private func getWordsByAlpha() -> [String] {
        return words.sorted().compactMap { $0.capitalized }
    }

    var body: some View {
        Button {
            showWordsFound.toggle()
        } label: {
            VStack {
                HStack {
                    Text(showWordsFound
                         ? "You found \(words.count) words:"
                         : getWordsByRecent().joined(separator: " "))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.all, PADDING_HORIZONTAL)
                    Spacer()
                    Image(systemName: showWordsFound ? "chevron.up" : "chevron.down")
                        .padding(.all, PADDING_HORIZONTAL)
                }
                if (showWordsFound) {
                    ScrollView {
                        HStack(alignment: .top, spacing: 8) {
                            // First column
                            let wordsAlpha = getWordsByAlpha()
                            let midpoint = words.count == 0 ? 0 : words.count / 2 + 1
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(wordsAlpha[..<midpoint], id: \.self) { word in
                                    Text(word)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 8)
                                }
                            }

                            // Second column
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(wordsAlpha[midpoint...], id: \.self) { word in
                                    Text(word)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 8)
                                }
                            }
                        }
                        .padding(.horizontal, PADDING_HORIZONTAL)
                    }
                }
            }
        }
        .frame(maxWidth: showWordsFound ? .infinity : nil,
               maxHeight: showWordsFound ? .infinity : nil,
               alignment: .top)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray)
        )
        .padding(.vertical)
    }
}

struct WordsFoundDropdownPreview: View {
    @State var showWordsFound: Bool = false
    var body: some View {
        let words = ["hello", "this", "word", "great", "again", "amazing", "another", "telephone"]
        WordsFoundDropdown(words: words, showWordsFound: $showWordsFound)
    }
}

#Preview {
    WordsFoundDropdownPreview()
        .padding()
}
