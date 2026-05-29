# zShellWatch

zShellWatch is a terminal-inspired Apple Watch companion app and widget project. The iPhone app is used to preview, configure, and sync a shell-style watch face, while the watchOS app displays the selected face on Apple Watch.

This project is inspired by:

- [kuglee/TermiWatch](https://github.com/kuglee/TermiWatch/)
- [qianlishun/TermiWatchWidget](https://github.com/qianlishun/TermiWatchWidget)

Important limitation: `zShellWatch` is not an Apple system watch face and does not replace the default watch face. It renders a watch-face-like screen inside the watchOS app, so the face is visible while the watch app is open.

You can download in [App Store](https://apps.apple.com/app/zshellwatch/id6770774873)

## Features

### Sample Watch Face Themes

<table border="0">
 <tr>
    <td><b style="font-size:14px">Cloud</b></td>
    <td><b style="font-size:14px">Colorful</b></td>
    <td><b style="font-size:14px">Binary</b></td>
 </tr>
 <tr>
    <td><img src="Preview/face-01.avif" width="320"></td>
    <td><img src="Preview/face-02.avif" width="320"></td>
    <td><img src="Preview/face-03.avif" width="320"></td>
 </tr>
</table>

### Quick Preview

<img src="Preview/quick-preview.gif" width="480" alt="Quick preview">

### iPhone control app

- Live Apple Watch-style preview in the main screen.
- Dark terminal UI with a gray navigation bar.
- Navigation bar actions for connection status, line configuration, and watch sync.
- Auto-hiding sync feedback toast instead of blocking alert dialogs.
- Status panel for Location, Health, Watch pairing, Weather source, and last sync state.
- Terminal user and machine name configuration.
- Shared settings storage through App Groups.

### Configurable face lines

Users can choose which lines appear and reorder them from the Face Lines screen.

Available lines include:

- Command Prompt
- Date
- Time
- Current Weather
- Temperature
- Humidity
- Next Weather
- Battery
- Rings
- Steps
- Calories
- Heart Rate
- Prompt

Weather lines are hidden automatically when no weather provider is configured. Health lines require HealthKit permission.

### Themes

zShellWatch includes multiple terminal-style themes:

- Default Theme: classic terminal face.
- Git Theme: git prompt styling, branch label, rotating line colors, and badge-style changed values.
- Cloud Theme: cloud/thunder prompt styling with rainbow text behavior.
- Icon Theme: icon-first layout with face line labels removed.
- Colorful Theme: rainbow prompt styling and stronger accent colors.

### Animations

The top status area can show a selectable animation:

- Dot Line
- Matrix Text
- Pacman
- Terminal Cursor
- Command Loader
- Signal Sweep
- No Animation

Animations are intentionally small and status-bar sized so they do not cover the watch face content.

### Weather

Weather support is optional. If no provider is configured, the weather feature is disabled and weather face lines are hidden.

Supported weather modes:

- QWeather API key through `HFWeatherKey`.
- WeatherKit through `qUseWeatherKit`.
- Disabled when both are unavailable.

Configuration is in [QConfiguration.swift](TermiWatchWidget/Configuration/QConfiguration.swift):

```swift
let qUseWeatherKit = false
let HFWeatherKey = ""
```

Personal Apple development teams may not support the WeatherKit capability. In that case, keep WeatherKit disabled and use QWeather only if you have a key.

## Setup

1. Open `TermiWatchWidget.xcodeproj` in Xcode.
2. Select the `TermiWatchWidget` scheme.
3. Configure signing for the iOS app, watch app, and widget targets.
4. Confirm the App Group matches:

```swift
let qGroupBundleID = "group.com.github.lunf.zShellWatch"
```

5. Enable HealthKit if you want health lines.
6. Configure weather only if you want weather lines:

```swift
let HFWeatherKey = "your-qweather-key"
```

or:

```swift
let qUseWeatherKit = true
```

7. Build and run the iOS app on a paired iPhone or simulator.
8. Install the watch app on Apple Watch.
9. Use the iPhone app to configure the face, then tap the sync action in the navigation bar.

## Known Limitations

- This app cannot install a real Apple system watch face.
- The watch face display depends on the watchOS app staying open.
- watchOS may sleep or background the app according to system rules.
- Custom background images are not supported.
- Weather lines are disabled unless QWeather or WeatherKit is configured.
- Health lines require HealthKit permission and device support.
- Watch sync requires the companion watch app to be installed and paired.

## License

This project is licensed under GPL-3.0. See [LICENSE.md](LICENSE.md).
