import React from "react";
import { Pressable, StyleSheet, Text, ViewStyle } from "react-native";
import { Palette } from "../theme/colors";
import { Metrics } from "../theme/metrics";
import { Typography } from "../theme/typography";

interface PrimaryButtonProps {
  title: string;
  onPress: () => void;
  height?: number;
  style?: ViewStyle;
}

/** The doc's dark, full-width call to action — "Continue", "Log food". */
export function PrimaryButton({ title, onPress, height = 52, style }: PrimaryButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.primary,
        { height, borderRadius: Metrics.cardRadius, opacity: pressed ? 0.85 : 1 },
        style,
      ]}
    >
      <Text style={[Typography.bodyEmphasized, styles.primaryText]}>{title}</Text>
    </Pressable>
  );
}

interface OutlineButtonProps {
  title: string;
  onPress: () => void;
  height?: number;
  cornerRadius?: number;
  /** Ink border + bold text (e.g. "Add weight check-in") instead of the
   * hairline-border, semibold-15 variant (e.g. "Log a workout"). */
  strong?: boolean;
  style?: ViewStyle;
}

export function OutlineButton({
  title,
  onPress,
  height = 52,
  cornerRadius = Metrics.cardRadius,
  strong = false,
  style,
}: OutlineButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.outline,
        {
          height,
          borderRadius: cornerRadius,
          borderColor: strong ? Palette.ink : Palette.hairline,
          opacity: pressed ? 0.7 : 1,
        },
        style,
      ]}
    >
      <Text
        style={[
          strong ? Typography.bodyEmphasized : styles.outlineTextRegular,
          { color: strong ? Palette.ink : Palette.textSecondary },
        ]}
      >
        {title}
      </Text>
    </Pressable>
  );
}

interface IconSquareButtonProps {
  glyph: string;
  onPress: () => void;
  tint?: string;
  size?: number;
}

/** The square icon button next to the primary CTA on the Today screen — a
 * manual burn entry. */
export function IconSquareButton({
  glyph,
  onPress,
  tint = Palette.amberText,
  size = 52,
}: IconSquareButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.iconSquare,
        { width: size, height: size, borderRadius: Metrics.cardRadius, opacity: pressed ? 0.7 : 1 },
      ]}
    >
      <Text style={{ fontSize: 20, color: tint }}>{glyph}</Text>
    </Pressable>
  );
}

interface SegmentedPillProps {
  title: string;
  isSelected: boolean;
  onPress: () => void;
  height?: number;
  fontSize?: number;
}

/** A pill that's either the dark selected state or a hairline-bordered
 * unselected one — meal-type chips, the progress time-range tabs. Fills
 * equal width in a row, matching the design's `flex: 1` segments. */
export function SegmentedPill({
  title,
  isSelected,
  onPress,
  height = 38,
  fontSize = 14,
}: SegmentedPillProps) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.pill,
        {
          height,
          backgroundColor: isSelected ? Palette.ink : Palette.surface,
          borderColor: isSelected ? "transparent" : Palette.hairline,
          opacity: pressed ? 0.8 : 1,
        },
      ]}
    >
      <Text
        style={{
          fontSize,
          fontWeight: isSelected ? "600" : "400",
          color: isSelected ? "#FFFFFF" : Palette.textSecondary,
        }}
      >
        {title}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  primary: {
    backgroundColor: Palette.ink,
    alignItems: "center",
    justifyContent: "center",
  },
  primaryText: {
    color: "#FFFFFF",
  },
  outline: {
    backgroundColor: Palette.surface,
    borderWidth: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  outlineTextRegular: {
    fontSize: 15,
    fontWeight: "600",
  },
  iconSquare: {
    backgroundColor: Palette.surface,
    borderWidth: 1,
    borderColor: Palette.hairline,
    alignItems: "center",
    justifyContent: "center",
  },
  pill: {
    flex: 1,
    borderWidth: 1,
    borderRadius: Metrics.pillRadius,
    alignItems: "center",
    justifyContent: "center",
  },
});
