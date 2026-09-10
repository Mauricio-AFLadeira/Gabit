import { GoalDirection, goalDirectionInfo } from "@mauit/shared";
import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Palette } from "../theme/colors";

interface GoalOptionRowProps {
  direction: GoalDirection;
  isSelected: boolean;
  onPress: () => void;
}

/** One radio row on the onboarding goal screen. Selected state gets a
 * filled dot and a green border. */
export function GoalOptionRow({ direction, isSelected, onPress }: GoalOptionRowProps) {
  const info = goalDirectionInfo[direction];

  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.row,
        {
          borderColor: isSelected ? Palette.green : Palette.hairline,
          opacity: pressed ? 0.85 : 1,
        },
      ]}
    >
      <View
        style={[
          styles.radio,
          {
            borderColor: isSelected ? "transparent" : Palette.controlBorder,
            backgroundColor: isSelected ? Palette.green : "transparent",
          },
        ]}
      >
        {isSelected && <View style={styles.radioDot} />}
      </View>
      <View style={styles.textColumn}>
        <Text style={styles.title}>{info.title}</Text>
        <Text style={styles.subtitle}>{info.subtitle}</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    backgroundColor: Palette.surface,
    borderWidth: 1.5,
    borderRadius: 14,
    paddingHorizontal: 18,
    paddingVertical: 16,
  },
  radio: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 1.5,
    alignItems: "center",
    justifyContent: "center",
  },
  radioDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: "#FFFFFF",
  },
  textColumn: { gap: 2, flexShrink: 1 },
  title: { fontSize: 17, fontWeight: "600", color: Palette.ink },
  subtitle: { fontSize: 13, color: Palette.inkSoft },
});
