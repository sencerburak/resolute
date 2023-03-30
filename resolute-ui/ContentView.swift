import SwiftUI

struct ContentView: View {
    let displayModes: [CGDisplayMode] = getAvailableDisplayModes()
    var body: some View {
        VStack {
            Spacer()
            
            displayModeButtons(displayModes: displayModes)
                    .padding(7)
            
            Spacer()
            
            HStack {
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Image(systemName: "power")
//                        .foregroundColor(.red)
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
