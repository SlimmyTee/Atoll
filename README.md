# Atoll — Dynamic Island for macOS 🏝️

A native, ultra-lightweight Dynamic Island utility for macOS built with **Swift**, **SwiftUI**, and **AppKit**.

Designed specifically for MacBooks with a camera notch (and seamlessly integrated for multi-display setups), inspired by [Alcove](https://tryalcove.com/) and Apple's Dynamic Island design language.

---

## ✨ Features

1. **Hardware-Fitted Notch Pill:**
   - Detects the exact physical cutout dimensions (`ScreenMetrics`).
   - Blends continuous pitch-black rounded geometry into the MacBook camera bezel.
   - Smooth 120Hz ProMotion spring animations with intelligent cursor exit debounce.
   - Smart multi-display detection: automatically hides on external displays so it stays locked to your MacBook notch.

2. **Unified Dashboard (Music & Calendar):**
   - **Music Player:** Live Spotify & Apple Music artwork, track title, all participating artists, live progress scrubber, and playback controls.
   - **Calendar & Smart Meetings:** Displays your next event with live countdown badges, location, and a 1-click **"Join Call"** button that automatically opens Microsoft Teams (native app or browser), Zoom, Google Meet, or Webex.
   - **All-Day Event Smart Filtering:** All-day events (e.g. holidays) never mask your timed meetings or video calls.

3. **File Pocket / Shelf:**
   - Drag and drop files directly onto the notch or shelf.
   - Quick staging area for temporary files, drag-out back to Slack, Mail, or Finder.

4. **Focus Timer:**
   - Integrated Pomodoro and quick focus presets (`5m`, `15m`, `25m`) right in your notch.

5. **Quick System Actions:**
   - 1-click system mute/unmute and instant screen lock (`⌥ + Space` toggle support).

6. **Native Menu Bar Extra:**
   - Pure accessory app (`LSUIElement = YES`) with zero Dock clutter.
   - Status bar menu to toggle, pin open, switch tabs, or quit.

---

## 🌐 Landing Page

This repository includes a production-ready landing page located in [`landing/`](landing/):
- **Live Interactive Sandbox:** Users can test the Dynamic Island in their browser, switch songs, explore tabs, and test notch interactions before installing.
- **Direct DMG Download:** Pre-configured link serving `Atoll.dmg` (704 KB).

To preview locally:
```bash
cd landing && python3 -m http.server 4173
# Open http://localhost:4173/ in your browser
```

---

## 💿 Installation & Distribution

### 1. Standalone DMG Installer
Download `Atoll.dmg` directly from the [landing page](landing/downloads/Atoll.dmg) or build it with:
```bash
./create_dmg.sh
```
Double-click `Atoll.dmg` and drag **Atoll** into your `/Applications` folder.

### 2. Run Directly from Source
```bash
./bundle.sh && open DynamicIsland.app
```

---

## 🛠️ Architecture

- `ScreenMetrics.swift`: Detects physical screen notch geometry and calculates anchor positions.
- `IslandPanel.swift`: Custom borderless `NSPanel` floating at `.statusBar` level across all spaces with pass-through hit testing.
- `IslandViewModel.swift`: State machine managing expanded/compact transitions, mute/lock states, active tabs, and timers.
- `IslandView.swift`: SwiftUI dynamic island layout, compact notch ears, and fluid spring animations.
- `MediaController.swift`: AppleScript and Cocoa query controller for Spotify and Apple Music with live artwork fetching.
- `CalendarController.swift`: EventKit calendar integration with direct meeting app URL detection.
- `FilePocketView.swift`: Drag-and-drop file shelf pocket.
- `TimerWidgetView.swift`: Focus countdown timer widget.
- `DynamicIsland.swift`: Application lifecycle and status bar menu.

---

## 📄 License
MIT License. Crafted with ❤️ for macOS.
