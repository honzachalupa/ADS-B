import SwiftUI

struct ClusterMarkerView: View {
    let count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 30, height: 30)
            
            Text("\(count)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(1.0 + min(CGFloat(count) * 0.05, 0.5)) // Scale based on cluster size
    }
}

#Preview {
    VStack(spacing: 20) {
        ClusterMarkerView(count: 5)
        ClusterMarkerView(count: 15)
        ClusterMarkerView(count: 50)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
