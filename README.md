# YTSkipper

A macOS menu bar app that presses YouTube's **Skip** button for you while videos play in Safari.

It does not capture the screen, move the mouse, or steal focus. It asks Safari's accessibility tree
for a button whose visible label is a configured Skip Label on a YouTube page, and sends it an
accessibility press. Safari can be on any display and behind other windows.

## Requirements

- macOS 14 or newer (built on macOS 27).
- Xcode Command Line Tools (Swift 6.4). Xcode itself is not needed.
- Safari. Other browsers are out of scope.

## Build and run

```sh
make run          # quits a running instance, builds build/YTSkipper.app, launches it
make test         # unit tests for the decision logic
make stop         # quit the running instance
make clean        # remove build/ and .build/
```

The app is run straight from `build/YTSkipper.app` inside this repo. Nothing is installed elsewhere
and nothing starts at login.

### Accessibility permission

On first launch macOS asks for Accessibility access. The menu also shows
"Accessibility permission needed" with a shortcut to the right Settings pane until it is granted.

The bundle is ad-hoc signed, so **after every rebuild macOS forgets the grant**: remove YTSkipper from
System Settings › Privacy & Security › Accessibility and add `build/YTSkipper.app` again.

## Menu

- **Enabled**: pause or resume skipping. Remembered across launches.
- **Skipped: N**: Skips since launch. A Skip is a press after which the button was gone on the next scan.
- **Quit YTSkipper**.

The icon is dimmed while disabled or unpermitted.

## Config

`docs/config.json` is created with defaults on first run and re-read whenever it changes on disk:

```json
{
  "hosts": ["www.youtube.com", "music.youtube.com"],
  "skipLabels": ["Skip", "Skip Ad", "Skip Ads"]
}
```

- `skipLabels`: exact visible texts that count as a Skip Button, compared case-insensitively with
  whitespace collapsed. "Skip navigation" never matches "Skip".
- `hosts`: exact hostnames whose pages are searched. Nothing on any other site is ever pressed.
- A missing or empty key falls back to its default. A broken file keeps the previous config and shows
  the error in the menu.

If YouTube shows its skip button with a label that is not in `skipLabels` (for example, another
interface language), the app logs `unrecognised label '…'` to the unified log; add the label to the
config. Watch the log with:

```sh
/usr/bin/log stream --predicate 'subsystem == "com.github.kanataidarov.ytskipper"' --level info
```

(The full path matters in zsh, which has its own builtin called `log`.)

## Testing end to end without waiting for an ad

```sh
make testpage
```

Open <http://localhost:8765/skip-page.html> in Safari and temporarily add `"localhost"` to `hosts`.
The page shows a Skip button after 3 s, hides it when pressed and counts the press. It also offers a
stubborn "Skip Ad" button that ignores presses (expect exactly 3 attempts) and a foreign-label mode
(expect no press and a log line). Remove `localhost` from `hosts` afterwards.

## Layout

```text
Sources/SkipCore/      pure decision logic: config, label matching, press/retry tracking, cadence
Sources/YTSkipper/     menu bar app: Safari accessibility access, scan loop, status item
Tests/SkipCoreTests/   unit tests (swift test)
Tests/Fixtures/        local HTML test page
Resources/Info.plist   bundle metadata
Makefile               build, bundle, run, test
docs/                  gitignored on purpose: runtime config and local-only ADRs
build/                 gitignored: the assembled app
```

## Scope

Foreground tabs only: Safari exposes only the tab each window currently shows, so a YouTube tab
hidden behind another tab is not reachable. Embedded players on other sites and YouTube's post-skip
banners are not handled.
