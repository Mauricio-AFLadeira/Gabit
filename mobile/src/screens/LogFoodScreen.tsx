import { MEAL_TYPES, MealType, mealTypeInfo, mockData } from "@mauit/shared";
import { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { useNavigation } from "@react-navigation/native";
import React, { useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { SegmentedPill } from "../components/Buttons";
import { NumericKeypad } from "../components/NumericKeypad";
import { RootStackParamList } from "../navigation/types";
import { Palette } from "../theme/colors";
import { Metrics } from "../theme/metrics";
import { Typography, monoStyle, tabularNums } from "../theme/typography";

type Nav = NativeStackNavigationProp<RootStackParamList>;

const MAX_DIGITS = 5;

/** Screen 03. React Native doesn't need the Swift version's UIKit-interop
 * justification for the keypad (RN already is the cross-platform layer) —
 * `NumericKeypad` here is just a plain component. */
export function LogFoodScreen() {
  const navigation = useNavigation<Nav>();
  const [selectedMeal, setSelectedMeal] = useState<MealType>("breakfast");
  const [energyDigits, setEnergyDigits] = useState("148");
  const [multiplierActive, setMultiplierActive] = useState(false);

  const typedValue = Number.parseInt(energyDigits, 10) || 0;
  const energyValue = multiplierActive ? typedValue * 2 : typedValue;

  const handleDigit = (digit: number) => {
    setEnergyDigits((current) => (current.length < MAX_DIGITS ? current + digit : current));
  };
  const handleBackspace = () => setEnergyDigits((current) => current.slice(0, -1));

  return (
    <View style={styles.screen}>
      <View style={styles.navRow}>
        <Pressable onPress={() => navigation.goBack()}>
          <Text style={styles.cancel}>Cancel</Text>
        </Pressable>
        <Text style={styles.navTitle}>Log food</Text>
        <Pressable onPress={() => navigation.goBack()} disabled={energyDigits.length === 0}>
          <Text
            style={[styles.save, { color: energyDigits.length === 0 ? Palette.disabled : Palette.ink }]}
          >
            Save
          </Text>
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} keyboardShouldPersistTaps="handled">
        <View style={styles.foodCard}>
          <View style={styles.fieldGroup}>
            <Text style={Typography.label}>What</Text>
            <Text style={styles.whatValue}>Greek yoghurt, 200 g</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.fieldGroup}>
            <Text style={Typography.label}>Energy</Text>
            <View style={styles.energyRow}>
              <Text style={[styles.energyValue, tabularNums()]}>{energyValue}</Text>
              <View style={styles.energyDivider} />
              <Text style={monoStyle(13, "400")}>kcal</Text>
            </View>
          </View>
        </View>

        <View style={styles.mealTypeRow}>
          {MEAL_TYPES.map((meal) => (
            <SegmentedPill
              key={meal}
              title={mealTypeInfo[meal].label}
              isSelected={meal === selectedMeal}
              onPress={() => setSelectedMeal(meal)}
            />
          ))}
        </View>

        <View style={styles.recentSection}>
          <Text style={Typography.label}>Recent — tap to log as is</Text>
          <View style={styles.recentChips}>
            {mockData.recentQuickAdds.map((item) => (
              <Pressable
                key={item.id}
                style={styles.chip}
                onPress={() => {
                  setEnergyDigits(`${item.calories}`);
                  navigation.goBack();
                }}
              >
                <Text style={styles.chipTitle}>{item.title}</Text>
                <Text style={monoStyle(11, "400")}>{item.calories}</Text>
              </Pressable>
            ))}
          </View>
        </View>
      </ScrollView>

      <NumericKeypad
        onDigit={handleDigit}
        onBackspace={handleBackspace}
        onToggleMultiplier={() => setMultiplierActive((active) => !active)}
        multiplierActive={multiplierActive}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: Palette.canvas },
  navRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: Metrics.screenGutter,
    paddingTop: 16,
    paddingBottom: 22,
  },
  cancel: { fontSize: 17, color: Palette.inkSoft },
  navTitle: { fontSize: 17, fontWeight: "600", color: Palette.ink },
  save: { fontSize: 17, fontWeight: "600" },
  scrollContent: { paddingHorizontal: Metrics.screenGutter, gap: 12, paddingBottom: 16 },
  foodCard: {
    backgroundColor: Palette.surface,
    borderWidth: 1,
    borderColor: Palette.hairline,
    borderRadius: 14,
    padding: 18,
    gap: 14,
  },
  fieldGroup: { gap: 4 },
  whatValue: { fontSize: 17, color: Palette.ink },
  divider: { height: 1, backgroundColor: Palette.hairlineSoft },
  energyRow: { flexDirection: "row", alignItems: "baseline", gap: 7 },
  energyValue: { fontSize: 40, fontWeight: "600", color: Palette.ink, letterSpacing: -1.2 },
  energyDivider: { width: 2, height: 34, backgroundColor: Palette.green },
  mealTypeRow: { flexDirection: "row", gap: 8 },
  recentSection: { gap: 9 },
  recentChips: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  chip: {
    flexDirection: "row",
    alignItems: "baseline",
    gap: 8,
    backgroundColor: Palette.surface,
    borderWidth: 1,
    borderColor: Palette.hairline,
    borderRadius: 999,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  chipTitle: { fontSize: 14, color: Palette.ink },
});
