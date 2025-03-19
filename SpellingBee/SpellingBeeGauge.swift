//
//  ProgressBar.swift
//  SpellingBee
//
//  Created by Scott Haynie on 3/19/25.
//

import SwiftUI

struct SpellingBeeGaugeStyle: GaugeStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.minimumValueLabel
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
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: geo.size.width * configuration.value, height: 5)
                        .foregroundStyle(AppColors.colorMain)
                    Circle()
                        .fill(AppColors.colorMain).opacity(0.7)
                        .frame(width: 30, height: 30)
                        .scaleEffect(1.3)
                        .offset(x: geo.size.width * configuration.value - (30 / 2))
                    configuration.currentValueLabel
                        .fixedSize()
                        .frame(width: 30, height: 30)
                        .offset(x: geo.size.width * configuration.value - (30 / 2))
                        .foregroundStyle(.white)
                        .fontWeight(.heavy)
                }
            }
            .frame(height: 28) // needed to keep things v-centered because of GR
            configuration.maximumValueLabel
        }
    }
}

#Preview {
    Gauge(value: 0, in: 0.0...300.0) {
        Text("Progress")
    } currentValueLabel: {
        Text("0")
    } minimumValueLabel: {
        Text("Beginner")
        //                            .transition(AnyTransition.opacity.animation(.easeInOut(duration:1.0)))
            .bold()
            .foregroundStyle(.blue)
        //.foregroundStyle(
        //.shadow(color: .green, radius: 3)
        //.foregroundStyle(.shadow(.drop(radius: 3)))
    } maximumValueLabel: {
        Text("300")
    }
    //.frame(height: 400)
    .padding()
    .gaugeStyle(SpellingBeeGaugeStyle())
}
