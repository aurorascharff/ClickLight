"use client";

import { PointerEvent, useEffect, useMemo, useRef, useState } from "react";

type ClickKind = "press" | "release" | "right" | "rightRelease" | "middle" | "middleRelease" | "drag";
type ThemeName = "blue" | "green" | "red";
type ProfileName = "Default" | "Tutorial" | "Presentation";
type ToggleKey = "press" | "release" | "right" | "middle" | "drag" | "laser" | "keys";

type DemoSettings = Record<ToggleKey, boolean> & {
  theme: ThemeName;
};

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

const profiles: Record<ProfileName, DemoSettings> = {
  Default: {
    press: true,
    release: true,
    right: true,
    middle: true,
    drag: true,
    laser: false,
    keys: true,
    theme: "blue",
  },
  Tutorial: {
    press: true,
    release: true,
    right: true,
    middle: true,
    drag: true,
    laser: false,
    keys: true,
    theme: "green",
  },
  Presentation: {
    press: true,
    release: true,
    right: true,
    middle: true,
    drag: false,
    laser: true,
    keys: true,
    theme: "red",
  },
};

let nextAnimationId = 0;
const installCommand = "brew install --cask aurorascharff/clicklight/clicklight";

export default function Home() {
  const [settings, setSettings] = useState<DemoSettings>(profiles.Default);
  const [profile, setProfile] = useState<ProfileName>("Default");
  const [pulses, setPulses] = useState<Pulse[]>([]);
  const [trail, setTrail] = useState<TrailPoint[]>([]);
  const [laserCursor, setLaserCursor] = useState<TrailPoint | null>(null);
  const [shortcut, setShortcut] = useState<string | null>(null);
  const [copiedInstall, setCopiedInstall] = useState(false);
  const surfaceRef = useRef<HTMLElement>(null);
  const pointerDownRef = useRef(false);
  const downPointRef = useRef<TrailPoint | null>(null);
  const lastDragPointRef = useRef<TrailPoint | null>(null);
  const hasDraggedRef = useRef(false);
  const pressedKindRef = useRef<ClickKind>("press");
  const shortcutTimeoutRef = useRef<number | null>(null);

  const activeColor = useMemo(() => {
    if (settings.theme === "green") return "var(--mint)";
    if (settings.theme === "red") return "var(--coral)";
    return "var(--aqua)";
  }, [settings.theme]);

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (!settings.keys || event.repeat) return;
      const parts = [];
      if (event.metaKey) parts.push("⌘");
      if (event.ctrlKey) parts.push("⌃");
      if (event.altKey) parts.push("⌥");
      if (event.shiftKey) parts.push("⇧");
      const key = event.key.length === 1 ? event.key.toUpperCase() : event.key.replace("Arrow", "");
      if (!["Meta", "Control", "Alt", "Shift"].includes(event.key)) parts.push(key);
      if (parts.length === 0) return;
      setShortcut(parts.join(" "));
      if (shortcutTimeoutRef.current) window.clearTimeout(shortcutTimeoutRef.current);
      shortcutTimeoutRef.current = window.setTimeout(() => setShortcut(null), 900);
    }

    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      if (shortcutTimeoutRef.current) window.clearTimeout(shortcutTimeoutRef.current);
    };
  }, [settings.keys]);

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
    downPointRef.current = downPoint ? { id: nextAnimationId++, ...downPoint } : null;
    lastDragPointRef.current = downPointRef.current;
    hasDraggedRef.current = false;

    if (event.button === 2 && settings.right) {
      pressedKindRef.current = "right";
      addPulse(event, "right");
      return;
    }

    if (event.button === 1 && settings.middle) {
      pressedKindRef.current = "middle";
      addPulse(event, "middle");
      return;
    }

    pressedKindRef.current = "press";
    if (settings.press) addPulse(event, "press");
  }

  function handlePointerMove(event: PointerEvent<HTMLElement>) {
    const point = pointFromEvent(event);
    if (!point) return;
    const nextPoint = { id: nextAnimationId++, ...point };
    const downPoint = downPointRef.current;
    if (pointerDownRef.current && downPoint) {
      const distance = Math.hypot(point.x - downPoint.x, point.y - downPoint.y);
      if (distance > 4) hasDraggedRef.current = true;
    }
    const lastDragPoint = lastDragPointRef.current;
    if (pointerDownRef.current && hasDraggedRef.current && settings.drag && lastDragPoint) {
      const dragDistance = Math.hypot(point.x - lastDragPoint.x, point.y - lastDragPoint.y);
      if (!settings.laser && dragDistance > 18) {
        addPulse(event, "drag");
        lastDragPointRef.current = nextPoint;
      } else if (settings.laser && dragDistance > 8) {
        lastDragPointRef.current = nextPoint;
      }
    }
    if (!settings.laser) return;
    setLaserCursor(nextPoint);
    if (pointerDownRef.current) {
      setTrail((current) => [...current.slice(-34), nextPoint]);
    }
  }

  function handlePointerUp(event: PointerEvent<HTMLElement>) {
    if (hasDraggedRef.current && settings.drag) addPulse(event, "drag");
    if (settings.release) {
      if (pressedKindRef.current === "right") addPulse(event, "rightRelease");
      else if (pressedKindRef.current === "middle") addPulse(event, "middleRelease");
      else addPulse(event, "release");
    }
    resetPointerState();
    window.setTimeout(() => setTrail([]), 900);
  }

  function resetPointerState() {
    pointerDownRef.current = false;
    downPointRef.current = null;
    lastDragPointRef.current = null;
    hasDraggedRef.current = false;
  }

  function updateProfile(nextProfile: ProfileName) {
    setProfile(nextProfile);
    setSettings(profiles[nextProfile]);
    setTrail([]);
    setLaserCursor(null);
    setShortcut(null);
  }

  function toggle(key: ToggleKey) {
    setSettings((current) => ({ ...current, [key]: !current[key] }));
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
    <main
      className="surface"
      id="demo"
      ref={surfaceRef}
      style={{ "--active": activeColor } as React.CSSProperties}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerCancel={resetPointerState}
      onContextMenu={(event) => event.preventDefault()}
    >
      <div className="background" aria-hidden="true" />

      <nav className="topbar" aria-label="ClickLight navigation" onPointerDown={stopDemoEvent}>
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

      <section className="statement" aria-label="ClickLight demo intro">
        <div className="hero-title">
          <span className="hero-mark" aria-hidden="true" />
          <h1>ClickLight</h1>
        </div>
        <p>Highlights your clicks during live demos, screen sharing, and UX reviews.</p>
        <div className="install" onPointerDown={stopDemoEvent}>
          <code>{installCommand}</code>
          <button type="button" onClick={copyInstallCommand} aria-label="Copy install command">
            {copiedInstall ? "Copied" : "Copy"}
          </button>
        </div>
      </section>

      <aside className="menu" aria-label="ClickLight controls" onPointerDown={stopDemoEvent}>
        <div className="menu-title">
          <span className="status-dot" />
          <strong>ClickLight</strong>
        </div>

        <div className="profiles" aria-label="Profiles">
          {(Object.keys(profiles) as ProfileName[]).map((name) => (
            <button
              className={profile === name ? "selected" : ""}
              disabled={profile === name}
              key={name}
              onClick={() => updateProfile(name)}
              type="button"
            >
              {name}
            </button>
          ))}
        </div>

        <div className="menu-section">
          <Toggle label="Show Press" on={settings.press} onClick={() => toggle("press")} />
          <Toggle label="Show Release" on={settings.release} onClick={() => toggle("release")} />
          <Toggle label="Show Right Click" on={settings.right} onClick={() => toggle("right")} />
          <Toggle label="Show Middle Click" on={settings.middle} onClick={() => toggle("middle")} />
          <Toggle label="Show Drag" on={settings.drag} onClick={() => toggle("drag")} />
        </div>

        <div className="menu-section">
          <Toggle label="Laser Pointer Mode" on={settings.laser} onClick={() => toggle("laser")} />
          <Toggle label="Show Keystrokes" on={settings.keys} onClick={() => toggle("keys")} />
        </div>
      </aside>

      {settings.keys && shortcut && <div className="shortcut-display">{shortcut}</div>}

      {trail.length > 1 && (
        <svg className="laser-strokes" aria-hidden="true">
          <polyline className="laser-stroke outer" points={trail.map((point) => `${point.x},${point.y}`).join(" ")} />
          <polyline className="laser-stroke main" points={trail.map((point) => `${point.x},${point.y}`).join(" ")} />
          <polyline className="laser-stroke middle" points={trail.map((point) => `${point.x},${point.y}`).join(" ")} />
          <polyline className="laser-stroke inner" points={trail.map((point) => `${point.x},${point.y}`).join(" ")} />
        </svg>
      )}

      {settings.laser && laserCursor && (
        <span className="laser-cursor" style={{ left: laserCursor.x, top: laserCursor.y }} />
      )}

      {pulses.map((pulse) => (
        <span
          className={`pulse ${pulse.kind}`}
          key={pulse.id}
          style={{ left: pulse.x, top: pulse.y }}
        />
      ))}
    </main>
  );
}

function Toggle({
  label,
  on,
  onClick,
}: {
  label: string;
  on: boolean;
  onClick: () => void;
}) {
  return (
    <button className="toggle" onClick={onClick} type="button">
      <span>{label}</span>
      <span className={`switch ${on ? "on" : ""}`} aria-hidden="true">
        <span />
      </span>
    </button>
  );
}
