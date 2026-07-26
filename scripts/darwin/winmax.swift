#!/usr/bin/swift

/// Usage:
///     swift winmax.swift maximize          Resize the frontmost window to its screen's visible frame.
///     swift winmax.swift maximize --force  Maximize even if already maximized.
///     swift winmax.swift restore           Restore the frame saved before the last maximize.
///     swift winmax.swift toggle            Maximize when not maximized, otherwise restore.

import Cocoa

// MARK: - AppKit bootstrap

/// Returns the shared application, forcing the AppKit initialization that
/// `NSScreen.visibleFrame` depends on.
///
/// - Returns: The shared `NSApplication`.
@discardableResult
func startAppKit() -> NSApplication {
  // In a plain script `NSScreen.visibleFrame` reports the full `frame` until the
  // app object exists, so a maximize reaches under the menu bar and hides the toolbar.
  NSApplication.shared
}

// MARK: - Coordinate conversion

/// The top edge of the primary screen, used as the origin for accessibility flips.
///
/// - Returns: The maximum y of the primary screen's frame.
func primaryScreenTop() -> CGFloat {
  NSScreen.screens.first?.frame.maxY ?? 0
}

extension CGPoint {
  /// The point converted between accessibility space (top-left origin) and
  /// AppKit screen space (bottom-left origin).
  var accessibilityFlipped: CGPoint {
    CGPoint(x: x, y: primaryScreenTop() - y)
  }
}

extension CGRect {
  /// The rectangle converted between accessibility space and AppKit screen space.
  var accessibilityFlipped: CGRect {
    CGRect(
      x: origin.x,
      y: primaryScreenTop() - origin.y - height,
      width: width,
      height: height)
  }
}

// MARK: - Accessibility attribute access

/// The name of the private enhanced-user-interface attribute.
let enhancedInterfaceAttribute = "AXEnhancedUserInterface"

/// Returns the value of an accessibility attribute.
///
/// - Parameters:
///   - element: The element to read.
///   - attribute: The attribute name.
/// - Returns: The attribute value, or `nil` when it is absent.
func attributeValue(of element: AXUIElement, named attribute: String) -> AnyObject? {
  var value: AnyObject?
  let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
  return status == .success ? value : nil
}

/// Returns a point-valued accessibility attribute.
///
/// - Parameters:
///   - element: The element to read.
///   - attribute: The attribute name.
/// - Returns: The point, or `nil` when the attribute is missing or not a point.
func point(of element: AXUIElement, named attribute: String) -> CGPoint? {
  guard let value = attributeValue(of: element, named: attribute),
    CFGetTypeID(value) == AXValueGetTypeID()
  else { return nil }
  var result = CGPoint.zero
  guard AXValueGetValue(value as! AXValue, .cgPoint, &result) else { return nil }
  return result
}

/// Returns a size-valued accessibility attribute.
///
/// - Parameters:
///   - element: The element to read.
///   - attribute: The attribute name.
/// - Returns: The size, or `nil` when the attribute is missing or not a size.
func size(of element: AXUIElement, named attribute: String) -> CGSize? {
  guard let value = attributeValue(of: element, named: attribute),
    CFGetTypeID(value) == AXValueGetTypeID()
  else { return nil }
  var result = CGSize.zero
  guard AXValueGetValue(value as! AXValue, .cgSize, &result) else { return nil }
  return result
}

/// Sets the position of an accessibility element.
///
/// - Parameters:
///   - element: The element to move.
///   - position: The new top-left position, in accessibility space.
func setPosition(of element: AXUIElement, to position: CGPoint) {
  var value = position
  guard let wrapped = AXValueCreate(.cgPoint, &value) else { return }
  AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, wrapped)
}

/// Sets the size of an accessibility element.
///
/// - Parameters:
///   - element: The element to resize.
///   - newSize: The new size.
func setSize(of element: AXUIElement, to newSize: CGSize) {
  var value = newSize
  guard let wrapped = AXValueCreate(.cgSize, &value) else { return }
  AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, wrapped)
}

/// Returns the frame of a window element, in accessibility space.
///
/// - Parameter window: The window element.
/// - Returns: The frame, or `nil` when position or size is unavailable.
func frame(of window: AXUIElement) -> CGRect? {
  guard let origin = point(of: window, named: kAXPositionAttribute),
    let extent = size(of: window, named: kAXSizeAttribute)
  else { return nil }
  return CGRect(origin: origin, size: extent)
}

/// Returns whether an application has enhanced user interface enabled.
///
/// - Parameter application: The application element.
/// - Returns: The current setting, or `nil` when unavailable.
func enhancedInterfaceEnabled(for application: AXUIElement) -> Bool? {
  attributeValue(of: application, named: enhancedInterfaceAttribute) as? Bool
}

/// Enables or disables enhanced user interface on an application.
///
/// - Parameters:
///   - application: The application element.
///   - enabled: The desired setting.
func setEnhancedInterface(for application: AXUIElement, enabled: Bool) {
  AXUIElementSetAttributeValue(
    application, enhancedInterfaceAttribute as CFString, enabled as CFBoolean)
}

/// Sets a window's frame using the size-position-size sequence the
/// accessibility API requires for reliable placement.
///
/// - Parameters:
///   - window: The window element to place.
///   - application: The owning application element, or `nil`.
///   - frame: The target frame, in accessibility space.
func setFrame(of window: AXUIElement, in application: AXUIElement?, to frame: CGRect) {
  if let application = application, enhancedInterfaceEnabled(for: application) == true {
    // Some apps re-lay out on the next resize and shove the window under the menu
    // bar; it is left off rather than restored because turning it back on
    // triggers the same jump.
    setEnhancedInterface(for: application, enabled: false)
  }
  setSize(of: window, to: frame.size)
  setPosition(of: window, to: frame.origin)
  setSize(of: window, to: frame.size)
}

// MARK: - Screen geometry

extension NSScreen {
  /// The area available to a maximized window, excluding menu bar, Dock, and any display notch.
  var maximizableFrame: CGRect {
    var result = visibleFrame
    guard #available(macOS 12.0, *), safeAreaInsets.top > 0 else { return result }
    let allowedTop = frame.maxY - safeAreaInsets.top
    guard result.maxY > allowedTop else { return result }
    result.size.height -= result.maxY - allowedTop
    return result
  }
}

/// Returns the screen holding the largest area of a window.
///
/// - Parameter windowFrame: The window frame, in accessibility space.
/// - Returns: The best-matching screen, or `nil` when no screens exist.
func screen(containing windowFrame: CGRect) -> NSScreen? {
  let flipped = windowFrame.accessibilityFlipped
  var best = NSScreen.main
  var bestArea: CGFloat = 0
  for candidate in NSScreen.screens {
    if candidate.frame.contains(flipped) { return candidate }
    let overlap = candidate.frame.intersection(flipped)
    guard !overlap.isNull else { continue }
    let area = overlap.width * overlap.height
    if area > bestArea {
      bestArea = area
      best = candidate
    }
  }
  return best
}

// MARK: - Frontmost window

/// A window paired with its owning application and process.
struct FrontmostWindow {
  let window: AXUIElement
  let application: AXUIElement
  let processID: pid_t
}

/// Returns the focused window of the frontmost application.
///
/// - Returns: The frontmost window, or `nil` when none can be resolved.
func frontmostWindow() -> FrontmostWindow? {
  guard let application = NSWorkspace.shared.frontmostApplication else { return nil }
  let processID = application.processIdentifier
  let applicationElement = AXUIElementCreateApplication(processID)

  if let focused = attributeValue(of: applicationElement, named: kAXFocusedWindowAttribute),
    CFGetTypeID(focused) == AXUIElementGetTypeID()
  {
    return FrontmostWindow(
      window: focused as! AXUIElement, application: applicationElement, processID: processID)
  }
  if let windows = attributeValue(of: applicationElement, named: kAXWindowsAttribute)
    as? [AXUIElement], let first = windows.first
  {
    return FrontmostWindow(
      window: first, application: applicationElement, processID: processID)
  }
  return nil
}

// MARK: - Saved-frame store

/// Reads and writes pre-maximize frames beneath the temporary directory.
///
/// Frames are keyed by process id and window title because the public
/// accessibility API does not vend a stable window identifier.
enum FrameStore {
  /// Returns the storage key for a window.
  ///
  /// - Parameters:
  ///   - window: The window element.
  ///   - processID: The owning process id.
  /// - Returns: A filesystem-safe key.
  static func key(for window: AXUIElement, processID: pid_t) -> String {
    let title = (attributeValue(of: window, named: kAXTitleAttribute) as? String) ?? ""
    let safeTitle =
      title
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: " ", with: "_")
    return "winmax_\(processID)_\(safeTitle)"
  }

  /// Returns the file URL backing a key.
  ///
  /// - Parameter key: The storage key.
  /// - Returns: The URL of the frame file.
  static func url(for key: String) -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(key).frame")
  }

  /// Saves a frame for later restoration.
  ///
  /// - Parameters:
  ///   - frame: The frame to persist, in accessibility space.
  ///   - key: The storage key.
  static func save(_ frame: CGRect, for key: String) {
    let line = "\(frame.origin.x) \(frame.origin.y) \(frame.width) \(frame.height)"
    try? line.write(to: url(for: key), atomically: true, encoding: .utf8)
  }

  /// Returns the frame previously saved for a key.
  ///
  /// - Parameter key: The storage key.
  /// - Returns: The saved frame, or `nil` when none is stored.
  static func load(for key: String) -> CGRect? {
    guard let line = try? String(contentsOf: url(for: key), encoding: .utf8) else { return nil }
    let values = line.split(separator: " ").compactMap { Double($0) }
    guard values.count == 4 else { return nil }
    return CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
  }

  /// Removes the frame stored for a key.
  ///
  /// - Parameter key: The storage key.
  static func clear(for key: String) {
    try? FileManager.default.removeItem(at: url(for: key))
  }
}

// MARK: - Commands

/// Writes a message to standard error and exits.
///
/// - Parameters:
///   - message: The message to report.
///   - code: The process exit code.
/// - Returns: Never; the process terminates.
func fail(_ message: String, code: Int32) -> Never {
  FileHandle.standardError.write(Data("winmax: \(message)\n".utf8))
  exit(code)
}

/// Returns whether a window already fills its screen's maximizable frame.
///
/// - Parameters:
///   - windowFrame: The current window frame, in accessibility space.
///   - screen: The screen to compare against.
/// - Returns: `true` when the frame matches within a small tolerance.
func isMaximized(_ windowFrame: CGRect, on screen: NSScreen) -> Bool {
  let target = screen.maximizableFrame.accessibilityFlipped
  let tolerance: CGFloat = 4
  return abs(windowFrame.origin.x - target.origin.x) < tolerance
    && abs(windowFrame.origin.y - target.origin.y) < tolerance
    && abs(windowFrame.width - target.width) < tolerance
    && abs(windowFrame.height - target.height) < tolerance
}

/// Maximizes the frontmost window, saving its current frame first.
///
/// - Parameter force: Maximizes even when the window already appears maximized.
func maximize(force: Bool) {
  guard let front = frontmostWindow() else { fail("no frontmost window", code: 1) }
  guard let current = frame(of: front.window) else { fail("cannot read window frame", code: 1) }
  guard let screen = screen(containing: current) else { fail("cannot determine screen", code: 1) }
  guard force || !isMaximized(current, on: screen) else { return }

  let key = FrameStore.key(for: front.window, processID: front.processID)
  FrameStore.save(current, for: key)
  setFrame(
    of: front.window, in: front.application, to: screen.maximizableFrame.accessibilityFlipped)
}

/// Restores the frontmost window to its saved pre-maximize frame.
func restore() {
  guard let front = frontmostWindow() else { fail("no frontmost window", code: 1) }
  let key = FrameStore.key(for: front.window, processID: front.processID)
  guard let saved = FrameStore.load(for: key) else { fail("no saved frame to restore", code: 1) }
  setFrame(of: front.window, in: front.application, to: saved)
  FrameStore.clear(for: key)
}

/// Maximizes the frontmost window, or restores it when already maximized.
func toggle() {
  guard let front = frontmostWindow(), let current = frame(of: front.window),
    let screen = screen(containing: current)
  else { fail("cannot read frontmost window", code: 1) }

  let key = FrameStore.key(for: front.window, processID: front.processID)
  if isMaximized(current, on: screen), FrameStore.load(for: key) != nil {
    restore()
  } else {
    maximize(force: false)
  }
}

/// Exits unless the invoking process holds Accessibility permission.
func requireAccessibility() {
  guard AXIsProcessTrusted() else {
    fail(
      "Accessibility permission not granted. Grant it to the app running this script in "
        + "System Settings › Privacy & Security › Accessibility.",
      code: 2)
  }
}

// MARK: - Entry point

let arguments = CommandLine.arguments
let command = arguments.count > 1 ? arguments[1] : "toggle"

startAppKit()
requireAccessibility()

switch command {
case "maximize": maximize(force: arguments.contains("--force"))
case "restore": restore()
case "toggle": toggle()
default: fail("usage: winmax.swift [maximize|restore|toggle] [--force]", code: 64)
}
