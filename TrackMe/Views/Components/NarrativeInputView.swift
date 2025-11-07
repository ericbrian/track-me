import SwiftUI

/// Sheet for entering a narrative description before starting tracking
struct NarrativeInputView: View {
    @Binding var narrative: String
    @Environment(\.presentationMode) var presentationMode
    let onStart: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(spacing: 8) {
                            Text("Describe Your Journey")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Add a description to help you remember this tracking session")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)

                    // Text input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(narrative.isEmpty ? Color.clear : Color.blue.opacity(0.5), lineWidth: 2)
                                )

                            if narrative.isEmpty {
                                Text("Enter a description for this tracking session...")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }

                            TextEditor(text: $narrative)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                        }
                    }

                    // Example suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggestions")
                            .font(.headline)
                            .fontWeight(.semibold)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            SuggestionCard(text: "Morning jog around the neighborhood", icon: "figure.run") {
                                narrative = "Morning jog around the neighborhood"
                            }

                            SuggestionCard(text: "Drive to work", icon: "car.fill") {
                                narrative = "Drive to work"
                            }

                            SuggestionCard(text: "Weekend hiking trip", icon: "mountain.2.fill") {
                                narrative = "Weekend hiking trip"
                            }

                            SuggestionCard(text: "Bicycle ride to the park", icon: "bicycle") {
                                narrative = "Bicycle ride to the park"
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    // Start button
                    Button(action: {
                        onStart()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                            Text("Start Tracking")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                    [Color.gray, Color.gray.opacity(0.8)] :
                                    [Color.green, Color.green.opacity(0.8)]
                                ),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(
                            color: (narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.green).opacity(0.3),
                            radius: 8, x: 0, y: 4
                        )
                    }
                    .disabled(narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .scaleEffect(narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: narrative.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
            )
        }
    }
}

struct SuggestionCard: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)

                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
