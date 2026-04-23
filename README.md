# MouseSpot

A small macOS menu bar app that draws a colored circle around your cursor so it's easier to follow during screen shares, presentations, and recordings. The circle pulses when you click and shrinks further while you hold the button.

Inspired by [Hyper Cursor](https://hypercursor.com/), but open source.

## Features

- Menu bar app — no dock icon
- Global hotkey to toggle the spot on/off (default: `⌃⌘H`)
- Adjustable size, opacity, color, and refresh rate
- Click animation with configurable click scale and hold scale
- Available in English, Dutch, French, and German

## Requirements

- macOS (Apple Silicon or Intel)
- Xcode to build from source

## Build

Open `mousespot.xcodeproj` in Xcode and run, or build from the command line:

```sh
xcodebuild -project mousespot.xcodeproj -scheme mousespot -configuration Release
```

## Usage

1. Launch the app — a scope icon appears in the menu bar.
2. Press the hotkey (or pick "Toggle circle" from the menu) to show/hide the spot.
3. Open **Settings…** to change size, color, opacity, FPS, click behavior, language, and hotkey.

## License

See repository for license details.
