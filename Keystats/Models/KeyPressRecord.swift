import Foundation
import SwiftData

@Model
final class KeyPressRecord {
    @Attribute(.unique) var keyCode: Int
    var keyName: String
    var count: Int
    var lastPressed: Date

    init(keyCode: Int, keyName: String) {
        self.keyCode = keyCode
        self.keyName = keyName
        self.count = 1
        self.lastPressed = Date()
    }

    func incrementCount() {
        count += 1
        lastPressed = Date()
    }
}
