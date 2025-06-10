import SwiftUI

struct MapFilterControlView: View {
    var body: some View {
#if os(iOS)
        Menu {
            MapFilterView()
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease")
        }
#endif
    }
}

#Preview {
    MapFilterControlView()
}
