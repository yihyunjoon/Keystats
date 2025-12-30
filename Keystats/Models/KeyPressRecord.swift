import Foundation
import SwiftData

@Model
final class KeyPressRecord {
    @Attribute(.unique) var keyCode: Int
    var keyName: String
    var count: Int

    init(keyCode: Int, keyName: String) {
        self.keyCode = keyCode
        self.keyName = keyName
        self.count = 1
    }

    func incrementCount() {
        count += 1
    }

    static func initializeDefaultsIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<KeyPressRecord>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else { return }

        for (keyCode, keyName) in KeyCodeMapping.keyNames {
            let record = KeyPressRecord(keyCode: keyCode, keyName: keyName)
            record.count = 0
            context.insert(record)
        }

        try? context.save()
    }
}
