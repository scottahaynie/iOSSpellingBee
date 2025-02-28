//
//  ContentView.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/9/25.
//

//TODO:
// DONE center honeycomb in screen - LayoutProtocol
// layouts
// DONE image buttons instead of words
// pointing system
// DONE randomize compliments
// DONE show # possibilities after 3 letters
// DONE saving game locally (after each word) - restoring saved game on load -
// save game history -- maybe in overflow menu
// DONE move game state into own model object - use ObservableObject plus the @Published annotation on all its vars
// DONE make enteredWord text read-only
// look for panagrams
// DONE animate hexagons on shuffle
// DONE progress bar for percentage found
// DONE long press Delete to clear entire word
// DONE make matching words hint only on press
// show progress bar current value
// animate when graduated to new level!
// fix bug where some hexagons don't animate, they just snap into their new position
// DONE Difficulty levels -- Easy / Medium / Hard
// DONE   present modal on New Game
// fix bug that animates center hexagon (and button row) when new game modal dismissed

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

    @ObservedObject var game: GameState
    var dictionary: Trie

    @State private var showToast = false
    @State private var toastType = ToastType.toastFound
    @State private var isShuffling = false
    @State private var showHint = false
    @State private var showNewGameModal = false
    @State private var shouldShowSettingsMenu = false

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
        if game.enteredWord.firstIndex(of: game.centerLetter[0]) == nil {
            toastType = ToastType.toastMissingCenterLetter
        } else if game.enteredWord.count < 4 {
            toastType = ToastType.toastTooShort
        } else if game.guessedWords.firstIndex(of: game.enteredWord.lowercased()) != nil {
            toastType = ToastType.toastAlreadyChosen
        } else if let i = game.possibleWords.firstIndex(of: game.enteredWord.lowercased()) {
            game.possibleWords.remove(at: i)
            game.guessedWords.append(game.enteredWord.lowercased())
            toastType = ToastType.toastFound
        } else {
            toastType = ToastType.toastNotFound
        }
        updateEnteredWord(text: "")
        showToast.toggle()
        saveGame()
    }
    
    private func restartGame() {
        let possibleMatchesRange: Range<Int>
        switch game.difficultyLevel {
        case .easy:
            possibleMatchesRange = 100..<200
        case .medium:
            possibleMatchesRange = 50..<100
        case .hard:
            possibleMatchesRange = 20..<50
        }
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
                trie: dictionary)
            print("finding possible words DONE")
            if possibleMatchesRange.contains(possibleWords.count) {
                game.outerLetters = String(chosenVowels.joined() + chosenCons.joined()).uppercased()
                game.centerLetter = center.uppercased()
                game.possibleWords = possibleWords
                game.guessedWords = []
                updateEnteredWord(text: "")
                for word in possibleWords {
                    print(word)
                }
                print(String(format:"%d possible words-- we have a MATCH! outside: %@, center: %@", possibleWords.count, game.outerLetters, game.centerLetter))
                break
            } else {
                print(String(format:"%d possible words, not good enough", possibleWords.count))
            }
        }
        saveGame()
    }
    
    private func updateEnteredWord(text: String) {
        game.enteredWord = text
        if text.count >= 3 {
            // filter out words that match the prefix -- possibleWords is sorted by prefix, so just find first then keep going until no match (or end)
            game.numWordsWithPrefix = game.possibleWords.filter({ $0.starts(with: text.lowercased()) }).count
        } else {
            game.numWordsWithPrefix = -1
        }
    }
    
    private func saveGame() {
        Task {
            try? await game.save()
        }
    }

    //TODO: to customize the look and feel of the gauge
    struct CustomGaugeStyle: GaugeStyle {
        func makeBody(configuration: Configuration) -> some View {
            
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    if !game.outerLetters.isEmpty {
                        Gauge(value: Double(game.guessedWords.count), in: 0...Double(game.possibleWords.count)) {
                            Text("Progress")
                        } currentValueLabel: {
                            Text("\(game.guessedWords.count)")
                        } minimumValueLabel: {
                            Text(game.guessedWords.count < 2 ? "Beginner" : "Good")
                            //                            .transition(AnyTransition.opacity.animation(.easeInOut(duration:1.0)))
                                .bold()
                                .foregroundStyle(.blue)
                            //.foregroundStyle(
                            //.shadow(color: .green, radius: 3)
                            //.foregroundStyle(.shadow(.drop(radius: 3)))
                        } maximumValueLabel: {
                            Text("\(game.possibleWords.count)")
                        }
                        .gaugeStyle(.accessoryLinear)
                        .frame(height: 22)
                        
                        //TODO: if gauge can show value underneath, remove this
                        Text("\(game.guessedWords.count) / \(game.possibleWords.count + game.guessedWords.count) Found")
                            .frame(height: 30)
                    } else {
                        Spacer(minLength: 30)
                        Text("Tap button below to start")
                            .frame(height: 30)
                    }
                    HStack {
                        // New Game Button
                        Button("New Game") {
                            //restartGame()
                            showNewGameModal.toggle()
                            //                    showingNewGameDialog = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        // Settings Button
                        Menu {
                            Button("Save Game", action: {
                                saveGame()
                            })
                            Button("Load Game", action: {
                                print("load game")
                            })
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .resizable()
                                .scaledToFit()
                                .padding(.all, 10)
                                .frame(width: 40, height: 40)
//                            Label("", systemImage: "ellipsis.circle")
//                                .frame(height: 40)
                        }
                    }
                    
                    Spacer()//minLength: 100)
                    TextField(
                        "", //"Enter a word",
                        text: $game.enteredWord
                    )
                    .font(Font.system(size: 50, design: .default))
                    .foregroundColor(.black)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .disableAutocorrection(true)
                    .textContentType(.name)
//                    .focused($wordEntryFocused)
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
                        Text(game.numWordsWithPrefix == -1 ? " " :
                                "\(game.numWordsWithPrefix) matches"
                        )
                        //.transition(.opacity.combined(with: .move(edge: .leading)))
                        .transition(.opacity)  // .blurReplace
                        .frame(height: 40)
                        .padding()
                    } else {
                        Button("Show hint") {
                            withAnimation() {
                                showHint = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation() {
                                    showHint = false
                                }
                            }
                        }
                        .disabled(showHint || game.numWordsWithPrefix == -1)
                        .transition(.opacity) //TODO: this isn't working
                        .buttonStyle(.bordered)
                        .frame(height: 40)
                        .padding()
                    }
                    
                    GeometryReader { geometryHoneycomb in
                        // Honeycomb
                        Honeycomb(
                            outerLetters: game.outerLetters,
                            centerLetter: game.centerLetter,
                            rect: CGRect(
                                x: geometryHoneycomb.size.width / 2,
                                y: geometryHoneycomb.size.height / 2,
                                width: 100,
                                height: 100
                            ),
                            isShuffling: $isShuffling,
                            onTap: { text, isCenter in
                                print("Honeycomb letter entered: \(text), isCenter: \(isCenter)")
                                updateEnteredWord(text: game.enteredWord + text)
                            }
                        )//.border(.red)
                    }
                    
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
                                    updateEnteredWord(text: String(game.enteredWord.dropLast(1)))
                                }
                                .onLongPressGesture(minimumDuration: 0.1) {
                                    updateEnteredWord(text: "")
                                }
                            //                        }
                        }
                        .disabled(game.outerLetters.isEmpty || game.enteredWord.isEmpty)
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
                        .disabled(game.outerLetters.isEmpty)
                        .buttonStyle(.borderedProminent)
                        
                        // Enter Button
                        Button {
                            onSubmit()
                        } label: {
                            Text("ENTER")
                                .frame(width: 80, height: 50)
                        }
                        .disabled(game.outerLetters.isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                
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

                // from https://blog.stackademic.com/swiftui-popup-dialog-this-is-also-how-you-can-add-custom-view-transition-animation-f7140431ec5f
                if showNewGameModal {
                    Modal(showModal: $showNewGameModal) {
                        VStack {
                            Picker("Difficulty", selection: $game.difficultyLevel) {
                                Text("Easy").tag(GameState.DifficultyLevel.easy)
                                Text("Medium").tag(GameState.DifficultyLevel.medium)
                                Text("Hard").tag(GameState.DifficultyLevel.hard)
                            }
                            .pickerStyle(.segmented)
                            Button("Start Game") {
                                showNewGameModal = false
                                restartGame()
                            }
                        }
                    }
                }
            }
        }
    }
}

//#Preview {
//    ContentView(game: )
//}
