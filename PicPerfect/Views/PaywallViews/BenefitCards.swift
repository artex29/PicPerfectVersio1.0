//
//  BenefitCards.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/23/25.
//

import SwiftUI

struct Benefit: Identifiable {
    var id:String {
        "\(text)-\(isLimit)"
    }
    
    let text: String
    let isLimit: Bool
}

struct BenefitCards: View {
    
    @State private var startRotation = false
   
    
    var benefits: [Benefit] = [
        Benefit(text: "Priority access to new tools & updates", isLimit: false),
        Benefit(text: "Unlimited photo scans", isLimit: false),
        Benefit(text: "Face, blur & exposure analysis", isLimit: false),
        Benefit(text: "No waiting times between scans", isLimit: true)
    ]
    
    @State var cardsPositions: [String: CGSize] = [:]
    @State private var textPresent:[String: Bool] = [:]
    @State private var cardRotations: [String: Angle] = [:]
    
    var body: some View {
        ZStack {
            
            ForEach(benefits.indices, id: \.hashValue) { index in
                let benefit = benefits[index]
                
                BenefitCard(textPresent: $textPresent,
                            benefit: benefit,
                            rotationAngle: cardRotation(index: index))
                .id(benefit.id)
                .offset(cardsPositions[benefit.id] ?? .zero)
                .rotationEffect(cardRotations[benefit.id] ?? .zero)
                .onAppear {
                    cardsPositions[benefit.id] = .zero
                    textPresent[benefit.id] = index == benefits.count - 1
                   
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    startRotation = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                
                dismissCardsAnimation()
                
            }
        }
        .onChange(of: benefits.count) { oldValue, newValue in
            if newValue != oldValue {
                withAnimation {
                    startRotation = true
                }
            }
        }
    }
    
    func cardRotation(index: Int) -> Angle {
        
        var angle = Angle(degrees: 0)
        
        if startRotation {
            angle = Angle(degrees: Double(benefits.count -  index - 1) * 5.0)
            return angle
        }
        
        return angle
    }
    
    func dismissCardsAnimation() {
        // 1️⃣ Animación de salida (reversa)
        for (index, benefit) in benefits.enumerated().reversed() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(benefits.count - index) * 3.0) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    let width = benefit.isLimit ? -800 : 800
                    cardsPositions[benefit.id] = CGSize(width: width, height: 0)
                    cardRotations[benefit.id] = Angle(degrees: benefit.isLimit ? -45 : 45)
                    // mostrar texto siguiente
                    if index > 0 {
                        if let nextTextElementID = textPresent.first(where: { $0.key == benefits[index - 1].id })?.key {
                            textPresent[nextTextElementID] = true
                        }
                    }
                }
            }
        }
        
        // 2️⃣ Reset después de terminar la secuencia
        let totalDuration = Double(benefits.count + 1) * 2.8
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            for (index, benefit) in benefits.enumerated() {
                withAnimation {
                    cardsPositions[benefit.id] = .zero
                    textPresent[benefit.id] = index == benefits.count - 1
                    cardRotations[benefit.id] = .zero
                }
            }
            
            // 3️⃣ Repetir indefinidamente
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // delay opcional entre ciclos
                dismissCardsAnimation()
            }
        }
    }
}


struct BenefitCard: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var textPresent: [String: Bool]
    @State var benefit:Benefit
    var rotationAngle: Angle
    
    let device = DeviceHelper.type
    
    var body: some View {
        
        ZStack(alignment: .center) {
            
            if colorScheme == .light {
                RoundedRectangle(cornerRadius: 20)
                    .applyGlassIfAvailable()
            }
            else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(cgColor: .init(red: 0, green: CGFloat.random(in: 0.1...0.8), blue: CGFloat.random(in: 0...0.5), alpha: 1)))
                    .opacity(0.5)
            }
           
              
            
               
            
            if textPresent[benefit.id] ?? false {
                Text(benefit.text)
                    .font(.title3.weight(.semibold))
                    .padding()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(width: 200, height: 300)
        .rotationEffect(rotationAngle, anchor: .bottomTrailing)
    }
    
    
}

#Preview {
    BenefitCards()
}
