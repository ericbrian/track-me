import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Always keep List in hierarchy to prevent UICollectionView inconsistency
                List {
                    if viewModel.sessions.isEmpty {
                        EmptyHistoryView()
                    } else {
                        ForEach(viewModel.sessions, id: \.objectID) { session in
                            ModernSessionRowView(session: session)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Tracking History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .onAppear {
                viewModel.attach(context: viewContext)
            }
        }
        .navigationViewStyle(.stack)
        .onDisappear {
            // Avoid FRC delegate callbacks after view disappears
            viewModel.detach()
        }
    }

    private func deleteSessions(offsets: IndexSet) {
        // Disable implicit animation from @FetchRequest
        withAnimation(.default) {
            offsets.map { viewModel.sessions[$0] }.forEach(viewContext.delete)
        }

        do {
            try viewContext.save()
            // Refresh the list
            viewModel.attach(context: viewContext)
        } catch {
            print("Error deleting sessions: \(error.localizedDescription)")
        }
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
