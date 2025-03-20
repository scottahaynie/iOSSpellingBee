//
//  ProgressBar.swift
//  SpellingBee
//
//  Created by Scott Haynie on 3/19/25.
//

import SwiftUI

struct SpellingBeeGauge<MinLabel: View, MaxLabel: View>: View {
    @Binding var minValue: Int
    @Binding var maxValue: Int
    @Binding var value: Int
    let minValueLabel: () -> MinLabel
    let maxValueLabel: () -> MaxLabel

    var body: some View {
        HStack {
            minValueLabel()
                .padding(.trailing, 15)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(height: 5)
                        .foregroundStyle(.gray.opacity(0.5))
                    let ticks = [0.00, 0.02, 0.05, 0.08, 0.15, 0.25, 0.40, 0.50, 0.70]
                    ForEach(ticks, id:\.self) { tick in
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
        minValue: .constant(0),
        maxValue: .constant(100),
        value: .constant(57),
        minValueLabel: {
            Text("Great")
                .font(.body.bold())
                .foregroundColor(.blue)
        }, maxValueLabel: {
            Text("100 pts")
        })
        .padding()
}
