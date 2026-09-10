/**
 * The doc's rules, verbatim: "Corner radius: 14 for cards, 12 for
 * controls, 999 for pills. No other values. Spacing is a 4-point scale;
 * screen gutter is a fixed 20. Minimum hit target 44×44."
 */
export const Metrics = {
  cardRadius: 14,
  controlRadius: 12,
  pillRadius: 999,

  screenGutter: 20,
  minHitTarget: 44,

  space1: 4,
  space2: 8,
  space3: 12,
  space4: 16,
  space5: 20,
  space6: 24,
} as const;
