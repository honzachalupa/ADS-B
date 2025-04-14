import SwiftUI

struct ListItemIconView: View {
    let label: String
    let iconName: String
    let color: Color
    
    init(label: String, iconName: String, color: Color = .blue) {
        self.label = label
        self.iconName = iconName
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 24, height: 24)
                
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
            }
            
            Text(label)
            
            Spacer()
        }
    }
}
