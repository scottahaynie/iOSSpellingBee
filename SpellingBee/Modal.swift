//
//  Modal.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/26/25.
//

import SwiftUI

struct Modal<Content: View>: View {
    @Binding var showModal: Bool
    let dismissOnTapOutside: Bool
    let content: Content // content of the modal
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.gray.opacity(0.7))
                .ignoresSafeArea()
                .onTapGesture {
                    if dismissOnTapOutside {
                        withAnimation {
                            showModal = false
                        }
                    }
                }
//            RoundedRectangle(cornerRadius: 30)
//                .foregroundColor(Color.white)
//                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.gray.opacity(0.2), lineWidth: 1))
//                .shadow(color: Color.gray.opacity(0.4), radius: 4)
//                .onTapGesture() {
//                    if dismissOnTapOutside {
//                        withAnimation {
//                            showModal = false
//                        }
//                    }
//                }
            
//            ScrollView {
            content
//            }
//            .padding()
//            .padding(.top, CGFloat(24))
            .frame(
                width: UIScreen.main.bounds.size.width - 100, height: 300)
            .padding()
            .padding(.top, CGFloat(24))
            //.padding(.vertical, 40)
            .background(.white)
            .cornerRadius(12)
            .overlay(alignment: .topTrailing) {
                Button(action: {
                    withAnimation {
                        showModal = false
                    }
                }, label: {
                    Image(systemName: "xmark.circle")
                })
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundStyle(Color.gray.opacity(0.7))
                .padding(.all, 8)
            }

            
//            VStack {
//                Spacer()
//                ModalButton(showModal: self.$showModal)
//            }.padding(.vertical)
            
        }
        //.padding(50)
        .ignoresSafeArea(.all)
        .frame(
            width: UIScreen.main.bounds.size.width, 
            height: UIScreen.main.bounds.size.height,
            alignment: .center
        )
    }
}

extension Modal {

    init(showModal: Binding<Bool>,
         dismissOnTapOutside: Bool = true,
         @ViewBuilder _ content: () -> Content) {
        _showModal = showModal
        self.dismissOnTapOutside = dismissOnTapOutside
        self.content = content()
    }
}

#Preview {
    Modal(showModal: .constant(false)) {
        Text("Content")
    }
}
