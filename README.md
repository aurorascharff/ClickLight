# ClickLight

ClickLight is a tiny macOS menu-bar app for live coding demos. It shows an immediate visual pulse at the cursor when you press, release, right-click, or drag, so viewers can distinguish your physical click from the UI response.

## Build

```bash
chmod +x build-app.sh
./build-app.sh
```

The script creates `ClickLight.app` in this folder.

## Run

Open `ClickLight.app`. macOS may ask for Accessibility permission so the app can listen for global mouse events. If the app does not see clicks, open:

System Settings -> Privacy & Security -> Accessibility

and enable ClickLight.

## Controls

The menu-bar item lets you:

- enable or disable highlights
- change size, intensity, and duration
- toggle press, release, right-click, and drag visuals
- reopen the permissions prompt
- quit the app
