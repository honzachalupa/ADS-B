import SwiftUI

struct MapLegendView<Content: View>: View {
    @ViewBuilder let label: Content
    @State var isLegendPopupPresented: Bool = false
    
    private func buildLegendText() -> AttributedString {
        var text = AttributedString(String(localized: "Regular aircraft are")) + " "
        
        var blueText = AttributedString(String(localized: "blue")) + " "
        blueText.foregroundColor = .blue
        text += blueText
        
        text += AttributedString(String(localized: "and military aircraft are")) + " "
        
        var greenText = AttributedString(String(localized: "green"))
        greenText.foregroundColor = .green
        text += greenText
        
        text += AttributedString(".")
        
        return text
    }
    
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
                
                Text(buildLegendText())
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    MapLegendView {
        Text("Legend")
    }
}
