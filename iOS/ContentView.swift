import SwiftUI
import SwiftCore
import MapKit

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var aircraftService = AircraftService.shared
    @AppStorage(SETTINGS_IS_DEBUG_INFO_BOX_ENABLED_KEY) private var isDebugInfoBoxEnabled: Bool = false
    @State private var isSettingsSheetPresented: Bool = false
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    ListView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    isSettingsSheetPresented.toggle()
                                } label: {
                                    Label("Settings", systemImage: "gearshape.fill")
                                }
                            }
                        }
                        .sheet(isPresented: $isSettingsSheetPresented) {
                            NavigationStack {
                                SettingsView()
                                    .toolbar {
                                        ToolbarItem(placement: .cancellationAction) {
                                            Button {
                                                isSettingsSheetPresented.toggle()
                                            } label: {
                                                Label("Close", systemImage: "xmark")
                                            }
                                        }
                                    }
                            }
                        }
                } detail: {
                    MapView()
                }
            } else {
                TabView {
                    Tab("Map", systemImage: "map") {
                        NavigationStack {
                            MapView()
                                .toolbar {
                                    ToolbarItem(placement: .topBarLeading) {
                                        NavigationLink {
                                            SettingsView()
                                        } label: {
                                            Label("Settings", systemImage: "gearshape.fill")
                                        }
                                    }
                                    
                                    #if os(iOS)
                                    // ToolbarSpacer(.flexible, placement: .topBarLeading)
                                    #endif
                                }
                        }
                    }
                    
                    Tab("List", systemImage: "list.bullet") {
                        ListView()
                    }
                }
            }
        }
        .overlay {
            if isDebugInfoBoxEnabled {
                VStack {
                    Spacer()
                    
                    DebugInfoView() 
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .frame(maxWidth: 500)
                        .padding(.bottom)
                }
            }
        }
        /* .tabViewBottomAccessory {
            if isDebugInfoBoxEnabled {
                DebugInfoView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown) */
        .messageManagerOverlay()
    }
}

#Preview {
    ContentView()
}
