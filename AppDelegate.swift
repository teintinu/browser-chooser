import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindow: NSWindow?
    var pickerWindow: NSWindow?
    var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupURLEvents()
        setupRouterObservation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if Router.shared.pendingURL == nil && !Router.shared.isRouting {
                self.showMainWindow()
            }
        }
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "safari", accessibilityDescription: "Browser Chooser")
            button.action = #selector(showMainWindow)
            button.target = self
        }
    }

    @objc private func showMainWindow() {
        if mainWindow == nil {
            let contentView = ContentView()
            mainWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            mainWindow?.center()
            mainWindow?.setFrameAutosaveName("Main Window")
            mainWindow?.contentView = NSHostingView(rootView: contentView)
            mainWindow?.title = "Teintinu Browser Chooser"
            mainWindow?.isReleasedWhenClosed = false
        }
        
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupURLEvents() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    private func setupRouterObservation() {
        Router.shared.$isShowingPicker
            .sink { [weak self] isShowing in
                if isShowing, let url = Router.shared.pendingURL {
                    DispatchQueue.main.async {
                        self?.showPickerWindow(for: url)
                    }
                } else if !isShowing {
                    DispatchQueue.main.async {
                        self?.closePickerWindow()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func showPickerWindow(for url: URL) {
        if pickerWindow == nil {
            let pickerView = BrowserPickerView(url: url)
            pickerWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 550, height: 600),
                styleMask: [.titled, .fullSizeContentView], // Sem botões de fechar/minimizar para forçar ação
                backing: .buffered, defer: false)
            pickerWindow?.center()
            pickerWindow?.contentView = NSHostingView(rootView: pickerView)
            pickerWindow?.title = "Where should I open this?"
            pickerWindow?.level = .floating // Garante que fique por cima
            pickerWindow?.isReleasedWhenClosed = false
        } else {
            // Se já existe, atualiza o conteúdo se necessário (SwiftUI cuidará da reatividade se passarmos via StateObject,
            // mas aqui criamos uma nova View pois o URL mudou)
            let pickerView = BrowserPickerView(url: url)
            pickerWindow?.contentView = NSHostingView(rootView: pickerView)
        }
        
        pickerWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePickerWindow() {
        pickerWindow?.orderOut(nil)
        pickerWindow = nil
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            return
        }
        Router.shared.handle(url: url)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            Router.shared.handle(url: url)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }
}
