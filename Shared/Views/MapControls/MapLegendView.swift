import SwiftUI

struct MapLegendView<Content: View>: View {
    @ViewBuilder let label: Content
    @State var isLegendPopupPresented: Bool = false
    
    var body: some View {
        Button {
            isLegendPopupPresented.toggle()
        } label: {
            label
        }
        .sheet(isPresented: $isLegendPopupPresented) {
            List {
                Section("Legend") {
                    ForEach(AircraftDisplayConfig.legendItems) { item in
                        ListItemIconView(label: item.label, iconName: item.iconName)
                    }
                }
                
                HStack {
                    Text("Regular aircrafts are") +
                    Text("&nbsp;blue&nbsp;")
                        .foregroundColor(.blue) +
                    Text("and military aircrafts are") +
                    Text("&nbsp;green")
                        .foregroundColor(.green) +
                    Text(".")
                }
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    MapLegendView {
        Text("Legend")
    }
}
