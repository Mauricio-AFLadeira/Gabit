import GabitKit
import SwiftUI

struct ContentView: View {

    var body: some View {
        VStack(spacing: 8) {
            Text("Gabit")
                .font(.largeTitle.bold())
            Text("core \(GabitKit.version)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
