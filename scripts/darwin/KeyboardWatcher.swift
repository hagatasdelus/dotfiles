import Foundation
import IOKit

/**
 * Watches keyboard (HID usage 1/6) attach/detach and runs keyboard-layout.
 *
 * It never decides the layout: the VID/PID -> US/JIS mapping lives in the CLI's
 * config.json, so adding a keyboard needs no change here.
 */

private func property(_ entry: io_service_t, _ key: String) -> AnyObject? {
    IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
}

private func numberProperty(_ entry: io_service_t, _ key: String) -> Int {
    guard let value = property(entry, key) else { return -1 }
    if let number = value as? NSNumber { return number.intValue }
    if let text = value as? String { return Int(text) ?? -1 }
    return -1
}

private func stringProperty(_ entry: io_service_t, _ key: String) -> String {
    guard let value = property(entry, key) else { return "" }
    if let text = value as? String { return text }
    if let data = value as? Data { return String(data: data, encoding: .utf8) ?? "" }
    return ""
}

private func log(_ message: String) {
    print("[\(ISO8601DateFormatter().string(from: Date()))] \(message)")
    fflush(stdout)
}

/** Interval, overridable with KEYBOARD_LAYOUT_RECONCILE_SECONDS (default 30s) */
private func reconcileSeconds() -> TimeInterval {
    if let raw = ProcessInfo.processInfo.environment["KEYBOARD_LAYOUT_RECONCILE_SECONDS"],
        let seconds = Double(raw), seconds > 0 {
        return seconds
    }
    return 30
}

private struct KeyboardDevice {
    let deviceId: String
    let vendorId: Int
    let productId: Int
    let product: String
    let manufacturer: String
    let transport: String
    let isBuiltIn: Bool
    let countryCode: Int
    let registryId: UInt64

    static func read(from entry: io_service_t) -> KeyboardDevice {
        let vendorId = numberProperty(entry, "VendorID")
        let productId = numberProperty(entry, "ProductID")
        let transport = stringProperty(entry, "Transport")
        var registryId: UInt64 = 0
        IORegistryEntryGetRegistryEntryID(entry, &registryId)

        return KeyboardDevice(
            deviceId: "\(vendorId == -1 ? -1 : vendorId)/\(productId == -1 ? -1 : productId)",
            vendorId: vendorId,
            productId: productId,
            product: stringProperty(entry, "Product"),
            manufacturer: stringProperty(entry, "Manufacturer"),
            transport: transport,
            isBuiltIn: numberProperty(entry, "Built-In") == 1,
            countryCode: numberProperty(entry, "CountryCode"),
            registryId: registryId
        )
    }

    var isVirtual: Bool { transport.isEmpty }

    func toJSONObject() -> [String: Any] {
        [
            "device_id": deviceId,
            "vendor_id": vendorId,
            "product_id": productId,
            "product": product,
            "manufacturer": manufacturer,
            "transport": transport,
            "is_keyboard": true,
            "is_built_in": isBuiltIn,
            "is_virtual": isVirtual,
            "country_code": countryCode,
        ]
    }

    func toHintJSON() -> String {
        let payload: [String: Any] = [
            "vendor_id": vendorId,
            "product_id": productId,
            "product": product,
        ]

        guard
            let data = try? JSONSerialization.data(withJSONObject: payload),
            let text = String(data: data, encoding: .utf8)
        else {
            return "{\"vendor_id\":\(vendorId),\"product_id\":\(productId)}"
        }
        return text
    }
}

private enum LayoutCLI {
    static func command() -> [String]? {
        if let override = ProcessInfo.processInfo.environment["KEYBOARD_LAYOUT_BIN"], !override.isEmpty {
            return [override]
        }

        let executable = URL(fileURLWithPath: CommandLine.arguments[0])
        let scriptDirectory = executable.deletingLastPathComponent()

        let compiled = scriptDirectory.appendingPathComponent("keyboard-layout").path
        if FileManager.default.isExecutableFile(atPath: compiled) {
            return [compiled]
        }

        let source = scriptDirectory.appendingPathComponent("../keyboard-layout.ts").path
        if FileManager.default.fileExists(atPath: source) {
            return ["bun", source]
        }

        return nil
    }

    @discardableResult
    static func run(arguments: [String]) -> Int32 {
        guard let binary = command() else {
            log("keyboard-layout CLI not found")
            return 127
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary[0])
        process.arguments = Array(binary.dropFirst()) + arguments

        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = [
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "\(NSHomeDirectory())/.bun/bin",
        ].joined(separator: ":")
        process.environment = environment

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                log("keyboard-layout \(arguments.joined(separator: " ")) failed (status \(process.terminationStatus))")
            }
            return process.terminationStatus
        } catch {
            log("cannot start keyboard-layout: \(error.localizedDescription)")
            return 126
        }
    }
}

private typealias MatchingCallback = @convention(c) (UnsafeMutableRawPointer?, io_iterator_t) -> Void

private final class Watcher {
    static let shared = Watcher()

    private let lock = NSLock()
    private var generation = 0
    private let queue = DispatchQueue(label: "local.keyboard-layout.watcher")
    private var lastFingerprint = ""
    private var lastExitCode: Int32 = 0

    private init() {}

    // MARK: 一覧

    func list() -> Never {
        var iterator = io_iterator_t()
        let matching = keyboardMatchingDictionary()

        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard result == KERN_SUCCESS else {
            print("{\"devices\":[]}")
            exit(result == KERN_SUCCESS ? 0 : 1)
        }

        var devices: [[String: Any]] = []
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            let device = KeyboardDevice.read(from: entry)
            if device.isVirtual { continue }
            devices.append(device.toJSONObject())
        }
        IOObjectRelease(iterator)

        let payload = try! JSONSerialization.data(withJSONObject: ["devices": devices])
        FileHandle.standardOutput.write(payload)
        FileHandle.standardOutput.write("\n".data(using: .utf8)!)
        exit(0)
    }

    // MARK: 監視

    func run() -> Never {
        guard let port = IONotificationPortCreate(kIOMainPortDefault) else {
            log("cannot create IONotificationPort")
            exit(1)
        }
        IONotificationPortSetDispatchQueue(port, queue)

        var appeared = io_iterator_t()
        var terminated = io_iterator_t()

        let appearResult = arm(port: port, name: kIOFirstMatchNotification, iterator: &appeared) { _, iterator in
            Watcher.shared.handle(iterator: iterator, kind: "attach")
        }
        let terminateResult = arm(port: port, name: kIOTerminatedNotification, iterator: &terminated) { _, iterator in
            Watcher.shared.handle(iterator: iterator, kind: "detach")
        }

        guard appearResult == KERN_SUCCESS, terminateResult == KERN_SUCCESS else {
            log("cannot subscribe to IOKit notifications (appear=\(appearResult), terminate=\(terminateResult))")
            exit(1)
        }

        drain(appeared)
        drain(terminated)

        log("watching IOHIDDevice (usage 1/6)")

        // Once at startup, then periodically to catch missed events (BT, sleep)
        lastFingerprint = fingerprint()
        lastExitCode = LayoutCLI.run(arguments: ["sync", "--source", "startup"])

        let timer = Timer(timeInterval: reconcileSeconds(), repeats: true) { _ in
            self.reconcile()
        }
        RunLoop.main.add(timer, forMode: .default)

        RunLoop.main.run()
        exit(0)
    }

    // MARK: 定期実行

    private func fingerprint() -> String {
        var iterator = io_iterator_t()
        let matching = keyboardMatchingDictionary()

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return ""
        }

        var entries: [String] = []
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            let device = KeyboardDevice.read(from: entry)
            IOObjectRelease(entry)
            if device.isVirtual {
                continue
            }
            entries.append("\(device.vendorId)/\(device.productId)/\(device.transport)/\(device.isBuiltIn)")
        }
        IOObjectRelease(iterator)

        return entries.sorted().joined(separator: ",")
    }

    private func recordFingerprint() {
        lastFingerprint = fingerprint()
    }

    /**
     * Safety net for missed events. Skips the CLI when the device list is unchanged,
     * so the cost is just enumeration. Retries on an unchanged list if the CLI failed.
     */
    private func reconcile() {
        let current = fingerprint()
        if current == lastFingerprint && lastExitCode == 0 {
            return
        }

        lastFingerprint = current
        lastExitCode = LayoutCLI.run(arguments: ["sync", "--source", "reconcile"])
    }

    private func keyboardMatchingDictionary() -> NSMutableDictionary {
        let matching = IOServiceMatching("IOHIDDevice") as NSMutableDictionary
        matching["PrimaryUsagePage"] = 1
        matching["PrimaryUsage"] = 6
        return matching
    }

    private func arm(
        port: IONotificationPortRef,
        name: String,
        iterator: UnsafeMutablePointer<io_iterator_t>,
        callback: @escaping MatchingCallback
    ) -> kern_return_t {
        let matching = keyboardMatchingDictionary()

        return name.withCString { pointer in
            IOServiceAddMatchingNotification(port, pointer, matching, callback, nil, iterator)
        }
    }

    private func drain(_ iterator: io_iterator_t) {
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            IOObjectRelease(entry)
        }
    }

    private func handle(iterator: io_iterator_t, kind: String) {
        var hints: [String] = []
        var hasExternal = false

        while case let entry = IOIteratorNext(iterator), entry != 0 {
            let device = KeyboardDevice.read(from: entry)
            IOObjectRelease(entry)

            if device.isVirtual { continue }
            if !device.isBuiltIn { hasExternal = true }

            if kind == "attach", !device.isBuiltIn {
                hints.append(device.toHintJSON())
            }
        }

        // Ignore virtual devices (Karabiner recreates them on profile switch) and
        // built-in keyboards, otherwise a profile switch would clear a manual pin
        guard hasExternal else { return }
        schedule(kind: kind, hint: hints.last)
    }

    /** Hubs re-enumerate, so wait a moment and fire once */
    private func schedule(kind: String, hint: String?) {
        lock.lock()
        generation += 1
        let generation = self.generation
        lock.unlock()

        queue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }

            self.lock.lock()
            let current = self.generation
            self.lock.unlock()

            guard generation == current else { return }

            var arguments = ["sync", "--source", "device-\(kind)"]
            if kind == "attach" {
                arguments += ["--event", "attach"]
                if let hint {
                    arguments += ["--hint", hint]
                }
            } else {
                arguments += ["--event", "detach"]
            }

            log("\(kind): \(hint ?? "unknown")")
            self.recordFingerprint()
            self.lastExitCode = LayoutCLI.run(arguments: arguments)
        }
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())

switch arguments.first ?? "run" {
case "list":
    Watcher.shared.list()
case "run":
    Watcher.shared.run()
default:
    print("usage: keyboard-watcher <list|run>")
    exit(2)
}
