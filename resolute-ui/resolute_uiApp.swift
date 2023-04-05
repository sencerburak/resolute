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

struct DisplayProfile: Codable {
    var displayID: CGDirectDisplayID
    var modeID: UInt32
}

class DisplayProfileManager {
    private static let profilesKey = "displayProfiles"

    static func saveProfile(_ profile: DisplayProfile) {
        var existingProfiles = loadProfiles() ?? []
        existingProfiles.append(profile)
        saveProfiles(existingProfiles)
    }

    static func loadProfiles() -> [DisplayProfile]? {
        if let data = UserDefaults.standard.data(forKey: profilesKey) {
            do {
                let profiles = try JSONDecoder().decode([DisplayProfile].self, from: data)
                return profiles
            } catch {
                print("Error decoding profiles: \(error)")
                return nil
            }
        }
        return nil
    }

    private static func saveProfiles(_ profiles: [DisplayProfile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: profilesKey)
        } catch {
            print("Error encoding profiles: \(error)")
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

        AppDelegate.popover.contentSize = NSSize(width: 360, height: 200)
        AppDelegate.popover.behavior = .applicationDefined
        AppDelegate.popover.contentViewController = NSHostingController(rootView: ContentView())

        statusBarItem.button?.target = self
        statusBarItem.button?.action = #selector(togglePopover)
//        print("All available modes and screens: \(getAllAvailableDisplayModes())")
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        let button = statusBarItem.button

        if AppDelegate.popover.isShown {
            AppDelegate.popover.performClose(sender)
        } else {
            listAvailableDisplays()
            AppDelegate.popover.show(relativeTo: button!.bounds, of: button!, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true) // Activate the app when showing the popover
            AppDelegate.popover.contentViewController?.view.window?.makeKey() // Make the popover key
        }
    }
}

// MARK: - Display Functions

func getDisplayID(for screen: NSScreen) -> CGDirectDisplayID {
    return screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID
}

func listAvailableDisplays() {
    let screens = NSScreen.screens

    for (index, screen) in screens.enumerated() {
        print("  Name: \(screen.localizedName)")
        let displayID = getDisplayID(for: screen)
        print("Display \(index + 1):")
        print("  ID: \(displayID)")
        print("  Frame: \(screen.frame)")
        print("  Visible Frame: \(screen.visibleFrame)")
        print("  DPI: \(screen.backingScaleFactor)")
        print("  Resolution: \(screen.frame.size.width)x\(screen.frame.size.height)")
        print("  Max Refresh Rate: \(screen.maximumRefreshInterval)Hz")
        print("  Display Modes:")

        for mode in getAvailableDisplayModes(for: screen) {
            print("\(mode.ioDisplayModeID), ", terminator: "")
//            print("")
        }
        
        let me = "be"
    }
}

func iconForDisplayMode(mode: CGDisplayMode) -> Image {
    let icon: Image?

    if mode.ioDisplayModeID < 3 {
        icon = Image("icon-1")
    } else if mode.ioDisplayModeID < 5 {
        icon = Image("icon-2")
    } else if mode.ioDisplayModeID < 8 {
        icon = Image("icon-3")
    } else if mode.ioDisplayModeID < 10 {
        icon = Image("icon-4")
    } else {
        icon = Image("icon-5")
    }

    return icon ?? Image(nsImage: NSImage(named: NSImage.cautionName)!)
}

func displayModeButtons(displayModes: [CGDisplayMode], screen: NSScreen) -> some View {
    return HStack {
        Spacer()
        ForEach(displayModes, id: \.self) { mode in
            iconForDisplayMode(mode: mode)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .highPriorityGesture(
                    TapGesture(count: 1)
                        .onEnded {
                            AppDelegate.popover.performClose(nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                setMode(mode: mode, screen: screen)
                            }
                            print("Selected display mode: \(mode.ioDisplayModeID)")
                        }
                )
        }
        Spacer()
    }
}

func setMode(mode: CGDisplayMode, screen: NSScreen) {
    let displayID = getDisplayID(for: screen)
    do {
        let success = try setDisplayMode(displayID: displayID, modeID: UInt32(mode.ioDisplayModeID))
        if success {
            print("Success")
        }
    } catch let error as DisplayModeError {
        print("Failed: \(error)")
    } catch {
        print("Unexpected error: \(error)")
    }
}

func isMainScreen(screen: NSScreen) -> Bool {
    return screen == NSScreen.main
}

func getAvailableDisplayModes(for screen: NSScreen) -> [CGDisplayMode] {
    if isMainScreen(screen: screen) {
        return getAvailableScaledDisplayModes(screen: screen)
    }
    else {
        return getAvailableScaledDisplayModes(screen: screen, checkResolutionFactor: true)
    }
}

func getAllAvailableDisplayModes() -> [CGDirectDisplayID: [CGDisplayMode]] {
    var allAvailableDisplayModes: [CGDirectDisplayID: [CGDisplayMode]] = [:]

    for screen in NSScreen.screens {
        let displayID = getDisplayID(for: screen)
        let availableDisplayModes = getAvailableScaledDisplayModes(screen: screen)
        allAvailableDisplayModes[displayID] = availableDisplayModes
    }

    return allAvailableDisplayModes
}

func getAvailableScaledDisplayModes(screen: NSScreen, checkResolutionFactor: Bool = true) -> [CGDisplayMode] {
    let options: NSDictionary = [kCGDisplayShowDuplicateLowResolutionModes: true]
    let displayID = getDisplayID(for: screen)
    let modes: [CGDisplayMode] = CGDisplayCopyAllDisplayModes(displayID, options) as! [CGDisplayMode]
    var availableModes: [CGDisplayMode] = []
    for mode in modes {
        let modeResolutionScalingFactor = mode.pixelWidth / mode.width

        if (checkResolutionFactor && modeResolutionScalingFactor == 2) || !checkResolutionFactor {
            if mode.isUsableForDesktopGUI() {
                availableModes.append(mode)
            }
        }
    }
    return availableModes
}

func getCurrentDisplayMode(for screen: NSScreen) -> CGDisplayMode? {
    let displayID = getDisplayID(for: screen)
    let displayMode = CGDisplayCopyDisplayMode(displayID)
    return displayMode
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
    let allAvailableDisplayModes = getAllAvailableDisplayModes()

    if allAvailableDisplayModes[displayID]?.contains(where: { $0.ioDisplayModeID == modeID }) != nil {
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
