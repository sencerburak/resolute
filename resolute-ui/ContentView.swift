import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            
            Spacer()
            
            ForEach(NSScreen.screens, id: \.self) { screen in
                let displayModes = getAvailableDisplayModes(for: screen)
                displayModeButtons(displayModes: displayModes, screen: screen)
//                        .padding(7)
            }
            
            Spacer()
            
            HStack {
                ForEach(NSScreen.screens, id: \.self) { screen in
                    Button("Save Current Profile for \(screen.localizedName)") {
                        let displayID = getDisplayID(for: screen)
                        let mode = getCurrentDisplayMode(for: screen)
                        if let mode = mode {
                            let profile = DisplayProfile(displayID: displayID, modeID: UInt32(mode.ioDisplayModeID))
                            DisplayProfileManager.saveProfile(profile)
                        }
                    }
                }


                ForEach(DisplayProfileManager.loadProfiles() ?? [], id: \.displayID) { profile in
                    Button("Load Profile \(profile.modeID)") {
                        do {
                            try setDisplayMode(displayID: profile.displayID, modeID: profile.modeID)
                        } catch let error as DisplayModeError {
                            print("Failed: \(error)")
                        } catch {
                            print("Unexpected error: \(error)")
                        }
                    }
                }

                
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .padding(.bottom, 10)
                .padding(.leading, 10)
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
