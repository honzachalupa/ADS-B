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
                
                Text(buildLegendText())
            }
            .presentationDetents([.medium])
        }
    }
    
    private func buildLegendText() -> AttributedString {
        var text = AttributedString("Regular aircraft are ")
        
        var blueText = AttributedString("blue")
        blueText.foregroundColor = .blue
        text += blueText
        
        text += AttributedString(" and military aircraft are ")
        
        var greenText = AttributedString("green")
        greenText.foregroundColor = .green
        text += greenText
        
        text += AttributedString(".")
        
        return text
    }
}

#Preview {
    MapLegendView {
        Text("Legend")
    }
}
