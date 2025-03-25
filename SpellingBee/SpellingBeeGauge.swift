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
                    let xProgress = geo.size.width * CGFloat(value) / CGFloat(maxValue - minValue)
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
        }
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

#Preview {
    SpellingBeeGauge(
        minValue: 0,
        maxValue: 100,
        value: 57,
        tickValues: [0,5,10,20,40,80,100],
        minValueLabel: {
            Text("Great")
                .font(.body.bold())
                .foregroundColor(.blue)
        }, maxValueLabel: {
            Text("100 pts")
        })
        .padding()
}
