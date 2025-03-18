//
//  Honeycomb.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/21/25.
//

import SwiftUI
import OSLog

// allows specifying colors by hex. eg. Color(hex: 44AAFF)
extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}

// allows for s[5] on Strings
extension String {
    subscript(i: Int) -> Character {
        self[index(startIndex, offsetBy: i)]
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // bounding rect is already centered, so center of rect is the center
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let sideLength = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let angle = CGFloat(i) * CGFloat.pi * 2 / 6
            let x = center.x + cos(angle) * sideLength
            let y = center.y + sin(angle) * sideLength
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct HexagonButton: View {
    private var text: String
    private var rect: CGRect
    private var textColor: Color
    private var backgroundColor: Color
    private var action: (String) -> Void

    init(text: String, rect: CGRect, textColor: Color, backgroundColor: Color, _ action: @escaping (String) -> Void) {
        self.text = text
        self.rect = rect
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: text.isEmpty ? {} : {action(text)}) {
            Text(text)
                //.font(Font.custom("Arial", fixedSize: 50))
                .font(Font.system(size: 50, weight: .heavy, design: .monospaced))
                //.bold()
                .contentTransition(.numericText()) // needs withAnimation around newGame
                .foregroundColor(self.textColor)
                .padding()
                .frame(width: self.rect.width, height: self.rect.height)
                .background(HexagonShape().fill(self.backgroundColor))
                .overlay(HexagonShape().stroke(Color.white, lineWidth: 2))
//                .frame(width: self.rect.width, height: self.rect.height)
                .shadow(radius: 5)
        }
        //.buttonStyle(PlainButtonStyle()) // Removes default button styling
        .buttonStyle(ScaleButtonStyle())
        .position(self.rect.origin) // positions the CENTER of the view
        //.animation(.easeInOut(duration: 1.0), value: self.rect.minX)
    }
}

struct Honeycomb: View {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                        category: String(describing: Honeycomb.self))

    var outerLetters: String
    var centerLetter: String
    //TODO: rect should be the rect of all hexagons, not just one
    var rect: CGRect
    @Binding var isShuffling: Bool
    var onTap: (String, Bool) -> Void
    
    @State private var positions: [CGPoint] = [
        CGPoint(x: 0, y: 0),
        CGPoint(x: 0, y: 0),
        CGPoint(x: 0, y: 0),
        CGPoint(x: 0, y: 0),
        CGPoint(x: 0, y: 0),
        CGPoint(x: 0, y: 0)
    ]

    private static func getHexagonPoint(i: Int, x: CGFloat, y: CGFloat, size: CGFloat) -> CGPoint {
        // 0-5 clockwise. 0 = lower-right, 5 = upper-right
        let angle = CGFloat(i) * CGFloat.pi * 2 / 6 + (CGFloat.pi / 6)
        return CGPoint(x: x + cos(angle) * size * 1.9, y: y + sin(angle) * size * 1.9)
    }

    private func initPositions() {
        let center = self.rect.origin
        let sideLength = min(self.rect.width, self.rect.height) / 2
        for i in 0..<6 {
            positions[i] = Honeycomb.getHexagonPoint(i: i, x: center.x, y: center.y, size: sideLength)
        }
    }

    private func shufflePositions() {
        // shuffle until all positions have changed
        while(true) {
            let positionsNew = positions.shuffled()
            if (positionsNew.enumerated().first(where: { positionsNew[$0.offset] == positions[$0.offset]}) == nil) {
                positions = positionsNew
                break
            }
        }
    }

    private func createHexagonButtons(isShuffling: Bool) -> some View {
        // rect is the center hexagon rect
        ZStack {
            ForEach(0..<6, id: \.self) { index in
               HexagonButton(
                   text: self.outerLetters.isEmpty ? "" : String(self.outerLetters[index]),
                   rect: CGRect(origin: positions[index], size: self.rect.size),
                   textColor: Color.white,
                   backgroundColor: Color.blue,
                   { text in
                       logger.debug("hexagon button tapped \(index)")
                       self.onTap(text, false)
                   }
               )
            }
            HexagonButton(
                text: centerLetter,
                rect: self.rect,
                textColor: Color.white,
                backgroundColor: Color.indigo,
                { text in
                    logger.debug("center hexagon tapped")
                    self.onTap(text, true)
                }
            )
        }
    }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                createHexagonButtons(isShuffling: isShuffling)
            }
            .onAppear {
                initPositions()
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                initPositions()
            }
            .onChange(of: isShuffling) { oldValue, newValue in
                if newValue {
                    withAnimation(.bouncy(duration: 1.0)) {
                        shufflePositions()
                    }
                    isShuffling = false
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isShuffling: Bool = false
    Group {
        Button("Shuffle") {
            isShuffling = true
        }
        GeometryReader { geo in
            Honeycomb(
                outerLetters: "ABCDEF",
                centerLetter: "O",
                rect: CGRect(x: geo.size.width / 2,
                             y: geo.size.height / 2,
                             width: 100,
                             height: 100),
                isShuffling: $isShuffling, //.constant(false),
                onTap: { text, isCenter in
                    print("Honeycomb letter tapped: \(text), is center: \(isCenter)")
                }
            )
        }
    }
}
