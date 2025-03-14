//
//  ContentView.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/9/25.
//

//TODO:
// IMMEDIATE:
// polish new game modal
// look for panagrams - alter points/ranks calcs based on it
// fix bug where some hexagons don't animate, they just snap into their new position
// fix modal bugs: modal moves things in the background when it appears
//  - animates center hexagon (and button row) when new game modal dismissed
//  - Cam: consider using a Sheet for this
// debug menu: specify letters to use (for comparing with NYT app)
// investigate using SwiftData for persistence: https://developer.apple.com/xcode/swiftdata/
// move game business logic into separate class with its own unit tests
// play sounds on button presses / word found
//  - https://www.hackingwithswift.com/forums/100-days-of-swiftui/trying-to-play-sound-when-pressing-button/28226
// loading indicator while new game getting created
// show last found words underneath points
// when last found words tapped, reveal all of them
// popup new game modal automatically (if no saved game)
// create nav bar at top: title, new game and settings buttons
// put New Game into menu (rather than button) -- or an image button at the top
// progress bar:
//  - tap on progress bar reveals rankings
//  - show tick marks on progress bar for each rank
//  - show progress bar current value
// show points to next rank, underneath progress bar - "6 points to Solid"
// move colors into constants
// find better kids words file -- it's too limited, doesn't have a lot of words
//
// FUTURE:
// animate when graduated to new level! throw confetti on screen
// save game history -- maybe in top bar, chart icon -- each game keyed on date/time created
// dark mode
//
// DONE:
// DONE pointing system / grades
// DONE allow keystrokes for quick testing (focus, but it's disabled)
// DONE Nolan Mode: allow 3-letter words and easier dictionary.
// DONE center honeycomb in screen - LayoutProtocol
// DONE image buttons instead of words
// DONE randomize compliments
// DONE show # possibilities after 3 letters
// DONE saving game locally (after each word) - restoring saved game on load -
// DONE move game state into own model object - use ObservableObject plus the @Published annotation on all its vars
// DONE make enteredWord text read-only
// DONE animate hexagons on shuffle
// DONE progress bar for percentage found
// DONE long press Delete to clear entire word
// DONE make matching words hint only on press
// DONE Difficulty levels -- Easy / Medium / Hard
// DONE   present modal on New Game

// iPhone 16 Pro simulator UserDefaults location:
// /Users/scotthay/Library/Developer/CoreSimulator/Devices/D6528BCC-3093-4B09-A01A-03A7253FB37E/data/Containers/Data/Application/F12CF147-50E3-4861-A071-1A4FB9A02B43/Library

import SwiftUI
import AlertToast
import OSLog

// allows SegmentedControl Picker to change height and style attributes
// applies to all segmented controls in app
// https://stackoverflow.com/questions/58609030/how-to-change-height-of-a-picker-with-segmentedpickerstyle-in-swiftui
extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setContentHuggingPriority(.defaultLow, for: .vertical)  // << here !!
        UISegmentedControl.appearance().backgroundColor = .tintColor.withAlphaComponent(0.15)
//        let font = UIFont.preferredFont(forTextStyle: .footnote) // regular weight
        UISegmentedControl.appearance().setTitleTextAttributes([.font: UIFont.preferredFont(forTextStyle: .subheadline)], for: .normal)
    }
}

struct ContentView: View {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                        category: String(describing: ContentView.self))

    private enum ToastType: Equatable {
        case toastFound
        case toastAlreadyChosen
        case toastMissingCenterLetter
        case toastTooShort
        case toastNotFound
    }

    @ObservedObject var game: GameState
    var dictionary: Trie
    var kidsDictionary: Trie

    @State private var showToast = false
    @State private var toastType = ToastType.toastFound
    @State private var isShuffling = false
    @State private var showHint = false
    @State private var showNewGameModal = false
    
    @FocusState private var textFocused: Bool

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
    
    private func calculatePoints(for words: [String]) -> Int {
        var points = 0
        for word in words {
            if word.count > game.minCharacters {
                points += word.count
            } else {
                points += 1
            }
        }
        return points
    }

    private func onSubmit() {
        if game.enteredWord.firstIndex(of: game.centerLetter[0]) == nil {
            toastType = ToastType.toastMissingCenterLetter
        } else if game.enteredWord.count < game.minCharacters {
            toastType = ToastType.toastTooShort
        } else if game.guessedWords.firstIndex(of: game.enteredWord.lowercased()) != nil {
            toastType = ToastType.toastAlreadyChosen
        } else if let i = game.remainingWords.firstIndex(of: game.enteredWord.lowercased()) {
            game.remainingWords.remove(at: i)
            game.guessedWords.append(game.enteredWord.lowercased())
            game.guessedPoints = calculatePoints(for: game.guessedWords)
            toastType = ToastType.toastFound
        } else {
            toastType = ToastType.toastNotFound
        }
        updateEnteredWord(text: "")
        textFocused = true
        showToast.toggle()
        if toastType == ToastType.toastFound {
            saveGame()
        }
    }
    
    private func restartGame() {
        let possibleMatchesRange: Range<Int>
        switch game.difficultyLevel {
        case .kids:
            possibleMatchesRange = 20..<50
        case .easy:
            possibleMatchesRange = 150..<300
        case .medium:
            possibleMatchesRange = 50..<150
        case .hard:
            possibleMatchesRange = 20..<50
        }
        var i = 1
        while true {
            var chosenVowels: [String] = []
            var vowels2 = VOWELS
            //TODO: consider 2 OR 3 vowels
            for _ in 1...2 {
                let randIndex = Int.random(in: 0..<vowels2.count)
                chosenVowels.append(vowels2.remove(at: randIndex))
            }
            logger.debug("chosen vowels: \(chosenVowels.joined())")
            
            var chosenCons: [String] = []
            var cons2 = CONS
            for _ in 1...5 {
                let randIndex = Int.random(in: 0..<cons2.count)
                chosenCons.append(cons2.remove(at: randIndex))
            }
            logger.debug("chosen cons: \(chosenCons.joined())")
            
            var center: String
            let randIndex = Int.random(in: 0...6)
            if randIndex < 2 {
                center = chosenVowels.remove(at: randIndex)
            } else {
                center = chosenCons.remove(at: randIndex - 2)
            }
            logger.debug("center: \(center)")
            logger.debug("vowels: \(chosenVowels.joined())")
            logger.debug("cons: \(chosenCons.joined())")
            
            logger.debug("finding possible words")
            let possibleWords = Util.findPossibleWords(
                letters: chosenVowels.joined() + chosenCons.joined() + center,
                requiredLetter: center,
                trie: game.difficultyLevel == .kids ? kidsDictionary : dictionary)
            logger.debug("finding possible words DONE")
            if possibleMatchesRange.contains(possibleWords.count) {
                // hooray - we found a match!
                game.outerLetters = String(chosenVowels.joined() + chosenCons.joined()).uppercased()
                game.centerLetter = center.uppercased()
                game.remainingWords = possibleWords
                game.guessedWords = []
                game.possiblePoints = calculatePoints(for: possibleWords)
                updateEnteredWord(text: "")
                for word in possibleWords {
                    logger.debug("\(word)")
                }
                logger.info("""
                    \(possibleWords.count) possible words-- we have a MATCH after \(i) tries!
                    outside: \(game.outerLetters), center: \(game.centerLetter)
                    """)
                break
            } else {
                logger.debug("\(possibleWords.count) possible words, not good enough")
            }
            i += 1
        }
        saveGame()
    }
    
    private func updateEnteredWord(text: String) {
        game.enteredWord = text
        if text.count >= game.minCharacters - 1 {
            // filter out words that match the prefix
            game.numWordsWithPrefix = game.remainingWords.filter({ $0.starts(with: text.lowercased()) }).count
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
        ZStack {
            VStack {
                if !game.outerLetters.isEmpty {
                    //Gauge(value: Double(game.guessedWords.count), in: 0...Double(game.remainingWords.count)) {
                    Gauge(value: Double(game.guessedPoints), in: 0...Double(game.possiblePoints)) {
                        Text("Progress")
                    } currentValueLabel: {
                        //Text("\(game.guessedWords.count)")
                        Text("\(game.guessedPoints)")
                    } minimumValueLabel: {
                        //Text(game.guessedWords.count < 2 ? "Beginner" : "Good")
                        Text(game.rank.rawValue)
                        //                            .transition(AnyTransition.opacity.animation(.easeInOut(duration:1.0)))
                            .bold()
                            .foregroundStyle(.blue)
                        //.foregroundStyle(
                        //.shadow(color: .green, radius: 3)
                        //.foregroundStyle(.shadow(.drop(radius: 3)))
                    } maximumValueLabel: {
                        //Text("\(game.remainingWords.count)")
                        Text("\(game.possiblePoints)")
                    }
                    .gaugeStyle(.accessoryLinear)
                    .frame(height: 22)
                    
                    //TODO: if gauge can show value underneath, remove this
                    Text("\(game.guessedWords.count) / \(game.remainingWords.count + game.guessedWords.count) Found (\(game.guessedPoints) points)")
                        .frame(height: 30)
                } else {
                    Spacer(minLength: 30)
                    Text("Tap button below to start")
                        .frame(height: 30)
                }
                HStack {
                    // New Game Button
                    Button("New Game") {
                        showNewGameModal.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // Settings Button
                    Menu {
                        Button("Save Game", action: {
                            saveGame()
                        })
                        Button("Load Game", action: {
                            logger.debug("load game")
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
                
                Spacer(minLength: 70)
                TextField(
                    "", //"Enter a word",
                    text: $game.enteredWord
                )
                .font(Font.system(size: 50, weight: .heavy, design: .monospaced))
                .foregroundColor(.black)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .disableAutocorrection(true)
                .textContentType(.name)
//                    .focused($wordEntryFocused)
                .multilineTextAlignment(.center)
                .onSubmit {
                    onSubmit()
                }
                //.disabled(true)
                .focused($textFocused)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray)
                )
                .padding(.horizontal, 20)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                        textFocused = true
                    }
                }
                
                // Matching words hint
                if showHint {
                    Text(game.numWordsWithPrefix == -1 ? " " :
                            "\(game.numWordsWithPrefix) matching words"
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
                    .transition(.opacity)
                    .buttonStyle(.bordered)
                    .frame(height: 40)
                    .padding()
                }
                
                // Honeycomb
                GeometryReader { geometryHoneycomb in
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
                            logger.debug("Honeycomb letter entered: \(text), isCenter: \(isCenter)")
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
                        Text("Enter")
                            .frame(width: 80, height: 50)
                    }
                    .disabled(game.outerLetters.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            
            // Present a toast if needed
            .toast(isPresenting: $showToast, duration: 1.5, alert: {
                switch (toastType) {
                case ToastType.toastFound:
                    return AlertToast(displayMode: .hud, type: .complete(Color.white), title: getRandomCompliment(), style: .style(backgroundColor: Color.green, titleColor: Color.white))
                case ToastType.toastTooShort:
                    return AlertToast(displayMode: .hud, type: .error(Color.white), title: "Too short", style: .style(backgroundColor: Color.red, titleColor: Color.white))
                case ToastType.toastNotFound:
                    return AlertToast(displayMode: .hud, type: .error(Color.white), title: "Nope", style: .style(backgroundColor: Color.red, titleColor: Color.white))
                case ToastType.toastAlreadyChosen:
                    return AlertToast(displayMode: .hud, type: .error(Color.white), title: "Already found", style: .style(backgroundColor: Color.red, titleColor: Color.white))
                case ToastType.toastMissingCenterLetter:
                    return AlertToast(displayMode: .hud, type: .error(Color.white), title: "Missing center letter", style: .style(backgroundColor: Color.red, titleColor: Color.white))
                }
            }, completion: {
                logger.debug("toast dismissed")
            })
            
            .task( {
                //UISegmentedControl.appearance().backgroundColor = .red //.tintColor.withAlphaComponent(0.2)
                //UISegmentedControl.appearance().setContentHuggingPriority(.defaultLow, for: .vertical)
            })

            // from https://blog.stackademic.com/swiftui-popup-dialog-this-is-also-how-you-can-add-custom-view-transition-animation-f7140431ec5f
            if showNewGameModal {
                Modal(showModal: $showNewGameModal) {
                    VStack {
                        Picker("Difficulty", selection: $game.difficultyLevel) {
                            Text("Kids").tag(GameState.DifficultyLevel.kids)
                            Text("Easy").tag(GameState.DifficultyLevel.easy)
                            Text("Medium").tag(GameState.DifficultyLevel.medium)
                            Text("Hard").tag(GameState.DifficultyLevel.hard)
                        }
                        .frame(height: 50)
                        .pickerStyle(.segmented)
                        .padding()
                        Button("Start Game") {
                            showNewGameModal = false
                            restartGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
}

#Preview {
    Group {
        let game = GameState()
        let _ = {
            game.outerLetters = "CTDREO"
            game.centerLetter = "B"
        }()
        ContentView(game: game, dictionary: Trie(), kidsDictionary: Trie())
    }
}
