import SwiftUI

struct MapLegendView: View {
    @State var isLegendPopupPresented: Bool = false
    
    var body: some View {
        Button {
            isLegendPopupPresented.toggle()
        } label: {
            Image(systemName: "info.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(12)
                .background(.thickMaterial)
                .cornerRadius(8)
                .fontWeight(.medium)
        }
        .sheet(isPresented: $isLegendPopupPresented) {
            List {
                Section("Legend") {
                    ForEach(AircraftDisplayConfig.legendItems) { item in
                        ListItemIconView(color: item.color, label: item.label, iconName: item.iconName)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    MapLegendView()
}
