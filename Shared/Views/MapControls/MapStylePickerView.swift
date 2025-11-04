import SwiftUI

struct MapStylePickerView: View {
    @Binding public var selection: String
    
    var body: some View {
        Menu {
            Section("Map style") {
                Picker("Map style", selection: $selection) {
                    Text("Standard").tag("standard")
                    Text("Satelite").tag("satelite")
                }
            }
        } label: {
            Label("Map style", systemImage: "map.fill")
        }
    }
}

#Preview {
    MapStylePickerView(selection: .constant("standard"))
}
