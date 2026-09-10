import { Platform, TextStyle } from "react-native";

/**
 * The doc's two-family system: the system face for anything a user reads
 * (Dynamic Type and every accessibility affordance for free), and a
 * monospaced face for units, dates and small labels. The doc specifies IBM
 * Plex Mono; this ships on the platform's default monospace font so the
 * app has zero font-loading setup, with the same tabular, data-honest
 * character.
 */
const monoFontFamily = Platform.select({
  ios: "Courier",
  android: "monospace",
  default: "monospace",
});

export function monoStyle(size: number, weight: TextStyle["fontWeight"] = "500"): TextStyle {
  return { fontFamily: monoFontFamily, fontSize: size, fontWeight: weight };
}

/** Every numeral in the app is tabular — figures must not jitter while a
 * value animates. */
export function tabularNums(): TextStyle {
  return { fontVariant: ["tabular-nums"] };
}

export const Typography = {
  /** system-ui 64 / 600 — the hero figure. Pass a different size for the
   * 40pt variant on the quick-add screen. */
  heroFigure: (size = 64): TextStyle => ({ fontSize: size, fontWeight: "600" }),

  /** system-ui 32 / 700 — large title. */
  largeTitle: { fontSize: 32, fontWeight: "700" } as TextStyle,

  /** system-ui 20 / 600 — row title. */
  rowTitle: { fontSize: 20, fontWeight: "600" } as TextStyle,

  /** system-ui 17 / 400 — body, the platform default. */
  body: { fontSize: 17, fontWeight: "400" } as TextStyle,

  /** system-ui 17 / 600 — body, emphasized (buttons, selected pills). */
  bodyEmphasized: { fontSize: 17, fontWeight: "600" } as TextStyle,

  /** system-ui 15 / 400 — secondary copy and captions. */
  secondary: { fontSize: 15, fontWeight: "400" } as TextStyle,

  /** Mono, 11 / 600, wide tracking, uppercase — label / unit. */
  label: {
    ...monoStyle(11, "600"),
    letterSpacing: 1.1,
    textTransform: "uppercase",
  } as TextStyle,

  /** Mono, smaller variant for timestamps and inline units. */
  mono: monoStyle(11, "500"),
};
