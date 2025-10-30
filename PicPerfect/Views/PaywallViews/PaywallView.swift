//
//  PaywallView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/23/25.
//

import SwiftUI
import RevenueCat
import FirebaseAnalytics

struct PaywallView: View {
    
    @Environment(ContentModel.self) var model
    
    @State private var selectedPackage: Package? = nil
    
    @State private var isPurchasing: Bool = false
    
    @State private var purchaseErroAlertPresent: Bool = false
    @State private var restoreErrorAlertPresent: Bool = false
    
    let backgroundImage = Image("marquee4")
    
    let language = LanguageHelper.language()
    let device = DeviceHelper.type
    
    var body: some View {
        
        ZStack {
            
            VStack {
                
                DismissButton {
                    model.showPaywall = false
                }
                
                BenefitCards()
                    .padding()
                
                Text("Family Sharing Included!")
                    .foregroundStyle(.yellow)
                    
                
                ForEach(model.offerings?.availablePackages ?? [], id: \.identifier) { package in
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .applyGlassIfAvailable()
                        
                        VStack(spacing: 5) {
                            
                            Text(package.storeProduct.localizedTitle)
                                .font(.headline)
                            
                            Text(package.storeProduct.localizedDescription)
                                .font(.subheadline)
                            
                            HStack(spacing: 0) {
                                
                                Text("\(package.storeProduct.currencyCode ?? "USD") ")
                                
                                Text(package.storeProduct.localizedPriceString)
                                    
                                Text(" / \(period(package: package))")
                                    .font(.title2)
                            }
                            .font(.title2)
                            
                            Text(breakDownPeriod(package: package))
                                .font(.caption)
                                .foregroundStyle(.yellow)
                                .bold()
                        }
                        .padding(10)
                        .foregroundStyle(.white)
                        .disabledView(selectedPackage?.identifier != package.identifier)
                    }
                    .overlay {
                        if selectedPackage?.identifier == package.identifier {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        }
                    }
                    .padding(5)
                    .onTapGesture {
                        selectedPackage = package
                        Analytics.logEvent("select_store_package", parameters: ["package_id": package.identifier])
                    }
                    
                    
                    
                }
                
                Button {
                    if let package = selectedPackage {
                        isPurchasing = true
                        
                        Task {
                            await model.purchase(package: package) { success in
                                if success {
                                    isPurchasing = false
                                    model.showPaywall = false
                                }
                                else {
                                    isPurchasing = false
                                    purchaseErroAlertPresent = true
                                }
                                
                                Analytics.logEvent("tap_purchase", parameters: ["with_success": success] )
                            }
                        }
                    }
                } label: {
                    Text("Get PicPerfect+")
                }
                .padding()
                .ifAvailableGlassButtonStyle()
                .alert("Purchase not completed", isPresented: $purchaseErroAlertPresent) {
                    Button("Try again") {
                        purchaseErroAlertPresent = false
                        isPurchasing = true
                        if let package = selectedPackage {
                            Task {
                               await  model.purchase(package: package) { success in
                                    if success {
                                        isPurchasing = false
                                        model.showPaywall = false
                                    }
                                    else {
                                        isPurchasing = false
                                        purchaseErroAlertPresent = true
                                    }
                                   
                                   Analytics.logEvent("tap_purchase_retry", parameters: ["with_success": success])
                                }
                            }
                        }
                    }
                    
                    Button("Cancel") {
                        model.showPaywall = false
                    }
                }
                
                HStack(alignment: .top) {
                    Button("Restore Purchases") {
                        isPurchasing = true
                        Task {
                            await  model.restorePurchases { success in
                                if success {
                                    isPurchasing = false
                                    model.showPaywall = false
                                }
                                else {
                                    isPurchasing = false
                                    restoreErrorAlertPresent = true
                                }
                            }
                            
                            Analytics.logEvent("tap_restore_purchase", parameters: ["is_subscribed": model.isUserSubscribed])
                        }

                    }
                    .buttonStyle(.borderless)
                    .alert("No active subscription.", isPresented: $restoreErrorAlertPresent) {
                        Button("ok") {
                            restoreErrorAlertPresent = false
                        }
                    }
                    
                    Spacer()
                    
                    if let url = URL(string: "https://www.artexcomputer.net/picperfectterms") {
                        Link("Privacy Policy & Terms of Service", destination: url)
                    }
                    
                }
                .padding(.horizontal, 40)
                .foregroundStyle(.white)
                .font(.caption)

            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background {
                backgroundImage
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(.container)
                    .blur(radius: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        AnimatedMesh()
                            .opacity(0.4)
                            .blendMode(.overlay)
                    }
                
            }
            
            ProgressView {
                Text("Processing…")
            }
            .tint(.white)
            .foregroundStyle(.white)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(.black)
                    
            }
            .isPresent(isPurchasing)
        }
        .onAppear {
            selectedPackage = model.offerings?.availablePackages.first(where: {$0.packageType == .annual})
        }
        .analyticsScreen(name: "PaywallView", class: "paywall_view", extraParameters: [
            "device_type": device.rawValue
        ])
        
    }
    
    func breakDownPeriod(package: Package) -> String {
        // Use RevenueCat's localized price string and the subscription period.
        let price: Double = package.storeProduct.priceDecimalNumber.doubleValue
        let period = package.storeProduct.subscriptionPeriod?.unit
        let pricePerWeek = price / 52
        
        if period == .year {
            switch language {
            case .english:
                return String(format: "$%.2f per week", pricePerWeek)
            case .spanish:
                return String(format: "$%.2f por semana", pricePerWeek)
            }
        }
        
        return ""
    }
    
    func period(package: Package) -> String {
        let period = package.storeProduct.subscriptionPeriod?.unit
        
        switch period {
        case .day:
            return language == .english ? "day" : "día"
        case .none:
            return ""
        case .some(.week):
            return language == .english ? "week" : "semana"
        case .some(.month):
            return language == .english ? "month" : "mes"
        case .some(.year):
            return language == .english ? "year" : "año"
        }
        
   
    }
    
}

#Preview {
    PaywallView()
        .environment(ContentModel())
}


struct AnimatedMesh: View {
    
    @State private var appear = false
    var body: some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0]
                    , [0.5, 0], [1, 0],
                    [0, 0.5], appear ? [0.5, 0.5] : [0.8, 0.2], [1, 0.5],
                    [0, 1], [2.5, 1], [1, 1]
                ],
                colors: [
                    .black,
                    .orange.opacity(0.8),
                    .yellow.opacity(0.7),
                    .black,
                    .orange.opacity(0.8),
                    .yellow.opacity(0.7),
                    .black,
                    .orange.opacity(0.8),
                    .yellow.opacity(0.7)
                ],
                smoothsColors: true
            )
            .ignoresSafeArea()

            .onAppear {
                withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                    // movimiento sutil en los puntos
                    appear.toggle()
                }
            }
        } else {
            LinearGradient(
                colors: [.black, .orange, .yellow, .white],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .opacity(0.6)
            .ignoresSafeArea()
        }
        #else
        if #available(macOS 15.0, *) {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0]
                    , [0.5, 0], [1, 0],
                    [0, 0.5], appear ? [0.5, 0.5] : [0.8, 0.2], [1, 0.5],
                    [0, 1], [2.5, 1], [1, 1]
                ],
                colors: [
                    .black,
                    .orange.opacity(0.8),
                    .yellow.opacity(0.7),
                    .black,
                    .orange.opacity(0.8),
                    .yellow.opacity(0.7),
                    .black,
                    .orange.opacity(0.8),
                    .yellow.opacity(0.7)
                ],
                smoothsColors: true
            )
            .ignoresSafeArea()

            .onAppear {
                withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                    // movimiento sutil en los puntos
                    appear.toggle()
                }
            }
        } else {
            LinearGradient(
                colors: [.black, .orange, .yellow, .white],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .opacity(0.6)
            .ignoresSafeArea()
        }
        #endif
    }
}

