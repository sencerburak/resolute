//
//  resolute_uiApp.swift
//  resolute-ui
//
//  Created by Sencer Burak Okumuş on 28/03/2023.
//

import SwiftUI
import SVGKit


@main
struct resolute_uiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            Text("Settings View")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    static var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }
    
    func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "star", accessibilityDescription: "Menu Bar Icon")
            button.action = #selector(togglePopover)
        }
           
        AppDelegate.popover.contentSize = NSSize(width: 360, height: 100)
        AppDelegate.popover.behavior = .transient
        AppDelegate.popover.contentViewController = NSHostingController(rootView: ContentView())

        statusBarItem.button?.target = self
        statusBarItem.button?.action = #selector(togglePopover)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        let button = statusBarItem.button
        
        if AppDelegate.popover.isShown {
            AppDelegate.popover.performClose(sender)
        } else {
            AppDelegate.popover.show(relativeTo: button!.bounds, of: button!, preferredEdge: .minY)
        }
    }
}

func iconForDisplayMode(mode: CGDisplayMode) -> Image {
    let icon: Image?
    // Determine an appropriate icon for the display mode
    // This example uses the resolution width as a simple condition, you can use more complex conditions if needed
    if mode.ioDisplayModeID < 3 {
        icon = Image("icon-1")
    } else if mode.ioDisplayModeID < 5 {
        icon = Image("icon-2")// (contentsOfFile: "icon-1.svg")
    } else if mode.ioDisplayModeID < 8 {
        icon = Image("icon-3")// (contentsOfFile: "icon-1.svg")
    } else if mode.ioDisplayModeID < 10 {
        icon = Image("icon-4")// (contentsOfFile: "icon-1.svg")
    }
    else {
        icon = Image("icon-5")// (contentsOfFile: "icon-1.svg")
    }
    if let icon = icon {
        return icon
    } else {
        return Image(nsImage: NSImage(named: NSImage.cautionName)!)
    }
}

func displayModeButtons(displayModes: [CGDisplayMode]) -> some View {
    return HStack {
        ForEach(displayModes, id: \.self) { mode in

            iconForDisplayMode(mode: mode)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .highPriorityGesture(
                    TapGesture(count: 1)
                        .onEnded {
                            AppDelegate.popover.performClose(nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {setMode(mode: mode)}
                            print("Selected display mode: \(mode.ioDisplayModeID)")
                        }
                )
//            .padding(.horizontal, 0)
        }

    }
}

func setMode(mode: CGDisplayMode) {
    let displayID = CGMainDisplayID()
    
    do {
        let success = try setDisplayMode(displayID: displayID, modeID: UInt32(mode.ioDisplayModeID))
        if success {
//          AppDelegate.popover.performClose(nil)
          print("Succeeeyysys")
        }
    } catch let error as DisplayModeError {
        print("Feyiiiiilllll: \(error)")

    } catch {
        print("Unexpectiiiiddd: \(error)")
    }
}

func getAvailableDisplayModes() -> [CGDisplayMode] {
    if NSScreen.main != nil {
        let displayID = CGMainDisplayID()
        return getAvailableScaledDisplayModes(displayID: displayID)
    }
    return []
}

func getAvailableScaledDisplayModes(displayID: CGDirectDisplayID) -> [CGDisplayMode] {
    let options: NSDictionary = [kCGDisplayShowDuplicateLowResolutionModes: true]

    let modes: [CGDisplayMode] = CGDisplayCopyAllDisplayModes(displayID, options) as! [CGDisplayMode]
    var availableModes: [CGDisplayMode] = []
    for mode in modes {
        let modeResolutionScalingFactor = mode.pixelWidth / mode.width

        if modeResolutionScalingFactor == 2 && mode.isUsableForDesktopGUI() {
            availableModes.append(mode)
        }
    }
    return availableModes
}

enum DisplayModeError: Error, CustomStringConvertible {
    case unavailableDisplayMode
    case modeNotFound
    case failedToChangeDisplayMode(CGError)

    var description: String {
        switch self {
        case .unavailableDisplayMode:
            return "The specified display mode is not available."
        case .modeNotFound:
            return "Failed to find the specified display mode."
        case .failedToChangeDisplayMode(let error):
            return "Failed to change display mode. Error: \(error)"
        }
    }
}

func setDisplayMode(displayID: CGDirectDisplayID, modeID: UInt32) throws -> Bool {
    if getAvailableDisplayModes().contains(where: { $0.ioDisplayModeID == modeID }) {
      let options: NSDictionary = [kCGDisplayShowDuplicateLowResolutionModes: true]
      let displayModes = CGDisplayCopyAllDisplayModes(displayID, options)
      if let modes = displayModes as? [CGDisplayMode] {
          for mode in modes {
              if mode.ioDisplayModeID == modeID {
                  print("Changing display mode to \(mode.width)x\(mode.height)@\(mode.refreshRate)Hz...")
                  let result = CGDisplaySetDisplayMode(displayID, mode, nil)
                  if result == CGError.success {
                      print("Display mode changed successfully.")
                      return true
                  } else {
                      throw DisplayModeError.failedToChangeDisplayMode(result)
                  }
              }
          }
      }
      throw DisplayModeError.modeNotFound
    }
    throw DisplayModeError.unavailableDisplayMode
}
