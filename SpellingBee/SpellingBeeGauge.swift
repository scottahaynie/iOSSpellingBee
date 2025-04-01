//
//  ProgressBar.swift
//  SpellingBee
//
//  Created by Scott Haynie on 3/19/25.
//

import SwiftUI

struct SpellingBeeGauge<MinLabel: View, MaxLabel: View>: View {
    var minValue: Int
    var maxValue: Int
    var value: Int
    var tickValues: [Int]
    let minValueLabel: () -> MinLabel
    let maxValueLabel: () -> MaxLabel

    private let tickPercents: [Double]
    
    init(minValue: Int, maxValue: Int, value: Int, tickValues: [Int] = [], minValueLabel: @escaping () -> MinLabel, maxValueLabel: @escaping () -> MaxLabel) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.value = value
        self.tickValues = tickValues
        self.minValueLabel = minValueLabel
        self.maxValueLabel = maxValueLabel
        
        self.tickPercents = self.tickValues.map { Double($0) / Double((maxValue - minValue)) }
    }

    var body: some View {
        HStack {
            minValueLabel()
                .padding(.trailing, 15)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(height: 5)
                        .foregroundStyle(.gray.opacity(0.5))
                    ForEach(tickPercents, id:\.self) { tick in
                        Rectangle()
                            .frame(width: 4, height: 10)
                            .offset(x: geo.size.width * tick)
                            .foregroundStyle(.white)
                            .overlay {
                                Rectangle()
                                    .frame(width: 2, height: 15)
                                    .offset(x: geo.size.width * tick)
                                    .foregroundStyle(.black)
                            }
                    }
                    let xProgress = geo.size.width * min(CGFloat(value) / CGFloat(maxValue - minValue), 1.0)
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: xProgress, height: 5)
                        .foregroundStyle(AppColors.colorMain)
                    Circle()
                        .fill(AppColors.colorMain).opacity(0.8)
                        .frame(width: 30, height: 30)
                        .scaleEffect(1.3)
                        .offset(x: xProgress - (30 / 2))
                    Text("\(value)")
                        .fixedSize()
                        .frame(width: 30, height: 30)
                        .offset(x: xProgress - (30 / 2))
                        .foregroundStyle(.white)
                        //ios16 .fontWeight(.heavy)
                        .font(.body.weight(.heavy))
                }
            }
            .frame(height: 28) // needed to keep things v-centered because of GR
            maxValueLabel()
                .padding(.leading, 15)
        }
        .contentShape(Rectangle())
    }
}

//iOS16
//struct SpellingBeeGaugeStyle: GaugeStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        HStack {
//            configuration.minimumValueLabel
//                .padding(.trailing, 15)
//            GeometryReader { geo in
//                ZStack(alignment: .leading) {
//                    RoundedRectangle(cornerRadius: 5)
//                        .frame(height: 5)
//                        .foregroundStyle(.gray.opacity(0.5))
//                    let ticks = [0.00, 0.02, 0.05, 0.08, 0.15, 0.25, 0.40, 0.50, 0.70]
//                    ForEach(ticks, id:\.self) { tick in
//                        Rectangle()
//                            .frame(width: 4, height: 10)
//                            .offset(x: geo.size.width * tick)
//                            .foregroundStyle(.white)
//                            .overlay {
//                                Rectangle()
//                                    .frame(width: 2, height: 15)
//                                    .offset(x: geo.size.width * tick)
//                                    .foregroundStyle(.black)
//                            }
//                    }
//                    RoundedRectangle(cornerRadius: 5)
//                        .frame(width: geo.size.width * configuration.value, height: 5)
//                        .foregroundStyle(AppColors.colorMain)
//                    Circle()
//                        .fill(AppColors.colorMain).opacity(0.7)
//                        .frame(width: 30, height: 30)
//                        .scaleEffect(1.3)
//                        .offset(x: geo.size.width * configuration.value - (30 / 2))
//                    configuration.currentValueLabel
//                        .fixedSize()
//                        .frame(width: 30, height: 30)
//                        .offset(x: geo.size.width * configuration.value - (30 / 2))
//                        .foregroundStyle(.white)
//                        //.fontWeight(.heavy)
//                        .font(.body.weight(.heavy))
//                }
//            }
//            .frame(height: 28) // needed to keep things v-centered because of GR
//            configuration.maximumValueLabel
//        }
//    }
//}

#Preview("Great") {
    SpellingBeeGauge(
        minValue: 0,
        maxValue: 70,
        value: 45,
        tickValues: [0,2,5,8,15,25,40,50,70],
        minValueLabel: {
            Text("Great")
                .font(.body.bold())
                .foregroundColor(.blue)
        }, maxValueLabel: {
            Text("100 pts")
        })
        .padding()
}

#Preview("At Genius") {
    SpellingBeeGauge(
        minValue: 0,
        maxValue: 70,
        value: 70,
        tickValues: [0,2,5,8,15,25,40,50,70],
        minValueLabel: {
            Text("Genius")
                .font(.body.bold())
                .foregroundColor(.blue)
        }, maxValueLabel: {
            Text("100 pts")
        })
        .padding()
}

#Preview("Past Genius") {
    SpellingBeeGauge(
        minValue: 0,
        maxValue: 70,
        value: 85,
        tickValues: [0,2,5,8,15,25,40,50,70],
        minValueLabel: {
            Text("Genius")
                .font(.body.bold())
                .foregroundColor(.blue)
        }, maxValueLabel: {
            Text("100 pts")
        })
        .padding()
}
