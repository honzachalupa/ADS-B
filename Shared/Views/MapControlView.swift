import SwiftUI

struct MapControlView: View {
    var iconName: String
    
    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .padding(12)
            .background(.thickMaterial)
            .cornerRadius(8)
            .fontWeight(.medium)
    }
}

#Preview {
    MapControlView(iconName: "map")
}
