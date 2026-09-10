import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { Palette } from "../theme/colors";
import { monoStyle, tabularNums } from "../theme/typography";

interface MacroBarProps {
  title: string;
  current: number;
  target: number;
  color: string;
}

/** One macro's progress — hue is the only thing distinguishing protein,
 * carbs and fat, and the label is always alongside it, never hue alone. */
export function MacroBar({ title, current, target, color }: MacroBarProps) {
  const fraction = target > 0 ? Math.min(1, Math.max(0, current / target)) : 0;

  return (
    <View style={styles.container}>
      <Text style={[monoStyle(10, "600"), styles.label]}>{title.toUpperCase()}</Text>
      <View style={styles.track}>
        <View style={[styles.fill, { width: `${fraction * 100}%`, backgroundColor: color }]} />
      </View>
      <Text style={[styles.value, tabularNums()]}>
        {current} / {target} g
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, gap: 6 },
  label: { color: Palette.inkSoft, letterSpacing: 1 },
  track: {
    height: 5,
    borderRadius: 999,
    backgroundColor: Palette.hairlineSoft,
    overflow: "hidden",
  },
  fill: {
    height: 5,
    borderRadius: 999,
  },
  value: { fontSize: 13, color: Palette.textSecondary },
});
