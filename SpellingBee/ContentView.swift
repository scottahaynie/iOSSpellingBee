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
// bug: hexagons don't animate, they just snap into their new position
// debug menu: specify letters to use (for comparing with NYT app)
// investigate using SwiftData for persistence: https://developer.apple.com/xcode/swiftdata/
// move game business logic into separate class with its own unit tests
// loading indicator while new game getting created
// popup new game modal automatically (if no saved game)
// tap on progress bar reveals rankings
// show points to next rank, underneath progress bar - "6 points to Solid"
// kids mode - easier words (# of syllables/ frequency)
// support iPad layout
//  -- problems: buttons pushed down past edge,
// why word entry height changes when empty?
// investigate % height layout -- need to use GeometryReader
// support large text sizes
// bug: New game modal switching level shouldn't alter current game
//
// FUTURE:
// animate when graduated to new level! throw confetti on screen - dancing gorilla
// save game history -- maybe in top bar, chart icon -- each game keyed on date/time created
// dark mode
//
// DONE:
// DONE progress bar should align Genius to 100% ?
// DONE kids mode - easier ranking
// DONE customizable colors
// DONE play sounds on button presses / word found
// DONE make sure game will build/work on Nolan's iPad (iOS 15.8)
// DONE prevent keyboard from popping up
// DONE show last found words underneath points (in recency order)
// DONE when last found words tapped, reveal all of them (in alpha order)
// DONE put New Game into menu (rather than button) -- or an image button at the top
// DONE create nav bar at top: title, new game and settings buttons
// DONE move colors into constants
// DONE - show tick marks on progress bar for each rank
// DONE - show progress bar current value
// DONE capitalize words found
// DONE fix modal bugs: modal moves things in the background when it appears
//  - animates center hexagon (and button row) when new game modal dismissed
//  - Cam: consider using a Sheet for this
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

extension Color: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        let rgbArray = rawValue.components(separatedBy: ",")
        if let red = Double (rgbArray[0]), let green = Double (rgbArray[1]), let blue = Double(rgbArray[2]), let alpha = Double (rgbArray[3]) {
            self.init(red: red, green: green, blue: blue, opacity: alpha)
        }
        else {
            self = .black
        }
    }
    
    public var rawValue: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return "\(red),\(green),\(blue),\(alpha)"
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
    
    @State private var showToast = false
    @State private var toastType = ToastType.toastFound
    @State private var isShuffling = false
    @State private var showHint = false
    @State private var showNewGameModal: Bool? = nil
    @State private var showSettingsModal: Bool? = nil
    @State private var showWordsFound = false
    
    @FocusState private var textFocused: Bool
    
    @AppStorage("hintsEnabled") private var hintsEnabled = false
    @AppStorage("soundsEnabled") private var soundsEnabled = true
    @AppStorage("hexagonColor") private var hexagonColor = AppColors.hexagon
    @AppStorage("centerHexagonColor") private var centerHexagonColor = AppColors.centerHexagon

    let VOWELS = ["a","e","i","o","u"]
    let CONS = ["b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","w","x","y","z"]
    let PADDING_HORIZONTAL = 8.0

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
            if soundsEnabled { Sounds.playSound(.fartcurly) }
        } else if game.enteredWord.count < game.minCharacters {
            toastType = ToastType.toastTooShort
            if soundsEnabled { Sounds.playSound(.fartlittle) }
        } else if game.guessedWords.firstIndex(of: game.enteredWord.lowercased()) != nil {
            toastType = ToastType.toastAlreadyChosen
            if soundsEnabled { Sounds.playRandomSound(Sounds.bigmisses) }
        } else if let i = game.remainingWords.firstIndex(of: game.enteredWord.lowercased()) {
            // guessed a word correctly
            let rankOld = game.rank
            game.remainingWords.remove(at: i)
            game.guessedWords.append(game.enteredWord.lowercased())
            game.guessedPoints = calculatePoints(for: game.guessedWords)
            toastType = ToastType.toastFound
            if game.rank != rankOld {
                // graduated ranks!
                if soundsEnabled { Sounds.playRandomSound(Sounds.bigwins) }
            } else {
                if soundsEnabled { Sounds.playRandomSound(Sounds.littlewins) }
            }
        } else {
            toastType = ToastType.toastNotFound
            if soundsEnabled { Sounds.playSound(.fartsqueak) }
        }
        updateEnteredWord(text: "")
        textFocused = true
        showToast.toggle()
        if toastType == ToastType.toastFound {
            saveGame()
        }
    }
    
    private func restartGame() {
        let possibleMatchesRange: ClosedRange<Int>
        switch game.difficultyLevel {
        case .kids:
            possibleMatchesRange = 100...150
        case .easy:
            possibleMatchesRange = 100...150
        case .medium:
            possibleMatchesRange = 50...100
        case .hard:
            possibleMatchesRange = 20...50
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
            
            var chosenCons: [String] = []
            var cons2 = CONS
            for _ in 1...5 {
                let randIndex = Int.random(in: 0..<cons2.count)
                chosenCons.append(cons2.remove(at: randIndex))
            }
            
            var center: String
            let randIndex = Int.random(in: 0...6)
            if randIndex < 2 {
                center = chosenVowels.remove(at: randIndex)
            } else {
                center = chosenCons.remove(at: randIndex - 2)
            }
            
            logger.debug("finding possible words, letters: \(chosenVowels.joined())\(chosenCons.joined()), center: \(center)")
            let possibleWords = Util.findPossibleWords(
                letters: chosenVowels.joined() + chosenCons.joined() + center,
                requiredLetter: center,
                minLength: game.minCharacters,
                trie: dictionary,
                stopAt: possibleMatchesRange.upperBound + 1)
            if possibleMatchesRange.contains(possibleWords.count) {
                // hooray - we found a match!
                game.outerLetters = String(chosenVowels.joined() + chosenCons.joined()).uppercased()
                game.centerLetter = center.uppercased()
                game.remainingWords = possibleWords
                game.guessedWords = []
                game.guessedPoints = 0
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
    
    private func getWordsByRecent() -> [String] {
        return game.guessedWords.reversed().compactMap { $0.capitalized }
    }
    private func getWordsByAlpha() -> [String] {
        return game.guessedWords.sorted().compactMap { $0.capitalized }
    }

    var body: some View {
        VStack {
            //** TITLE BAR
            HStack {
                // Title
                Text("Spelling Bee")
                    .font(.title)
                    .bold()
                    .padding(.horizontal, PADDING_HORIZONTAL)
                Spacer()
                // New Game Button
                Button {
                    showNewGameModal = !(showNewGameModal ?? false)
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .resizable()
                        .padding(.all, PADDING_HORIZONTAL)
                        .frame(width: 45, height: 45)
                }
                // Settings Button
                Button {
                    showSettingsModal = !(showSettingsModal ?? false)
                } label: {
                    Image(systemName: "gearshape")
                        .resizable()
                        .padding(.all, PADDING_HORIZONTAL)
                        .frame(width: 45, height: 45)
                }
            }
            .padding(.horizontal, 5)
            //.background(.blue.opacity(0.3).gradient, in: RoundedRectangle(cornerRadius: 8))
            .background(.linearGradient(colors: [AppColors.colorTitle.opacity(0.2), AppColors.colorTitle.opacity(0.5)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, -5)

            //** PROGRESS GAUGE
            if !game.outerLetters.isEmpty {
                let maxValue = Int(Float(game.possiblePoints) * (game.isKids ? GameState.Rank.Genius.kidsRange.lowerBound : GameState.Rank.Genius.range.lowerBound))
                SpellingBeeGauge(
                    minValue: 0,
                    maxValue: maxValue,
                    value: game.guessedPoints,
                    tickValues: game.getRankThresholds(),
                    minValueLabel: {
                        Text("\(game.rank.rawValue)")
                            .font(.body.bold())
                            .foregroundColor(AppColors.colorMain)
                    }, maxValueLabel: {
                        Text("\(maxValue)")
                    })
            }

            //** WORDS FOUND
            Button {
                showWordsFound.toggle()
            } label: {
                VStack {
                    HStack {
                        Text(showWordsFound
                             ? "You found \(game.guessedWords.count) words:"
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
                                let words = getWordsByAlpha()
                                let midpoint = words.count == 0 ? 0 : words.count / 2 + 1
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(words[..<midpoint], id: \.self) { word in
                                        Text(word)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 8)
                                    }
                                }

                                // Second column
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(words[midpoint...], id: \.self) { word in
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
            Spacer(minLength: 40)
            
            if (!showWordsFound) {
                // Word Entry
                //TODO: TextField shows cursor, but couldn't prevent keyboard from popping up
//                TextField(
//                    "",
//                    text: $game.enteredWord
//                )
//                .font(Font.system(size: 50, weight: .heavy, design: .monospaced))
//                .foregroundColor(.black)
//                .textInputAutocapitalization(.characters)
//                .autocorrectionDisabled(true)
//                .disableAutocorrection(true)
//                .textContentType(.name)
//                //                    .focused($wordEntryFocused)
//                .multilineTextAlignment(.center)
//                .onSubmit {
//                    onSubmit()
//                }
//                //.disabled(true)
//                .focused($textFocused)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 5)
//                        .stroke(Color.gray)
//                )
//                .padding(.horizontal, 0)//PADDING_HORIZONTAL)
//                .onAppear {
//                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
//                        textFocused = true
//                    }
//                }
//
                //** WORD ENTRY
                Text(game.enteredWord)
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
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray)
                    )
                    .padding(.horizontal, 0)//PADDING_HORIZONTAL)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                            textFocused = true
                        }
                    }

                //** MATCHING WORDS HINT
                if hintsEnabled {
                    if showHint {
                        Text(game.numWordsWithPrefix == -1 ? " " :
                                "\(game.numWordsWithPrefix) matching words"
                        )
                        //.transition(.opacity.combined(with: .move(edge: .leading)))
                        .transition(.opacity)  // .blurReplace
                        .frame(height: 30)
                        .padding()
                    } else {
                        Button {
                            withAnimation() {
                                showHint = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation() {
                                    showHint = false
                                }
                            }
                        } label: {
                            Text("Show hint")
                                .frame(height: 30)
                        }
                        .disabled(showHint || game.numWordsWithPrefix == -1)
                        .transition(.opacity)
                        .buttonStyle(.bordered)
                        // need frame/padding too so it's same height as "2 matching words" Text
                        .frame(height: 30)
                        .padding()
                    }
                }

                //** HONEYCOMB
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
                        outerColor: $hexagonColor,
                        centerColor: $centerHexagonColor,
                        onTap: { text, isCenter in
                            if soundsEnabled { Sounds.playSound(.softClick) }
                            logger.debug("Honeycomb letter entered: \(text), isCenter: \(isCenter)")
                            updateEnteredWord(text: game.enteredWord + text)
                        }
                    )//.border(.red)
                }
                .frame(height: 300)

                //** BUTTON ROW
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
                                if soundsEnabled { Sounds.playSound(.erase1) }
                            }
                            .onLongPressGesture(minimumDuration: 0.1) {
                                updateEnteredWord(text: "")
                                if soundsEnabled { Sounds.playSound(.erase1) }
                            }

                        //                        }
                    }
                    .tint(hexagonColor)
                    .disabled(game.outerLetters.isEmpty || game.enteredWord.isEmpty)
                    .buttonStyle(.borderedProminent)
                    
                    // Shuffle Button
                    Button {
                        isShuffling = true
                        if soundsEnabled { Sounds.playSound(.shuffle1) }
                    } label: {
                        Image(systemName: "shuffle")
                            .resizable()
                            .scaledToFit()
                            .padding(.all, 10)
                            .frame(width: 50, height: 50)
                    }
                    .tint(hexagonColor)
                    .disabled(game.outerLetters.isEmpty)
                    .buttonStyle(.borderedProminent)
                    
                    // Enter Button
                    Button {
                        onSubmit()
                    } label: {
                        Text("**Enter**")
                            .frame(width: 80, height: 50)
                    }
                    .tint(hexagonColor)
                    .disabled(game.outerLetters.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .padding(.all, 12 + PADDING_HORIZONTAL)
        
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

//ios16        .sheet(isPresented: $showNewGameModal, content: {
        .halfSheet(showSheet: $showNewGameModal, content: {
            VStack {
                ZStack {
                    Text("New Game")
                        .font(.title)
                    HStack {
                        Spacer()
                        Button {
                            showNewGameModal = false
                        } label: {
                            Image(systemName: "xmark.circle")
                                .resizable()
                                .scaledToFit()
                                .padding(.all, 10)
                                .frame(width: 50, height: 50)
                        }
                    }
                    .padding(.top, 5)
                }
                Spacer()

                Picker("Difficulty", selection: $game.difficultyLevel) {
                    Text("Kids").tag(GameState.DifficultyLevel.kids)
                    Text("Easy").tag(GameState.DifficultyLevel.easy)
                    Text("Medium").tag(GameState.DifficultyLevel.medium)
                    Text("Hard").tag(GameState.DifficultyLevel.hard)
                }
                .frame(height: 50)
                .pickerStyle(.segmented)
                .padding()
                Spacer()
                Button {
                    showNewGameModal = false
                    restartGame()
                } label: {
                    Text("Start Game")
                        .frame(height: 50)
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.borderedProminent)
            }
//ios16            .presentationDetents([.height(300)])
        }, onDismiss: {
            logger.debug("new game modal dismissed")
        })

//ios16        .sheet(isPresented: $showSettingsModal, content: {
        .halfSheet(showSheet: $showSettingsModal, content: {
            VStack {
                ZStack {
                    Text("Settings")
                        .font(.title)
                    HStack {
                        Spacer()
                        Button {
                            showSettingsModal = false
                        } label: {
                            Image(systemName: "xmark.circle")
                                .resizable()
                                .scaledToFit()
                                .padding(.all, 10)
                                .frame(width: 50, height: 50)
                        }
                    }
                    .padding(.top, 5)
                }

                Toggle(isOn: $hintsEnabled, label: {
                    Text("Enable word match hints")
                })
                .padding()
                Toggle(isOn: $soundsEnabled, label: {
                    Text("Play sounds")
                })
                .padding()
                //TODO: custom button: https://switch2mac.medium.com/colorpicker-with-custom-styled-button-b5f0e701972d
//                    HexagonButton(
//                        text: "",
//                        rect: CGRect(x: 0, y: 0, width: 30, height: 30),
//                        textColor: Color.white,
//                        backgroundColor: hexagonColorState,
//                        { text in
//                            ColorPicker("set the color", selection: $hexagonColor)
//                        }
//                    )
                ColorPicker("Outer Hexagon Color", selection: $hexagonColor)
                    .padding()
                ColorPicker("Center Hexagon Color", selection: $centerHexagonColor)
                    .padding()
                Spacer()
            }
            .foregroundStyle(Color.blue)
//ios16            .presentationDetents([.height(300)])
        }, onDismiss: {
            logger.debug("settings modal dismissed")
        })
    }
}

#Preview {
    Group {
        let game = GameState()
        let _ = {
            game.outerLetters = "CTDREO"
            game.centerLetter = "B"
            game.guessedWords = ["hello", "this", "word", "great", "again", "amazing", "another", "telephone"]
            game.guessedPoints = 123
            game.possiblePoints = 150
        }()
        ContentView(game: game, dictionary: Trie())
    }
}
