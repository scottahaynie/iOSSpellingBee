//
//  ContentView.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/9/25.
//

//TODO:
// center honeycomb in screen
// layouts
// DONE image buttons instead of words
// pointing system
// DONE randomize compliments
// DONE show # possibilities after 3 letters
// saving game locally (after each word) - restoring saved game on load
// save game history -- maybe in overflow menu
// move game state into own model object
// DONE make enteredWord text read-only
// look for panagrams
// DONE animate hexagons on shuffle
// DONE progress bar for percentage found
// DONE long press Delete to clear entire word
// DONE make matching words hint only on press
// show progress bar current value
// animate when graduated to new level!
// fix bug where some hexagons don't animate, they just snap into their new position

import SwiftUI
import AlertToast

struct ContentView: View {
    private enum ToastType: Equatable {
        case toastFound
        case toastAlreadyChosen
        case toastMissingCenterLetter
        case toastTooShort
        case toastNotFound
    }
    @State private var wordTrie: Trie?
    @State private var outerLetters: String? // uppercased
    @State private var centerLetter: String? // uppercased
    @State private var possibleWords: [String]?
    @State private var guessedWords: [String]?
    @State private var enteredWord = ""
    @State private var numWordsWithPrefix = -1
    @FocusState private var wordEntryFocused: Bool
    @State private var showToast = false
    @State private var toastType = ToastType.toastFound
    @State private var rectX = 100
    @State private var isShuffling = false
    @State private var showHint = false

    let VOWELS = ["a","e","i","o","u"]
    let CONS = ["b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","w","x","y","z"]

    private func getRandomCompliment() -> String {
        return ["So cool!",
         "Nice choice!",
         "Keep it up!",
         "Way to go!",
         "Fun times!",
         "Yippee!"].randomElement()!
    }
    private func onSubmit() {
        if enteredWord.firstIndex(of: centerLetter![0]) == nil {
            toastType = ToastType.toastMissingCenterLetter
        } else if enteredWord.count < 4 {
            toastType = ToastType.toastTooShort
        } else if guessedWords!.firstIndex(of: enteredWord.lowercased()) != nil {
            toastType = ToastType.toastAlreadyChosen
        } else if let i = possibleWords!.firstIndex(of: enteredWord.lowercased()) {
            possibleWords!.remove(at: i)
            guessedWords!.append(enteredWord.lowercased())
            toastType = ToastType.toastFound
        } else {
            toastType = ToastType.toastNotFound
        }
        updateEnteredWord(text: "")
        wordEntryFocused = true
        showToast.toggle()
    }

    private func initGame() {
        print("reading word file")
        guard let filePath = Bundle.main.path(forResource: "EWOL-Words", ofType: "txt") else {
            print("File not found")
            return
        }
        do {
            let fileContents = try String(contentsOfFile: filePath)
            let words = fileContents.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            wordTrie = Trie()
            print("building trie")
            for word in words {
                if word.count > 3 {
                    wordTrie?.insert(val: word)
                }
            }
            print("building trie DONE")
        } catch {
            print("Error")
        }
    }
    
    private func restartGame() {
        while true {
            var chosenVowels: [String] = []
            var vowels2 = VOWELS
            for _ in 1...2 {
                let randIndex = Int.random(in: 0..<vowels2.count)
                chosenVowels.append(vowels2.remove(at: randIndex))
            }
            print("chosen vowels: " + chosenVowels.joined())
            
            var chosenCons: [String] = []
            var cons2 = CONS
            for _ in 1...5 {
                let randIndex = Int.random(in: 0..<cons2.count)
                chosenCons.append(cons2.remove(at: randIndex))
            }
            print("chosen cons: " + chosenCons.joined())
            
            var center: String
            let randIndex = Int.random(in: 0...6)
            if randIndex < 2 {
                center = chosenVowels.remove(at: randIndex)
            } else {
                center = chosenCons.remove(at: randIndex - 2)
            }
            print("center: " + center)
            print("vowels: " + chosenVowels.joined())
            print("cons: " + chosenCons.joined())
            
            print("finding possible words")
            let possibleWords = Util.findPossibleWords(
                letters: chosenVowels.joined() + chosenCons.joined() + center,
                requiredLetter: center,
                trie: wordTrie!)
            print("finding possible words DONE")
            if possibleWords.count > 20 && possibleWords.count < 100 {
                self.outerLetters = String(chosenVowels.joined() + chosenCons.joined()).uppercased()
                self.centerLetter = center.uppercased()
                self.possibleWords = possibleWords
                self.guessedWords = []
                updateEnteredWord(text: "")
                self.wordEntryFocused = true
                for word in possibleWords {
                    print(word)
                }
                print(String(format:"%d possible words-- we have a MATCH! outside: %@, center: %@", possibleWords.count, outerLetters!, centerLetter!))
                break
            } else {
                print(String(format:"%d possible words, not good enough", possibleWords.count))
            }
        }
    }
    
    private func updateEnteredWord(text: String) {
        self.enteredWord = text
        if text.count >= 3 {
            // filter out words that match the prefix -- possibleWords is sorted by prefix, so just find first then keep going until no match (or end)
            self.numWordsWithPrefix = self.possibleWords!.filter({ $0.starts(with: text.lowercased()) }).count
        } else {
            self.numWordsWithPrefix = -1
        }
    }

    //TODO: to customize the look and feel of the gauge
    struct CustomGaugeStyle: GaugeStyle {
        func makeBody(configuration: Configuration) -> some View {
            
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if outerLetters != nil {
                    Gauge(value: Double(guessedWords!.count), in: 0...Double(possibleWords!.count)) {
                        Text("Progress")
                    } currentValueLabel: {
                        Text("\(guessedWords!.count)")
                    } minimumValueLabel: {
                        Text(guessedWords!.count < 2 ? "Beginner" : "Good")
//                            .transition(AnyTransition.opacity.animation(.easeInOut(duration:1.0)))
                            .bold()
                            .foregroundStyle(.blue)
                            //.foregroundStyle(
                            //.shadow(color: .green, radius: 3)
                            //.foregroundStyle(.shadow(.drop(radius: 3)))
                    } maximumValueLabel: {
                        Text("\(possibleWords!.count)")
                    }
                    .gaugeStyle(.accessoryLinear)
                    .frame(height: 22)
                    
                    //TODO: if gauge can show value underneath, remove this
                    Text("\(guessedWords!.count) / \(possibleWords!.count + guessedWords!.count) Found")
                        .frame(height: 30)
                } else {
                    Spacer(minLength: 30)
                    Text("Tap button below to start")
                        .frame(height: 30)
                }
                Button("New Game") {
                    restartGame()
                    
        //            let trie = Trie()
        //            trie.insert(val: "hello")
        //            trie.insert(val: "hella")
        //            trie.insert(val: "helpme")
        //            print(trie.contains(val: "helpme"))
        //            print(trie.contains(prefix: "hel"))
        //            print(trie.contains(val: "hel"))
        //            print(trie.find(prefix: "hel").joined())
                }
                .buttonStyle(.borderedProminent)

                Spacer(minLength: 100)
                TextField(
                    "", //"Enter a word",
                    text: $enteredWord
                )
                .font(Font.system(size: 50, design: .default))
                .foregroundColor(.black)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .disableAutocorrection(true)
                .textContentType(.name)
                .focused($wordEntryFocused)
                .multilineTextAlignment(.center)
                .onSubmit {
                    onSubmit()
                }
                .disabled(true)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray)
                )
                .padding(.horizontal, 20)

                // Matching words hint
                if showHint {
                    Text(numWordsWithPrefix == -1 ? " " :
                         "\(numWordsWithPrefix) matches"
                    )
                    .transition(.opacity)
                    .frame(height: 40)
                    .padding()
                } else {
                    Button("Show hint") {
                        showHint = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showHint = false
                        }
                    }
                    .disabled(showHint || numWordsWithPrefix == -1)
                    .transition(.opacity)
                    .buttonStyle(.bordered)
                    .frame(height: 40)
                    .padding()
                }
                
                // Honeycomb
                Honeycomb(
                    outerLetters: outerLetters,
                    centerLetter: centerLetter,
                    //TODO: center honeycomb vertically/horizontally
                    //TODO: rect should be the rect of all hexagons, not just one
                    //rect: CGRect(x: 200, y: 400, width: 100, height: 100),
                    //rect: CGRect(x: geometry.size.width / 2 - 15, y: 200, width: 100, height: 100),
                    rect: CGRect(x: 180/*self.rectX*/, y: 150, width: 100, height: 100),
                    isShuffling: $isShuffling,
                    onTap: { text, isCenter in
                        print("Honeycomb letter entered: \(text), isCenter: \(isCenter)")
                        updateEnteredWord(text: self.enteredWord + text)
                    }
                )
                
                // Button Row
                HStack {
                    // Delete Button
                    Button(action: {
                    }) {
                        //not needed?
                        //                        VStack {
                        Image(systemName: "delete.left.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(.all, 10)
                            .frame(width: 80, height: 50)
                            .contentShape(Rectangle()) // to make space around image tappable
                            .onTapGesture {
                                updateEnteredWord(text: String(enteredWord.dropLast(1)))
                            }
                            .onLongPressGesture(minimumDuration: 0.1) {
                                updateEnteredWord(text: "")
                            }
                        //                        }
                    }
                    .disabled(outerLetters == nil || enteredWord.isEmpty)
                    .buttonStyle(.borderedProminent)
                    
                    // Shuffle Button
                    Button {
                        isShuffling = true
                    } label: {
                        Image(systemName: "shuffle")
                            .resizable()
                            .scaledToFit()
                            .padding(.all, 10)
                            .frame(width: 50, height: 50)
                    }
                    .disabled(outerLetters == nil)
                    .buttonStyle(.borderedProminent)
                    
                    // Enter Button
                    Button {
                        onSubmit()
                    } label: {
                        Text("ENTER")
                            .frame(width: 80, height: 50)
                    }
                    .disabled(outerLetters == nil)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()

            // Initialize game on first load
            .task {
                initGame()
            }

            // Present a toast if needed
            .toast(isPresenting: $showToast, duration: 1, alert: {
                switch (toastType) {
                case ToastType.toastFound:
                    return AlertToast(displayMode: .hud, type: .complete(Color.white), title: getRandomCompliment(), style: .style(backgroundColor: Color.green, titleColor: Color.white))
                case ToastType.toastTooShort:
                    return AlertToast(displayMode: .hud, type: .error(Color.white), title: "Too short", style: .style(backgroundColor: Color.red, titleColor: Color.white))
                case ToastType.toastNotFound:
                    return AlertToast(displayMode: .hud, type: .error(Color.white), title: "Nope", style: .style(backgroundColor: Color.red, titleColor: Color.white))
                case ToastType.toastAlreadyChosen:
                    return AlertToast(displayMode: .hud, type: .error(Color.white), title: "Already chosen", style: .style(backgroundColor: Color.red, titleColor: Color.white))
                case ToastType.toastMissingCenterLetter:
                    return AlertToast(displayMode: .hud, type: .error(Color.white), title: "Missing center letter", style: .style(backgroundColor: Color.red, titleColor: Color.white))
                }
            }, completion: {
                print("toast dismissed")
            })
        }
    }
}

#Preview {
    ContentView()
}
