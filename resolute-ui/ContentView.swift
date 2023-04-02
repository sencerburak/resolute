import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()

            VStack {
                ForEach(NSScreen.screens, id: \.self) { screen in
                    let displayModes = getAvailableDisplayModes(for: screen)
                    displayModeButtons(displayModes: displayModes, screen: screen)
                        .padding(7)
                }
            }

            Spacer()

            HStack {
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
