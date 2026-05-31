"use client";

import { PointerEvent, useEffect, useMemo, useRef, useState } from "react";
import {
  profiles,
  profilesById,
  toSwiftExport,
  type Profile,
  type ProfileSettings,
} from "../profiles";

type ClickKind =
  | "press"
  | "release"
  | "right"
  | "rightRelease"
  | "middle"
  | "middleRelease"
  | "drag";

type Pulse = {
  id: number;
  x: number;
  y: number;
  kind: ClickKind;
};

type TrailPoint = {
  id: number;
  x: number;
  y: number;
};

type Stroke = {
  id: number;
  points: TrailPoint[];
};

const LASER_CURSOR_FADE_MS = 420;
const LASER_STROKE_FADE_MS = 900;
const LASER_MIN_POINT_DISTANCE = 2.5;
// Matches Swift LiveShortcutLabel: 0.72s visible + 0.28s fade.
const SHORTCUT_VISIBLE_MS = 720;
const SHORTCUT_FADE_MS = 280;

// Mirrors HotKeyBinding.keyCodeToDisplayString / fallbackKeyCodeString.
// Returns the on-screen label for the pressed key, or null to skip.
function displayKey(event: KeyboardEvent): string | null {
  switch (event.code) {
    case "Space":
      return "Space";
    case "Enter":
    case "NumpadEnter":
      return "↩";
    case "Tab":
      return "⇥";
    case "Backspace":
      return "⌫";
    case "Delete":
      return "⌦";
    case "Escape":
      return "Esc";
    case "ArrowLeft":
      return "←";
    case "ArrowRight":
      return "→";
    case "ArrowDown":
      return "↓";
    case "ArrowUp":
      return "↑";
    case "PageUp":
      return "⇞";
    case "PageDown":
      return "⇟";
    case "Home":
      return "↖";
    case "End":
      return "↘";
  }
  if (/^F\d{1,2}$/.test(event.code)) return event.code;
  if (
    [
      "MetaLeft",
      "MetaRight",
      "ControlLeft",
      "ControlRight",
      "AltLeft",
      "AltRight",
      "ShiftLeft",
      "ShiftRight",
    ].includes(event.code)
  ) {
    return null;
  }
  if (event.key.length === 1) return event.key.toUpperCase();
  return null;
}

const profilesByName: Record<string, Profile> = Object.fromEntries(
  profiles.map((p) => [p.name, p]),
);
const DEFAULT_PROFILE = profilesByName.Default ?? profiles[0];

// Mirrors Swift ClickColorPreset.color values from SettingsStore.swift.
const PRESET_COLORS: Partial<
  Record<ProfileSettings["colorPreset"], [number, number, number]>
> = {
  primary: [0.0, 0.48, 1.0], // approximation of macOS accent
  blue: [0.0, 0.74, 1.0],
  green: [0.2, 0.9, 0.42],
  purple: [0.58, 0.36, 1.0],
  pink: [1.0, 0.32, 0.72],
  orange: [1.0, 0.46, 0.19],
  white: [1.0, 1.0, 1.0],
};

const DEFAULT_PER_KIND_COLOR: Record<
  "press" | "release" | "right" | "middle" | "drag",
  [number, number, number]
> = {
  press: [0.0, 0.74, 1.0],
  release: [0.4, 0.88, 1.0],
  right: [1.0, 0.46, 0.19],
  middle: [0.27, 0.92, 0.58],
  drag: [0.92, 0.84, 0.22],
};

function rgbCss(c: [number, number, number], alpha = 1) {
  const r = Math.round(Math.max(0, Math.min(1, c[0])) * 255);
  const g = Math.round(Math.max(0, Math.min(1, c[1])) * 255);
  const b = Math.round(Math.max(0, Math.min(1, c[2])) * 255);
  return alpha === 1
    ? `rgb(${r}, ${g}, ${b})`
    : `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function mixComponent(a: number, b: number) {
  return (a + b) / 2;
}

// Mirrors color(for:) in ClickOverlayView.swift.
function resolveColors(s: ProfileSettings) {
  const customLeft: [number, number, number] = [
    s.customLeftColorRed,
    s.customLeftColorGreen,
    s.customLeftColorBlue,
  ];
  const customRight: [number, number, number] = [
    s.customRightColorRed,
    s.customRightColorGreen,
    s.customRightColorBlue,
  ];
  const customMiddle: [number, number, number] = [
    s.customMiddleColorRed,
    s.customMiddleColorGreen,
    s.customMiddleColorBlue,
  ];
  const customDrag: [number, number, number] = [
    s.customDragColorRed,
    s.customDragColorGreen,
    s.customDragColorBlue,
  ];
  const customAll: [number, number, number] = [
    s.customColorRed,
    s.customColorGreen,
    s.customColorBlue,
  ];

  let press: [number, number, number];
  let release: [number, number, number];
  let right: [number, number, number];
  let middle: [number, number, number];
  let drag: [number, number, number];

  if (s.colorPreset === "custom") {
    if (s.customColorMode === "all") {
      press = release = right = middle = drag = customAll;
    } else {
      press = release = customLeft;
      right = customRight;
      middle = customMiddle;
      drag = customDrag;
    }
  } else {
    const preset = PRESET_COLORS[s.colorPreset];
    if (preset) {
      press = release = right = middle = drag = preset;
    } else {
      press = DEFAULT_PER_KIND_COLOR.press;
      release = DEFAULT_PER_KIND_COLOR.release;
      right = DEFAULT_PER_KIND_COLOR.right;
      middle = DEFAULT_PER_KIND_COLOR.middle;
      drag = DEFAULT_PER_KIND_COLOR.drag;
    }
  }

  const laserMain: [number, number, number] = [
    s.laserColorRed,
    s.laserColorGreen,
    s.laserColorBlue,
  ];
  const laserInner: [number, number, number] = [
    s.laserInnerColorRed,
    s.laserInnerColorGreen,
    s.laserInnerColorBlue,
  ];
  const laserMiddle: [number, number, number] = [
    mixComponent(laserMain[0], laserInner[0]),
    mixComponent(laserMain[1], laserInner[1]),
    mixComponent(laserMain[2], laserInner[2]),
  ];

  return {
    press,
    release,
    right,
    middle,
    drag,
    laserMain,
    laserInner,
    laserMiddle,
  };
}

// Map intensity 0.15–1.35 to UI strengths. Mirrors the Swift renderer:
// - opacity = clamp(0.18 + intensity * 0.78)
// - glow halo gated at >= 0.7 (drawGlowIfNeeded), with a hard step-up at
//   >= 1.2 (alpha multiplier 0.08 → 0.18, plus a bigger radius factor)
function deriveIntensityVars(intensity: number) {
  const clamped = Math.max(0.15, Math.min(1.35, intensity));
  const opacity = Math.min(1, 0.18 + clamped * 0.78);

  // Geometric glow size, drives box-shadow spread (a filled disc behind
  // the ring). 0 below intensity 0.7, then ramps; large boost at >= 1.2 so
  // Beacon is unmistakable.
  let glow = 0;
  let glowAlpha = 0;
  if (clamped >= 1.2) {
    // Beacon zone: big disc, ~18% alpha (matches Swift's `>= 1.2 ? 0.18`).
    glow = 0.85 + (clamped - 1.2) * 1.0; // 1.2 -> 0.85, 1.35 -> 1.0
    glowAlpha = 0.55; // visually equivalent to Swift's 0.18 since CSS disc
    // accumulates blur+spread, not a raw fill.
  } else if (clamped >= 0.7) {
    // Bright zone: moderate disc, ~8% alpha.
    glow = (clamped - 0.7) * 0.9 + 0.3; // 0.7 -> 0.3, 1.0 -> 0.57
    glowAlpha = 0.28;
  }

  // Ring thickness. Matches Swift lineWidth = max(2.25, baseSize * (0.035 + intensity * 0.045)).
  const borderScale = 0.5 + clamped * 1.1;

  return {
    "--pulse-opacity": opacity.toFixed(3),
    "--pulse-glow": glow.toFixed(3),
    "--pulse-glow-alpha": glowAlpha.toFixed(3),
    "--pulse-border-scale": borderScale.toFixed(3),
    // Drag dot diameter in Swift: 2 * (size * 0.6) * (0.08 + 0.065 * intensity).
    // Web --pulse-size is (size * 1.4), so the dot scale relative to it is
    //   (1.2 / 1.4) * (0.08 + 0.065 * intensity)  ≈  0.857 * (...).
    "--drag-dot-scale": ((1.2 / 1.4) * (0.08 + 0.065 * clamped)).toFixed(4),
  } as React.CSSProperties;
}

function settingsToCssVars(s: ProfileSettings): React.CSSProperties {
  const c = resolveColors(s);
  return {
    "--press-color": rgbCss(c.press),
    "--release-color": rgbCss(c.release),
    "--right-color": rgbCss(c.right),
    "--middle-color": rgbCss(c.middle),
    "--drag-color": rgbCss(c.drag),
    "--laser-main": rgbCss(c.laserMain),
    "--laser-middle": rgbCss(c.laserMiddle),
    "--laser-inner": rgbCss(c.laserInner),
    "--laser-outer": rgbCss(c.laserMain, 0.25),
    "--active": rgbCss(c.press),
    // Map Swift size (32–112) to a comparable pixel value for the web demo.
    "--pulse-size": `${Math.round(s.size * 1.4)}px`,
    // Swift duration is seconds.
    "--pulse-duration": `${Math.round(s.duration * 1000)}ms`,
    ...deriveIntensityVars(s.intensity),
  } as React.CSSProperties;
}

// Mirrors StatusController.compactCount: compact-name formatting with up to
// one fractional digit (e.g. 1, 999, 1K, 1.2K, 12K, 1M).
function compactCount(value: number): string {
  if (typeof Intl !== "undefined" && "NumberFormat" in Intl) {
    try {
      return new Intl.NumberFormat("en", {
        notation: "compact",
        maximumFractionDigits: 1,
      }).format(value);
    } catch {
      // fall through
    }
  }
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(1)}K`;
  return String(value);
}

let nextAnimationId = 0;
const installCommand =
  "brew install --cask aurorascharff/clicklight/clicklight";

// Mirrors Sources/ClickLight/ClickSettingOptions.swift so the submenu shows
// the same presets the macOS app does.
const SIZE_PRESETS: { title: string; value: number }[] = [
  { title: "Small", value: 44 },
  { title: "Medium", value: 64 },
  { title: "Large", value: 88 },
  { title: "Huge", value: 116 },
];
const INTENSITY_PRESETS: { title: string; value: number }[] = [
  { title: "Subtle", value: 0.28 },
  { title: "Normal", value: 0.7 },
  { title: "Bright", value: 1.0 },
  { title: "Beacon", value: 1.35 },
];
const DURATION_PRESETS: { title: string; value: number }[] = [
  { title: "Snappy", value: 0.28 },
  { title: "Normal", value: 0.48 },
  { title: "Long", value: 0.72 },
  { title: "Very Long", value: 1.0 },
];
// Mirrors ClickColorPreset.allCases (omitting `.custom`, which is reached
// by editing the per-click colors in the macOS Settings window).
const COLOR_PRESETS: { id: ProfileSettings["colorPreset"]; title: string }[] = [
  { id: "default", title: "Default" },
  { id: "primary", title: "Primary" },
  { id: "blue", title: "Blue" },
  { id: "green", title: "Green" },
  { id: "purple", title: "Purple" },
  { id: "pink", title: "Pink" },
  { id: "orange", title: "Orange" },
  { id: "white", title: "White" },
];

function approxEqual(a: number, b: number, tolerance = 0.01) {
  return Math.abs(a - b) < tolerance;
}

export default function Home() {
  const [settings, setSettings] = useState<ProfileSettings>(
    DEFAULT_PROFILE.settings,
  );
  const [profileId, setProfileId] = useState<string>(DEFAULT_PROFILE.id);
  const [pulses, setPulses] = useState<Pulse[]>([]);
  const [activeStroke, setActiveStroke] = useState<Stroke | null>(null);
  const [fadingStrokes, setFadingStrokes] = useState<Stroke[]>([]);
  const [laserCursor, setLaserCursor] = useState<TrailPoint | null>(null);
  const [laserCursorFading, setLaserCursorFading] = useState(false);
  const [shortcut, setShortcut] = useState<string | null>(null);
  const [shortcutFading, setShortcutFading] = useState(false);
  const [copiedInstall, setCopiedInstall] = useState(false);
  // Demo-only display flags. Not persisted in profiles so JSON stays
  // compatible with the Swift ClickProfileSettings schema.
  const [showMenuBarText, setShowMenuBarText] = useState(true);
  const [showMenuBarClickCount, setShowMenuBarClickCount] = useState(true);
  const [clickCount, setClickCount] = useState(0);
  const [expandedGroup, setExpandedGroup] = useState<
    "size" | "intensity" | "duration" | "colors" | null
  >(null);
  const surfaceRef = useRef<HTMLElement>(null);
  const pointerDownRef = useRef(false);
  const downPointRef = useRef<TrailPoint | null>(null);
  const lastDragPointRef = useRef<TrailPoint | null>(null);
  const hasDraggedRef = useRef(false);
  const pressedKindRef = useRef<ClickKind>("press");
  const shortcutFadeTimeoutRef = useRef<number | null>(null);
  const shortcutRemoveTimeoutRef = useRef<number | null>(null);
  const cursorFadeTimeoutRef = useRef<number | null>(null);
  const cursorRemoveTimeoutRef = useRef<number | null>(null);

  const surfaceStyle = useMemo(() => settingsToCssVars(settings), [settings]);

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (!settings.showLiveKeyboardShortcuts || event.repeat) return;
      // Mirrors Swift HotKeyBinding: require at least one non-shift modifier.
      if (!event.metaKey && !event.ctrlKey && !event.altKey) return;

      const keyString = displayKey(event);
      if (!keyString) return;

      // Some browser-reserved combos (⌘Space, ⌘Tab, ⌘H, ⌘Q, ⌘W) never reach
      // JS, but for the ones that do, prevent default browser handling so the
      // demo overlay isn't interrupted.
      event.preventDefault();

      let modifiers = "";
      if (event.ctrlKey) modifiers += "⌃";
      if (event.altKey) modifiers += "⌥";
      if (event.shiftKey) modifiers += "⇧";
      if (event.metaKey) modifiers += "⌘";

      // Swift joins modifiers and key with no separator: "⌘Space", "⌘C".
      setShortcut(modifiers + keyString);
      setShortcutFading(false);
      if (shortcutFadeTimeoutRef.current)
        window.clearTimeout(shortcutFadeTimeoutRef.current);
      if (shortcutRemoveTimeoutRef.current)
        window.clearTimeout(shortcutRemoveTimeoutRef.current);
      shortcutFadeTimeoutRef.current = window.setTimeout(() => {
        setShortcutFading(true);
        shortcutRemoveTimeoutRef.current = window.setTimeout(() => {
          setShortcut(null);
          setShortcutFading(false);
        }, SHORTCUT_FADE_MS);
      }, SHORTCUT_VISIBLE_MS);
    }

    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      if (shortcutFadeTimeoutRef.current)
        window.clearTimeout(shortcutFadeTimeoutRef.current);
      if (shortcutRemoveTimeoutRef.current)
        window.clearTimeout(shortcutRemoveTimeoutRef.current);
    };
  }, [settings.showLiveKeyboardShortcuts]);

  function pointFromEvent(event: PointerEvent<HTMLElement>) {
    const rect = surfaceRef.current?.getBoundingClientRect();
    if (!rect) return null;
    return {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top,
    };
  }

  function addPulse(event: PointerEvent<HTMLElement>, kind: ClickKind) {
    const point = pointFromEvent(event);
    if (!point) return;
    const pulse = { id: nextAnimationId++, kind, ...point };
    setPulses((current) => [...current.slice(-12), pulse]);
    window.setTimeout(() => {
      setPulses((current) => current.filter((item) => item.id !== pulse.id));
    }, 900);
  }

  function handlePointerDown(event: PointerEvent<HTMLElement>) {
    event.currentTarget.setPointerCapture(event.pointerId);
    pointerDownRef.current = true;
    const downPoint = pointFromEvent(event);
    downPointRef.current = downPoint
      ? { id: nextAnimationId++, ...downPoint }
      : null;
    lastDragPointRef.current = downPointRef.current;
    hasDraggedRef.current = false;
    // Mirrors ClickActivityStore.record: each press is one click. Drag adds
    // at most one click per gesture, handled in handlePointerMove.
    setClickCount((c) => c + 1);

    if (event.button === 2 && settings.showRightClick) {
      pressedKindRef.current = "right";
      addPulse(event, "right");
      return;
    }

    if (event.button === 1 && settings.showMiddleClick) {
      pressedKindRef.current = "middle";
      addPulse(event, "middle");
      return;
    }

    pressedKindRef.current = "press";
    if (settings.showPress) addPulse(event, "press");
  }

  function clearCursorTimers() {
    if (cursorFadeTimeoutRef.current) {
      window.clearTimeout(cursorFadeTimeoutRef.current);
      cursorFadeTimeoutRef.current = null;
    }
    if (cursorRemoveTimeoutRef.current) {
      window.clearTimeout(cursorRemoveTimeoutRef.current);
      cursorRemoveTimeoutRef.current = null;
    }
  }

  function bumpLaserCursor(point: TrailPoint) {
    clearCursorTimers();
    setLaserCursor(point);
    setLaserCursorFading(false);
    cursorFadeTimeoutRef.current = window.setTimeout(() => {
      setLaserCursorFading(true);
      cursorRemoveTimeoutRef.current = window.setTimeout(() => {
        setLaserCursor(null);
        setLaserCursorFading(false);
      }, LASER_CURSOR_FADE_MS);
    }, 16);
  }

  function clearLaserVisuals() {
    clearCursorTimers();
    setLaserCursor(null);
    setLaserCursorFading(false);
    setActiveStroke(null);
    setFadingStrokes([]);
  }

  function handlePointerMove(event: PointerEvent<HTMLElement>) {
    const point = pointFromEvent(event);
    if (!point) return;
    const nextPoint = { id: nextAnimationId++, ...point };
    const downPoint = downPointRef.current;
    if (pointerDownRef.current && downPoint) {
      const distance = Math.hypot(point.x - downPoint.x, point.y - downPoint.y);
      if (distance > 4 && !hasDraggedRef.current) {
        hasDraggedRef.current = true;
        // Matches ClickActivityStore: one click per drag gesture.
        setClickCount((c) => c + 1);
      }
    }
    const lastDragPoint = lastDragPointRef.current;
    if (
      pointerDownRef.current &&
      hasDraggedRef.current &&
      settings.showDrag &&
      lastDragPoint
    ) {
      const dragDistance = Math.hypot(
        point.x - lastDragPoint.x,
        point.y - lastDragPoint.y,
      );
      if (!settings.showLaserPointer && dragDistance > 18) {
        addPulse(event, "drag");
        lastDragPointRef.current = nextPoint;
      } else if (settings.showLaserPointer && dragDistance > 8) {
        lastDragPointRef.current = nextPoint;
      }
    }
    if (!settings.showLaserPointer) return;
    bumpLaserCursor(nextPoint);
    if (pointerDownRef.current) {
      setActiveStroke((current) => {
        if (!current) {
          return { id: nextAnimationId++, points: [nextPoint, nextPoint] };
        }
        const last = current.points[current.points.length - 1];
        if (
          Math.hypot(last.x - nextPoint.x, last.y - nextPoint.y) <
          LASER_MIN_POINT_DISTANCE
        ) {
          return current;
        }
        return { ...current, points: [...current.points, nextPoint] };
      });
    }
  }

  function handlePointerUp(event: PointerEvent<HTMLElement>) {
    if (hasDraggedRef.current && settings.showDrag) addPulse(event, "drag");
    if (settings.showRelease) {
      if (pressedKindRef.current === "right") addPulse(event, "rightRelease");
      else if (pressedKindRef.current === "middle")
        addPulse(event, "middleRelease");
      else addPulse(event, "release");
    }

    const stroke = activeStroke;
    setActiveStroke(null);
    if (stroke && stroke.points.length >= 2) {
      setFadingStrokes((strokes) => [...strokes, stroke]);
      window.setTimeout(() => {
        setFadingStrokes((strokes) =>
          strokes.filter((item) => item.id !== stroke.id),
        );
      }, LASER_STROKE_FADE_MS);
    }

    resetPointerState();
  }

  function resetPointerState() {
    pointerDownRef.current = false;
    downPointRef.current = null;
    lastDragPointRef.current = null;
    hasDraggedRef.current = false;
  }

  function clearShortcut() {
    if (shortcutFadeTimeoutRef.current) {
      window.clearTimeout(shortcutFadeTimeoutRef.current);
      shortcutFadeTimeoutRef.current = null;
    }
    if (shortcutRemoveTimeoutRef.current) {
      window.clearTimeout(shortcutRemoveTimeoutRef.current);
      shortcutRemoveTimeoutRef.current = null;
    }
    setShortcut(null);
    setShortcutFading(false);
  }

  function applyProfile(id: string) {
    const next = profilesById[id];
    if (!next) return;
    setProfileId(id);
    setSettings(next.settings);
    clearLaserVisuals();
    clearShortcut();
  }

  type SettingsToggleKey =
    | "showPress"
    | "showRelease"
    | "showRightClick"
    | "showMiddleClick"
    | "showDrag"
    | "showLaserPointer"
    | "showLiveKeyboardShortcuts";

  function toggle(key: SettingsToggleKey) {
    setSettings((current) => {
      const next: ProfileSettings = { ...current, [key]: !current[key] };
      if (key === "showLaserPointer" && !next.showLaserPointer) {
        clearLaserVisuals();
      }
      if (
        key === "showLiveKeyboardShortcuts" &&
        !next.showLiveKeyboardShortcuts
      ) {
        clearShortcut();
      }
      return next;
    });
  }

  function toggleGroup(group: "size" | "intensity" | "duration" | "colors") {
    setExpandedGroup((current) => (current === group ? null : group));
  }

  function setSettingsField<K extends keyof ProfileSettings>(
    key: K,
    value: ProfileSettings[K],
  ) {
    setSettings((current) => ({ ...current, [key]: value }));
  }

  function handlePointerLeave() {
    if (pointerDownRef.current) return;
    clearCursorTimers();
    setLaserCursorFading(true);
    cursorRemoveTimeoutRef.current = window.setTimeout(() => {
      setLaserCursor(null);
      setLaserCursorFading(false);
    }, LASER_CURSOR_FADE_MS);
  }

  async function copyInstallCommand() {
    await navigator.clipboard.writeText(installCommand);
    setCopiedInstall(true);
    window.setTimeout(() => setCopiedInstall(false), 1200);
  }

  function stopDemoEvent(event: PointerEvent<HTMLElement>) {
    event.stopPropagation();
  }

  return (
    <>
      <main
        className="surface"
        id="demo"
        ref={surfaceRef}
        style={surfaceStyle}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        onPointerCancel={resetPointerState}
        onPointerLeave={handlePointerLeave}
      >
        <div className="background" aria-hidden="true" />

        <nav
          className="topbar"
          aria-label="ClickLight navigation"
          onPointerDown={stopDemoEvent}
        >
          <a
            className="github-link"
            href="https://github.com/aurorascharff/ClickLight"
            aria-label="ClickLight source on GitHub"
          >
            <svg aria-hidden="true" viewBox="0 0 24 24">
              <path d="M12 2C6.48 2 2 6.58 2 12.22c0 4.5 2.87 8.32 6.84 9.67.5.1.68-.22.68-.49v-1.9c-2.78.62-3.37-1.22-3.37-1.22-.46-1.18-1.11-1.5-1.11-1.5-.91-.64.07-.63.07-.63 1 .07 1.53 1.06 1.53 1.06.9 1.56 2.35 1.11 2.92.85.09-.67.35-1.11.63-1.37-2.22-.26-4.56-1.13-4.56-5.04 0-1.11.39-2.02 1.03-2.73-.1-.26-.45-1.3.1-2.7 0 0 .84-.28 2.75 1.04A9.35 9.35 0 0 1 12 6.92c.85 0 1.7.12 2.5.34 1.9-1.32 2.74-1.04 2.74-1.04.55 1.4.2 2.44.1 2.7.64.71 1.03 1.62 1.03 2.73 0 3.92-2.34 4.78-4.57 5.03.36.32.68.94.68 1.9v2.82c0 .27.18.59.69.49A10.08 10.08 0 0 0 22 12.22C22 6.58 17.52 2 12 2Z" />
            </svg>
          </a>
        </nav>

        <div className="showcase">
          <section className="statement" aria-label="ClickLight demo intro">
            <div className="hero-title">
              <span className="hero-mark" aria-hidden="true" />
              <h1>ClickLight</h1>
            </div>
            <p>
              A tiny macOS menu bar app that highlights your clicks during
              demos, screen sharing, UX reviews, and anywhere people need to
              follow what you are doing.
            </p>
            <div className="install" onPointerDown={stopDemoEvent}>
              <code>{installCommand}</code>
              <button
                className={copiedInstall ? "copied" : ""}
                type="button"
                onClick={copyInstallCommand}
                aria-label={
                  copiedInstall
                    ? "Copied install command"
                    : "Copy install command"
                }
              >
                {copiedInstall ? (
                  <svg aria-hidden="true" viewBox="0 0 24 24">
                    <path d="m9.4 16.2-3.2-3.2-1.4 1.4 4.6 4.6 9.8-9.8-1.4-1.4-8.4 8.4Z" />
                  </svg>
                ) : (
                  <svg aria-hidden="true" viewBox="0 0 24 24">
                    <path d="M8 7.5A2.5 2.5 0 0 1 10.5 5h6A2.5 2.5 0 0 1 19 7.5v6a2.5 2.5 0 0 1-2.5 2.5h-6A2.5 2.5 0 0 1 8 13.5v-6Zm2.5-.5a.5.5 0 0 0-.5.5v6a.5.5 0 0 0 .5.5h6a.5.5 0 0 0 .5-.5v-6a.5.5 0 0 0-.5-.5h-6ZM5 10.5A2.5 2.5 0 0 1 7.5 8v2A.5.5 0 0 0 7 10.5v6a.5.5 0 0 0 .5.5h6a.5.5 0 0 0 .5-.5h2a2.5 2.5 0 0 1-2.5 2.5h-6A2.5 2.5 0 0 1 5 16.5v-6Z" />
                  </svg>
                )}
              </button>
            </div>
          </section>

          <aside
            className="menu"
            aria-label="ClickLight controls"
            onPointerDown={stopDemoEvent}
          >
            <div className="menu-brand" aria-hidden="true">
              <span className="menu-brand-icon" />
              {showMenuBarText && (
                <span className="menu-brand-title">ClickLight</span>
              )}
              {showMenuBarClickCount && (
                <span className="menu-brand-count">
                  {compactCount(clickCount)}
                </span>
              )}
            </div>
            <div className="menu-separator" />

            <MenuItem
              label="Laser Pointer Mode"
              checked={settings.showLaserPointer}
              onClick={() => toggle("showLaserPointer")}
            />
            <MenuItem
              label="Show Live Keyboard Shortcuts"
              checked={settings.showLiveKeyboardShortcuts}
              onClick={() => toggle("showLiveKeyboardShortcuts")}
            />

            <div className="menu-separator" />
            <MenuItem
              label="Show Press"
              checked={settings.showPress}
              onClick={() => toggle("showPress")}
            />
            <MenuItem
              label="Show Release"
              checked={settings.showRelease}
              onClick={() => toggle("showRelease")}
            />
            <MenuItem
              label="Show Right Click"
              checked={settings.showRightClick}
              onClick={() => toggle("showRightClick")}
            />
            <MenuItem
              label="Show Middle Click"
              checked={settings.showMiddleClick}
              onClick={() => toggle("showMiddleClick")}
            />
            <MenuItem
              label="Show Drag"
              checked={settings.showDrag}
              onClick={() => toggle("showDrag")}
            />

            <div className="menu-separator" />
            <MenuItem
              label="Show Menu Bar Text"
              checked={showMenuBarText}
              onClick={() => setShowMenuBarText((v) => !v)}
            />
            <MenuItem
              label="Show Click Count"
              checked={showMenuBarClickCount}
              onClick={() => setShowMenuBarClickCount((v) => !v)}
            />

            <div className="menu-separator" />
            <MenuItem
              chevron
              expanded={expandedGroup === "size"}
              label="Size"
              onClick={() => toggleGroup("size")}
            />
            {expandedGroup === "size" && (
              <>
                {SIZE_PRESETS.map((preset) => (
                  <MenuItem
                    checked={approxEqual(settings.size, preset.value)}
                    inset
                    key={preset.title}
                    label={preset.title}
                    onClick={() => setSettingsField("size", preset.value)}
                  />
                ))}
                {!SIZE_PRESETS.some((p) =>
                  approxEqual(settings.size, p.value),
                ) && (
                  <MenuItem
                    checked
                    disabled
                    inset
                    label="Custom (Configured in Settings)"
                  />
                )}
              </>
            )}
            <MenuItem
              chevron
              expanded={expandedGroup === "intensity"}
              label="Intensity"
              onClick={() => toggleGroup("intensity")}
            />
            {expandedGroup === "intensity" && (
              <>
                {INTENSITY_PRESETS.map((preset) => (
                  <MenuItem
                    checked={approxEqual(settings.intensity, preset.value)}
                    inset
                    key={preset.title}
                    label={preset.title}
                    onClick={() => setSettingsField("intensity", preset.value)}
                  />
                ))}
                {!INTENSITY_PRESETS.some((p) =>
                  approxEqual(settings.intensity, p.value),
                ) && (
                  <MenuItem
                    checked
                    disabled
                    inset
                    label="Custom (Configured in Settings)"
                  />
                )}
              </>
            )}
            <MenuItem
              chevron
              expanded={expandedGroup === "duration"}
              label="Duration"
              onClick={() => toggleGroup("duration")}
            />
            {expandedGroup === "duration" && (
              <>
                {DURATION_PRESETS.map((preset) => (
                  <MenuItem
                    checked={approxEqual(settings.duration, preset.value)}
                    inset
                    key={preset.title}
                    label={preset.title}
                    onClick={() => setSettingsField("duration", preset.value)}
                  />
                ))}
                {!DURATION_PRESETS.some((p) =>
                  approxEqual(settings.duration, p.value),
                ) && (
                  <MenuItem
                    checked
                    disabled
                    inset
                    label="Custom (Configured in Settings)"
                  />
                )}
              </>
            )}
            <MenuItem
              chevron
              expanded={expandedGroup === "colors"}
              label="Colors"
              onClick={() => toggleGroup("colors")}
            />
            {expandedGroup === "colors" && (
              <>
                {COLOR_PRESETS.map((preset) => (
                  <MenuItem
                    checked={settings.colorPreset === preset.id}
                    inset
                    key={preset.id}
                    label={preset.title}
                    onClick={() => setSettingsField("colorPreset", preset.id)}
                  />
                ))}
                {settings.colorPreset === "custom" && (
                  <MenuItem
                    checked
                    disabled
                    inset
                    label="Custom (Configured in Settings)"
                  />
                )}
              </>
            )}

            <div className="menu-separator" />
            <MenuItem disabled label="Profiles" chevron />
            {profiles.map((p) => (
              <MenuItem
                checked={profileId === p.id}
                inset
                key={p.id}
                label={p.name}
                onClick={() => applyProfile(p.id)}
              />
            ))}

            <div className="menu-separator" />
            <MenuItem disabled label="Open Settings..." shortcut="⌘," />
            <MenuItem disabled label="About ClickLight" />
          </aside>
        </div>

        <button
          type="button"
          className="export-pill"
          onClick={() =>
            downloadCurrentProfile(
              settings,
              profilesById[profileId]?.name ?? "Custom",
            )
          }
          onPointerDown={stopDemoEvent}
          aria-label="Export current settings as a ClickLight profile"
        >
          <svg aria-hidden="true" viewBox="0 0 24 24">
            <path d="M12 3a1 1 0 0 1 1 1v9.586l3.293-3.293a1 1 0 0 1 1.414 1.414l-5 5a1 1 0 0 1-1.414 0l-5-5a1 1 0 1 1 1.414-1.414L11 13.586V4a1 1 0 0 1 1-1Zm-7 14a1 1 0 0 1 1 1v1h12v-1a1 1 0 1 1 2 0v2a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-2a1 1 0 0 1 1-1Z" />
          </svg>
          <span>Export profile</span>
        </button>

        {settings.showLiveKeyboardShortcuts && shortcut && (
          <div className={`shortcut-display ${shortcutFading ? "fading" : ""}`}>
            {shortcut}
          </div>
        )}

        {settings.showLaserPointer &&
          (activeStroke || fadingStrokes.length > 0) && (
            <svg className="laser-strokes" aria-hidden="true">
              {fadingStrokes.map((stroke) => (
                <g key={stroke.id} className="laser-stroke-group fading">
                  <polyline
                    className="laser-stroke outer"
                    points={stroke.points.map((p) => `${p.x},${p.y}`).join(" ")}
                  />
                  <polyline
                    className="laser-stroke main"
                    points={stroke.points.map((p) => `${p.x},${p.y}`).join(" ")}
                  />
                  <polyline
                    className="laser-stroke middle"
                    points={stroke.points.map((p) => `${p.x},${p.y}`).join(" ")}
                  />
                  <polyline
                    className="laser-stroke inner"
                    points={stroke.points.map((p) => `${p.x},${p.y}`).join(" ")}
                  />
                </g>
              ))}
              {activeStroke && activeStroke.points.length > 1 && (
                <g className="laser-stroke-group active">
                  <polyline
                    className="laser-stroke outer"
                    points={activeStroke.points
                      .map((p) => `${p.x},${p.y}`)
                      .join(" ")}
                  />
                  <polyline
                    className="laser-stroke main"
                    points={activeStroke.points
                      .map((p) => `${p.x},${p.y}`)
                      .join(" ")}
                  />
                  <polyline
                    className="laser-stroke middle"
                    points={activeStroke.points
                      .map((p) => `${p.x},${p.y}`)
                      .join(" ")}
                  />
                  <polyline
                    className="laser-stroke inner"
                    points={activeStroke.points
                      .map((p) => `${p.x},${p.y}`)
                      .join(" ")}
                  />
                </g>
              )}
            </svg>
          )}

        {settings.showLaserPointer && laserCursor && (
          <span
            className={`laser-cursor ${laserCursorFading ? "fading" : ""}`}
            style={{ left: laserCursor.x, top: laserCursor.y }}
          />
        )}

        {pulses.map((pulse) => (
          <span
            className={`pulse ${pulse.kind}`}
            key={pulse.id}
            style={{ left: pulse.x, top: pulse.y }}
          />
        ))}
      </main>
    </>
  );
}

function downloadProfile(profile: Profile) {
  const json = JSON.stringify(toSwiftExport(profile), null, 2);
  const blob = new Blob([json], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `clicklight-${profile.name.toLowerCase().replace(/\s+/g, "-")}.json`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

// Wraps the live demo state in a Profile envelope so it can be exported
// the same way as a curated profile. A new UUID is minted each time so
// repeated exports import as separate profiles in the macOS app.
function buildCustomProfile(settings: ProfileSettings, name: string): Profile {
  const id =
    typeof crypto !== "undefined" && "randomUUID" in crypto
      ? crypto.randomUUID()
      : `custom-${Date.now()}`;
  return {
    id,
    name,
    description: "Exported from clicklight.dev",
    createdAt: new Date().toISOString(),
    settings,
  };
}

function downloadCurrentProfile(settings: ProfileSettings, name: string) {
  downloadProfile(buildCustomProfile(settings, name));
}

function MenuItem({
  checked = false,
  chevron = false,
  disabled = false,
  expanded = false,
  inset = false,
  label,
  onClick,
  shortcut,
}: {
  checked?: boolean;
  chevron?: boolean;
  disabled?: boolean;
  expanded?: boolean;
  inset?: boolean;
  label: string;
  onClick?: () => void;
  shortcut?: string;
}) {
  return (
    <button
      className={`menu-row ${inset ? "inset" : ""}`}
      disabled={disabled}
      onClick={onClick}
      type="button"
    >
      <span className="menu-check" aria-hidden="true">
        {checked ? "✓" : ""}
      </span>
      <span className="menu-label">{label}</span>
      {shortcut && <span className="menu-shortcut">{shortcut}</span>}
      {chevron && (
        <span
          className={`menu-chevron ${expanded ? "expanded" : ""}`}
          aria-hidden="true"
        >
          ›
        </span>
      )}
    </button>
  );
}
