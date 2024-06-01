import SwiftUI

class TypeEffectHandler {
    @MainActor
    func typeEffect(for response: String, displayedResponse: Binding<String>, completion: @escaping () -> Void) {
        let characters = Array(response)
        var currentText = displayedResponse.wrappedValue
        
        Task {
            for char in characters {
                currentText.append(char)
                displayedResponse.wrappedValue = currentText
                try await Task.sleep(nanoseconds: UInt64.random(in: 10_000_000...50_000_000)) // 10-50ms delay
            }
            completion()
        }
    }
}
