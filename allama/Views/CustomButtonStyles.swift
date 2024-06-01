import SwiftUI

// Custom button style for sidebar
struct SidebarButtonStyle: ButtonStyle {
    var selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(selected ? .blue : .gray)
            .padding(.vertical, 0)
            .padding(.horizontal, 15)
            .frame(height: 25)
            .background(selected ? Color.gray.opacity(0.05) : Color.clear)
            .cornerRadius(3)
    }
}

struct DeleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.red)
            .padding(.vertical, 10)
            .padding(.horizontal, 0)
            .background(Color.clear)
            .cornerRadius(5)
    }
}
