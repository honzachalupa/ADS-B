import SwiftUI

struct ListItemIconView: View {
    let color: Color
    let label: String
    let iconName: String
    
    init(color: Color, label: String, iconName: String = "airplane") {
        self.color = color
        self.label = label
        self.iconName = iconName
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
                    .foregroundStyle(color)
            }
            
            Text(label)
            
            Spacer()
        }
    }
}
