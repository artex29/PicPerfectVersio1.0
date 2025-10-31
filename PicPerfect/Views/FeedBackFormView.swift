//
//  FeedBackFormView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/29/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseAnalytics

struct FeedbackFormView: View {
    
    @Environment(ContentModel.self) var model
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var category = LocalizedStringKey("suggestion").stringValue
    @State private var message = ""
    @State private var isSending = false
    @State private var sent = false
    @State private var allowContact = false
    
    @Binding var messageSent: Bool

    let categories = [
        LocalizedStringKey("suggestion").stringValue,
        LocalizedStringKey("problem").stringValue,
        LocalizedStringKey("compliment").stringValue,
        LocalizedStringKey("other").stringValue
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                
                DismissButton {
                    model.feedbackFormPresent = false
                }
                
                Text("We’d love to hear from you 💬")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Your feedback helps us improve. Please fill out this short form:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Group {
                    TextField("Your name", text: $name)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Email address", text: $email)
                        .textContentType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                        .keyboardType(.emailAddress)
                    #endif
                    
                    Picker("", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0)}
                    }
                    .pickerStyle(.segmented)
                    
                    
                    TextEditor(text: $message)
                        .frame(height: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.9), lineWidth: 1)
                        )
                    
                    Toggle(.allowContactUser, isOn: $allowContact)
                }

                if isSending {
                    ProgressView()
                } else {
                    Button(action: {
                        Task { await sendFeedback() }
                    }) {
                        Text("Send Feedback")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!isFormValid)
                }

                if sent {
                    Label(.thankingForFeedback, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                }
            }
            .padding()
          
        }
        .analyticsScreen(name: "FeedbackFormView", class: "feedback_form_view")
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !message.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func sendFeedback() async {
        guard isFormValid else { return }
        isSending = true

        let db = Firestore.firestore()
        let feedback: [String: Any] = [
            "uid": Auth.auth().currentUser?.uid ?? "unknown",
            "name": name,
            "email": email,
            "category": category,
            "message": message,
            "allowContact": allowContact,
            "timestamp": Timestamp(date: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "platform": "iOS"
        ]

        do {
            try await db.collection("feedbacks").addDocument(data: feedback)
            
            sent = true
            clearForm()
            messageSent = true
            dismiss()
            
            Analytics.logEvent("feedback_form_submitted", parameters: feedback)
            
        } catch {
            print("❌ Error sending feedback: \(error.localizedDescription)")
            Analytics.logEvent("user_feedback_failed", parameters: [
                "error": error.localizedDescription
            ])
        }

        isSending = false
    }

    private func clearForm() {
        name = ""
        email = ""
        category = LocalizedStringKey("suggestion").stringValue
        message = ""
    }
}


#Preview {
    FeedbackFormView(messageSent: .constant(false))
        .environment(ContentModel())
}
