/**
 * The app never uses a bare ASCII hyphen for a negative number — every
 * signed figure (burn credit, over-budget delta, weight change, average
 * balance) gets an explicit `+` or a typographic minus.
 */

export function formatSignedInteger(value: number): string {
  return value < 0 ? `−${Math.abs(value)}` : `+${value}`;
}

export function formatSignedDecimal(value: number, fractionDigits = 1): string {
  const magnitude = Math.abs(value).toFixed(fractionDigits);
  return value < 0 ? `−${magnitude}` : `+${magnitude}`;
}
