import SwiftData
import SwiftUI

struct DataSettingsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var records: [KeyPressRecord]

  @State private var showClearConfirmation = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(String(localized: "Data"))
        .font(.headline)

      Button(String(localized: "Reset"), role: .destructive) {
        showClearConfirmation = true
      }
      .disabled(records.isEmpty)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
      .regularMaterial,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
    .alert(
      String(localized: "Clear All Data?"),
      isPresented: $showClearConfirmation
    ) {
      Button(String(localized: "Cancel"), role: .cancel) {}
      Button(String(localized: "Clear"), role: .destructive) {
        clearAllData()
      }
    } message: {
      Text(String(localized: "This action cannot be undone."))
    }
  }

  private func clearAllData() {
    do {
      try modelContext.delete(model: KeyPressRecord.self)
    } catch {
      print("Failed to clear data: \(error)")
    }
  }
}

#Preview {
  DataSettingsView()
    .modelContainer(for: KeyPressRecord.self, inMemory: true)
}
