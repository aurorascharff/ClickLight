// Profile data for the website demo and downloadable JSON files.
//
// The `settings` shape mirrors Swift's ClickProfileSettings exactly, so any
// JSON downloaded from this site can be imported in the macOS app via
// Settings -> Profiles -> Import.
//
// Reference: Sources/ClickLight/ClickProfileStore.swift

export type LiveShortcutPosition = "nearPointer" | "bottomCenter";
export type LiveShortcutSize = "small" | "medium" | "large" | "extraLarge";
export type ColorPreset =
  | "default"
  | "primary"
  | "blue"
  | "green"
  | "purple"
  | "pink"
  | "orange"
  | "white"
  | "custom";
export type CustomColorMode = "all" | "byClick";

export type ProfileSettings = {
  showPress: boolean;
  showRelease: boolean;
  showRightClick: boolean;
  showMiddleClick: boolean;
  showDrag: boolean;
  showLaserPointer: boolean;
  showLiveKeyboardShortcuts: boolean;
  liveShortcutPosition: LiveShortcutPosition;
  liveShortcutSize: LiveShortcutSize;
  size: number;
  intensity: number;
  duration: number;
  colorPreset: ColorPreset;
  customColorMode: CustomColorMode;
  customColorRed: number;
  customColorGreen: number;
  customColorBlue: number;
  customLeftColorRed: number;
  customLeftColorGreen: number;
  customLeftColorBlue: number;
  customRightColorRed: number;
  customRightColorGreen: number;
  customRightColorBlue: number;
  customMiddleColorRed: number;
  customMiddleColorGreen: number;
  customMiddleColorBlue: number;
  customDragColorRed: number;
  customDragColorGreen: number;
  customDragColorBlue: number;
  laserColorRed: number;
  laserColorGreen: number;
  laserColorBlue: number;
  laserInnerColorRed: number;
  laserInnerColorGreen: number;
  laserInnerColorBlue: number;
};

export type Profile = {
  id: string;
  name: string;
  description: string;
  createdAt: string; // ISO 8601, converted to Foundation reference-date on download
  settings: ProfileSettings;
};

// Foundation's JSONEncoder default for Date is seconds-since-2001-01-01.
const REFERENCE_DATE_OFFSET_SECONDS = 978_307_200;

function toFoundationDate(iso: string): number {
  return Math.round(
    (Date.parse(iso) - REFERENCE_DATE_OFFSET_SECONDS * 1000) / 1000,
  );
}

// Wraps a profile in the same export envelope the Swift app emits.
export function toSwiftExport(profile: Profile) {
  return {
    version: 1,
    profiles: [
      {
        id: profile.id,
        name: profile.name,
        createdAt: toFoundationDate(profile.createdAt),
        settings: profile.settings,
      },
    ],
  };
}

const DEFAULT_BLUE: [number, number, number] = [0.0, 0.74, 1.0];
const DEFAULT_ORANGE: [number, number, number] = [1.0, 0.46, 0.19];
const DEFAULT_GREEN: [number, number, number] = [0.27, 0.92, 0.58];
const DEFAULT_DRAG_YELLOW: [number, number, number] = [0.92, 0.84, 0.22];
const DEFAULT_LASER_RED: [number, number, number] = [
  1.0, 0.1607843137, 0.0196078431,
];

function rgb(c: [number, number, number]) {
  return { r: c[0], g: c[1], b: c[2] };
}

function baseSettings(
  overrides: Partial<ProfileSettings> = {},
): ProfileSettings {
  return {
    showPress: true,
    showRelease: true,
    showRightClick: true,
    showMiddleClick: true,
    showDrag: true,
    showLaserPointer: false,
    showLiveKeyboardShortcuts: false,
    liveShortcutPosition: "bottomCenter",
    liveShortcutSize: "medium",
    size: 64,
    intensity: 0.7,
    duration: 0.48,
    colorPreset: "default",
    customColorMode: "all",
    customColorRed: DEFAULT_BLUE[0],
    customColorGreen: DEFAULT_BLUE[1],
    customColorBlue: DEFAULT_BLUE[2],
    customLeftColorRed: DEFAULT_BLUE[0],
    customLeftColorGreen: DEFAULT_BLUE[1],
    customLeftColorBlue: DEFAULT_BLUE[2],
    customRightColorRed: DEFAULT_ORANGE[0],
    customRightColorGreen: DEFAULT_ORANGE[1],
    customRightColorBlue: DEFAULT_ORANGE[2],
    customMiddleColorRed: DEFAULT_GREEN[0],
    customMiddleColorGreen: DEFAULT_GREEN[1],
    customMiddleColorBlue: DEFAULT_GREEN[2],
    customDragColorRed: DEFAULT_DRAG_YELLOW[0],
    customDragColorGreen: DEFAULT_DRAG_YELLOW[1],
    customDragColorBlue: DEFAULT_DRAG_YELLOW[2],
    laserColorRed: DEFAULT_LASER_RED[0],
    laserColorGreen: DEFAULT_LASER_RED[1],
    laserColorBlue: DEFAULT_LASER_RED[2],
    laserInnerColorRed: 1,
    laserInnerColorGreen: 1,
    laserInnerColorBlue: 1,
    ...overrides,
  };
}

// Stable IDs so users who download more than once don't accumulate duplicates.
export const profiles: Profile[] = [
  {
    id: "1B2EE5C0-0001-4000-8000-000000000001",
    name: "Default",
    description:
      "Balanced blue rings for everyday work — every click type shown, neutral size and timing.",
    createdAt: "2026-05-31T00:00:00Z",
    settings: baseSettings(),
  },
  {
    id: "1B2EE5C0-0007-4000-8000-000000000007",
    name: "Workshop",
    description:
      "Default style scaled up — larger rings, slower fade, and live keyboard shortcuts so a room full of people can follow what you're doing.",
    createdAt: "2026-05-31T00:00:00Z",
    settings: baseSettings({
      showLiveKeyboardShortcuts: true,
      liveShortcutSize: "large",
      size: 88,
      intensity: 1.0,
      duration: 0.72,
    }),
  },
  {
    id: "1B2EE5C0-0008-4000-8000-000000000008",
    name: "Screen Recording",
    description:
      "Smooth, slow-fading purple rings tuned to read well in compressed video — gentle intensity so the highlights guide the eye without overwhelming what you're recording.",
    createdAt: "2026-05-31T00:00:00Z",
    settings: baseSettings({
      showLiveKeyboardShortcuts: false,
      size: 64,
      intensity: 0.7,
      duration: 0.72,
      colorPreset: "purple",
    }),
  },
  {
    id: "1B2EE5C0-0003-4000-8000-000000000003",
    name: "Presentation",
    description:
      "Laser pointer on, small punchy red rings, quick fade — the one profile designed for live stage talks where the laser does the pointing and clicks are a secondary cue.",
    createdAt: "2026-05-31T00:00:00Z",
    settings: baseSettings({
      showLaserPointer: true,
      showLiveKeyboardShortcuts: false,
      size: 44,
      intensity: 0.7,
      duration: 0.28,
      colorPreset: "custom",
      customColorMode: "all",
      customColorRed: 1.0,
      customColorGreen: 0.17,
      customColorBlue: 0.14,
    }),
  },
  {
    id: "1B2EE5C0-0006-4000-8000-000000000006",
    name: "Minimal",
    description:
      "A single tiny fast white dot, only on press. Nothing else — no release, no right, no middle, no drag, no shortcuts. The least intrusive way to still see where you clicked.",
    createdAt: "2026-05-31T00:00:00Z",
    settings: baseSettings({
      showRelease: false,
      showRightClick: false,
      showMiddleClick: false,
      showDrag: false,
      showLiveKeyboardShortcuts: false,
      size: 44,
      intensity: 0.28,
      duration: 0.28,
      colorPreset: "white",
    }),
  },
];

export const profilesById: Record<string, Profile> = Object.fromEntries(
  profiles.map((p) => [p.id, p]),
);
