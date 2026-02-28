import Foundation
import SwiftData

actor KeyPressPersistenceActor {
  private let modelContext: ModelContext

  init(container: ModelContainer) {
    modelContext = ModelContext(container)
  }

  func flush(
    _ batchedCounts: [(keyCode: Int, keyName: String, delta: Int)]
  ) throws {
    guard !batchedCounts.isEmpty else { return }

    for item in batchedCounts {
      let keyCode = item.keyCode
      let descriptor = FetchDescriptor<KeyPressRecord>(
        predicate: #Predicate<KeyPressRecord> { $0.keyCode == keyCode }
      )

      if let record = try modelContext.fetch(descriptor).first {
        record.count += item.delta
      } else {
        let newRecord = KeyPressRecord(
          keyCode: item.keyCode,
          keyName: item.keyName
        )
        if item.delta > 1 {
          newRecord.count = item.delta
        }
        modelContext.insert(newRecord)
      }
    }

    try modelContext.save()
  }
}
