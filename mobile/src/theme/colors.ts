/**
 * The foundations doc specifies every color as OKLCH — "one lightness, one
 * chroma, hue does the talking" — which React Native's style system has no
 * native support for (it wants hex/rgb()/hsl() strings). This reproduces
 * the browser's `oklch()` conversion exactly (via the OKLab intermediate
 * space) instead of eyeballing hex approximations, so the palette matches
 * the design source to the bit. Same algorithm as the Swift version's
 * `Color(oklchL:c:h:)` — kept in sync by hand since there's no shared
 * runtime between Swift and TypeScript.
 */
function oklch(l: number, c: number, h: number): string {
  const hueRadians = (h * Math.PI) / 180;
  const a = c * Math.cos(hueRadians);
  const b = c * Math.sin(hueRadians);

  const l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  const m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  const s_ = l - 0.0894841775 * a - 1.2914855480 * b;

  const l3 = l_ ** 3;
  const m3 = m_ ** 3;
  const s3 = s_ ** 3;

  const rLinear = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
  const gLinear = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
  const bLinear = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

  const gammaEncode = (x: number): number => {
    const clamped = Math.min(Math.max(x, 0), 1);
    return clamped <= 0.0031308 ? 12.92 * clamped : 1.055 * Math.pow(clamped, 1 / 2.4) - 0.055;
  };

  const r = Math.round(gammaEncode(rLinear) * 255);
  const g = Math.round(gammaEncode(gLinear) * 255);
  const bChannel = Math.round(gammaEncode(bLinear) * 255);
  return `rgb(${r}, ${g}, ${bChannel})`;
}

// -------------------------------------------------------------- Semantic -----
// "One lightness, one chroma, hue does the talking."

/** Fuel / on track. Also the color for protein and the weight trend line. */
const green = oklch(0.55, 0.11, 155);
const greenText = oklch(0.48, 0.1, 155);
const greenTextHover = oklch(0.4, 0.11, 155);
const greenIcon = oklch(0.44, 0.09, 155);
const greenTint = oklch(0.94, 0.03, 155);

/** Burn / credited. */
const amber = oklch(0.62, 0.11, 65);
const amberText = oklch(0.52, 0.11, 65);
const amberIcon = oklch(0.48, 0.1, 65);
const amberTint = oklch(0.95, 0.03, 65);

/** Over budget — the only screen allowed to use it. */
const red = oklch(0.55, 0.13, 25);
const redText = oklch(0.48, 0.13, 25);
const redIcon = oklch(0.46, 0.11, 25);
const redTint = oklch(0.95, 0.03, 25);

export const Palette = {
  // Neutrals — warm, low chroma (the doc specifies these as literal hex).
  canvas: "#F6F5F0",
  surface: "#FFFFFF",
  hairline: "#E3E1D8",
  hairlineSoft: "#EDECE5",
  inkSoft: "#8A8A7E",
  ink: "#1A1A16",
  textSecondary: "#55554D",
  textTertiary: "#6E6E62",
  controlBorder: "#D3D1C6",
  disabled: "#D3D1C6",

  // Numeric keypad tray — a slightly darker neutral shelf than the canvas.
  keypadTray: "#E6E4DB",
  keypadTrayBorder: "#D9D7CD",
  keypadKeyBorder: "#DDDBD1",
  keypadFunctionKey: "#DEDCD2",

  green,
  greenText,
  greenTextHover,
  greenIcon,
  greenTint,

  amber,
  amberText,
  amberIcon,
  amberTint,

  red,
  redText,
  redIcon,
  redTint,

  // Macros — hue-only distinction, never labels alone.
  macroProtein: green,
  macroCarbs: oklch(0.65, 0.1, 80),
  macroFat: oklch(0.58, 0.11, 25),
} as const;
