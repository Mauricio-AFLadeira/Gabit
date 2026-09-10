import { FoodEntry, formatSignedInteger, mealTypeInfo } from "@mauit/shared";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { Palette } from "../theme/colors";
import { monoStyle, tabularNums } from "../theme/typography";

function glyphFor(entry: FoodEntry): string {
  return entry.kind.type === "exercise" ? "↑" : mealTypeInfo[entry.kind.mealType].glyph;
}

function avatarTint(entry: FoodEntry): { background: string; foreground: string } {
  if (entry.kind.type === "exercise") {
    return { background: Palette.amberTint, foreground: Palette.amberIcon };
  }
  if (entry.kind.mealType === "dinner") {
    return { background: Palette.redTint, foreground: Palette.redIcon };
  }
  return { background: Palette.greenTint, foreground: Palette.greenIcon };
}

function detailFor(entry: FoodEntry): string {
  if (entry.macros) {
    return `${entry.time} · P${entry.macros.proteinGrams} C${entry.macros.carbsGrams} F${entry.macros.fatGrams}`;
  }
  return `${entry.time} · manual estimate`;
}

interface FoodEntryRowProps {
  entry: FoodEntry;
}

/** One row in the entries list: a tinted glyph avatar, title, a mono
 * detail line, and a trailing calorie figure — colored and signed for a
 * burn credit, plain for a meal. */
export function FoodEntryRow({ entry }: FoodEntryRowProps) {
  const tint = avatarTint(entry);
  const isExercise = entry.kind.type === "exercise";

  return (
    <View style={styles.row}>
      <View style={[styles.avatar, { backgroundColor: tint.background }]}>
        <Text style={[monoStyle(10, "600"), { color: tint.foreground }]}>{glyphFor(entry)}</Text>
      </View>
      <View style={styles.textColumn}>
        <Text style={styles.title}>{entry.title}</Text>
        <Text style={[monoStyle(11, "400"), styles.detail]}>{detailFor(entry)}</Text>
      </View>
      <Text
        style={[styles.calories, tabularNums(), { color: isExercise ? Palette.amberText : Palette.ink }]}
      >
        {isExercise ? formatSignedInteger(entry.calories) : entry.calories}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  avatar: {
    width: 34,
    height: 34,
    borderRadius: 10,
    alignItems: "center",
    justifyContent: "center",
  },
  textColumn: { flex: 1, gap: 1 },
  title: { fontSize: 16, fontWeight: "600", color: Palette.ink },
  detail: { color: Palette.inkSoft },
  calories: { fontSize: 16, fontWeight: "600" },
});
