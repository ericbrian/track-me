import SwiftUI
import CoreData

// MARK: - Main View

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = HistoryListViewModel()

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
                    if viewModel.isEmpty {
                        EmptyHistoryView()
                    } else {
                        ForEach(viewModel.sessions, id: \.objectID) { session in
                            ModernSessionRowView(session: session)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: viewModel.deleteSessions)
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
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
