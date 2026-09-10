import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Palette } from "../theme/colors";
import { monoStyle } from "../theme/typography";

interface NumericKeypadProps {
  onDigit: (digit: number) => void;
  onBackspace: () => void;
  onToggleMultiplier: () => void;
  multiplierActive: boolean;
}

type KeyValue = number | "multiplier" | "backspace";

const DIGIT_ROWS: KeyValue[][] = [
  [1, 2, 3],
  [4, 5, 6],
  [7, 8, 9],
  ["multiplier", 0, "backspace"],
];

/**
 * The design's "UIKit interop" screen was Swift-specific — SwiftUI needed
 * a `UIViewRepresentable` to drop in a custom UIKit keypad. React Native
 * doesn't have that problem: it's already the cross-platform layer, so
 * this is just a plain component, no native module required.
 */
export function NumericKeypad({
  onDigit,
  onBackspace,
  onToggleMultiplier,
  multiplierActive,
}: NumericKeypadProps) {
  return (
    <View style={styles.tray}>
      <View style={styles.macroRow}>
        {["P 20", "C 8", "F 4"].map((label) => (
          <View key={label} style={styles.macroChip}>
            <Text style={monoStyle(12, "500")}>{label}</Text>
          </View>
        ))}
      </View>

      <View style={styles.grid}>
        {DIGIT_ROWS.map((row, rowIndex) => (
          <View key={rowIndex} style={styles.gridRow}>
            {row.map((key) => (
              <KeypadKey
                key={key}
                keyValue={key}
                multiplierActive={multiplierActive}
                onDigit={onDigit}
                onBackspace={onBackspace}
                onToggleMultiplier={onToggleMultiplier}
              />
            ))}
          </View>
        ))}
      </View>
    </View>
  );
}

interface KeypadKeyProps {
  keyValue: KeyValue;
  multiplierActive: boolean;
  onDigit: (digit: number) => void;
  onBackspace: () => void;
  onToggleMultiplier: () => void;
}

function KeypadKey({ keyValue, multiplierActive, onDigit, onBackspace, onToggleMultiplier }: KeypadKeyProps) {
  if (keyValue === "multiplier") {
    return (
      <Pressable
        onPress={onToggleMultiplier}
        style={({ pressed }) => [
          styles.key,
          styles.functionKey,
          { backgroundColor: multiplierActive ? Palette.ink : Palette.keypadFunctionKey, opacity: pressed ? 0.7 : 1 },
        ]}
      >
        <Text style={[monoStyle(14, "400"), { color: multiplierActive ? "#FFFFFF" : Palette.textSecondary }]}>
          ×2
        </Text>
      </Pressable>
    );
  }

  if (keyValue === "backspace") {
    return (
      <Pressable
        onPress={onBackspace}
        style={({ pressed }) => [styles.key, styles.functionKey, { opacity: pressed ? 0.7 : 1 }]}
      >
        <Text style={styles.backspaceGlyph}>⌫</Text>
      </Pressable>
    );
  }

  return (
    <Pressable
      onPress={() => onDigit(keyValue)}
      style={({ pressed }) => [styles.key, styles.digitKey, { opacity: pressed ? 0.7 : 1 }]}
    >
      <Text style={styles.digitText}>{keyValue}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  tray: {
    backgroundColor: Palette.keypadTray,
    borderTopWidth: 1,
    borderTopColor: Palette.keypadTrayBorder,
    paddingTop: 10,
    paddingBottom: 8,
    paddingHorizontal: 6,
    gap: 8,
  },
  macroRow: { flexDirection: "row", gap: 8 },
  macroChip: {
    flex: 1,
    height: 32,
    borderRadius: 8,
    backgroundColor: Palette.surface,
    borderWidth: 1,
    borderColor: Palette.keypadKeyBorder,
    alignItems: "center",
    justifyContent: "center",
  },
  grid: { gap: 8 },
  gridRow: { flexDirection: "row", gap: 8 },
  key: {
    flex: 1,
    height: 46,
    borderRadius: 9,
    alignItems: "center",
    justifyContent: "center",
  },
  digitKey: {
    backgroundColor: Palette.surface,
    shadowColor: "#000",
    shadowOpacity: 0.09,
    shadowRadius: 0,
    shadowOffset: { width: 0, height: 1 },
    elevation: 1,
  },
  digitText: {
    fontSize: 25,
    color: Palette.ink,
    fontVariant: ["tabular-nums"],
  },
  functionKey: {
    backgroundColor: Palette.keypadFunctionKey,
  },
  backspaceGlyph: {
    fontSize: 20,
    color: Palette.textSecondary,
  },
});
