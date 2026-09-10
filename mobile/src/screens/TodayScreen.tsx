import {
  DayLog,
  burnFraction,
  consumedFraction,
  formatSignedInteger,
  isOverBudget as computeIsOverBudget,
  mockData,
  remainingCalories,
  weekdayLabel,
} from "@mauit/shared";
import { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { useNavigation } from "@react-navigation/native";
import React, { useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { IconSquareButton, OutlineButton, PrimaryButton } from "../components/Buttons";
import { FoodEntryRow } from "../components/FoodEntryRow";
import { MacroBar } from "../components/MacroBar";
import { RadialProgressRing } from "../components/RadialProgressRing";
import { RootStackParamList } from "../navigation/types";
import { Palette } from "../theme/colors";
import { Metrics } from "../theme/metrics";
import { Typography, monoStyle, tabularNums } from "../theme/typography";

type Nav = NativeStackNavigationProp<RootStackParamList>;

/** Screens 02 and 05 — the same Today screen in its two states. One
 * number owns the screen; burn is credited as a separate arc, never
 * folded into intake; red appears only once the budget is genuinely
 * exceeded. Tap the date to flip between the two mock days. */
export function TodayScreen() {
  const navigation = useNavigation<Nav>();
  const [day, setDay] = useState<DayLog>(mockData.onTrackDay);

  const overBudget = computeIsOverBudget(day);
  const remaining = remainingCalories(day);
  const centerValue = overBudget ? formatSignedInteger(-remaining) : `${remaining}`;

  const toggleDay = () => setDay(overBudget ? mockData.onTrackDay : mockData.overBudgetDay);

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={Typography.largeTitle}>Today</Text>
        <Pressable onPress={toggleDay}>
          <Text style={[monoStyle(11.5, "400"), styles.dateLabel]}>
            {weekdayLabel(day.date).toUpperCase()}
          </Text>
        </Pressable>
      </View>

      <View style={styles.ringWrapper}>
        <RadialProgressRing
          consumedFraction={consumedFraction(day)}
          burnFraction={burnFraction(day)}
          isOverBudget={overBudget}
          centerValue={centerValue}
          centerLabel={overBudget ? "kcal over target" : "kcal remaining"}
        />
      </View>

      <View style={styles.statRow}>
        <StatLabel label="eaten" value={`${day.eatenCalories}`} color={Palette.ink} />
        <Text style={styles.dot}>·</Text>
        <StatLabel
          label="burn"
          value={formatSignedInteger(day.burnCalories)}
          color={day.burnCalories > 0 ? Palette.amberText : Palette.inkSoft}
        />
        <Text style={styles.dot}>·</Text>
        <StatLabel label="target" value={`${day.targetCalories}`} color={Palette.ink} />
      </View>

      {overBudget ? (
        <View style={styles.card}>
          {day.insightNote && <Text style={styles.insightText}>{day.insightNote}</Text>}
          <View style={styles.divider} />
          <View style={styles.actionsRow}>
            <OutlineButton
              title="Log a workout"
              height={44}
              cornerRadius={12}
              onPress={() => {}}
              style={styles.flexButton}
            />
            <OutlineButton
              title="Review entries"
              height={44}
              cornerRadius={12}
              onPress={() => {}}
              style={styles.flexButton}
            />
          </View>
        </View>
      ) : (
        <View style={[styles.card, styles.macroCard]}>
          <MacroBar
            title="Protein"
            current={day.proteinGrams}
            target={day.proteinTarget}
            color={Palette.macroProtein}
          />
          <MacroBar title="Carbs" current={day.carbsGrams} target={day.carbsTarget} color={Palette.macroCarbs} />
          <MacroBar title="Fat" current={day.fatGrams} target={day.fatTarget} color={Palette.macroFat} />
        </View>
      )}

      <View style={styles.entriesSection}>
        <View style={styles.entriesHeader}>
          <Text style={[Typography.label, styles.entriesLabel]}>
            {overBudget ? "Largest entries" : `${day.entries.length} entries`}
          </Text>
          {!overBudget && <Text style={styles.repeatLink}>Repeat yesterday</Text>}
        </View>
        <View style={styles.entriesCard}>
          {day.entries.map((entry, index) => (
            <View key={entry.id}>
              <FoodEntryRow entry={entry} />
              {index < day.entries.length - 1 && <View style={styles.rowDivider} />}
            </View>
          ))}
        </View>
      </View>

      <View style={styles.actionRow}>
        <PrimaryButton title="Log food" onPress={() => navigation.navigate("LogFood")} style={styles.flexButton} />
        <IconSquareButton glyph="↑" onPress={() => {}} />
      </View>
    </ScrollView>
  );
}

function StatLabel({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <View style={styles.statLabelRow}>
      <Text style={styles.statLabelText}>{label}</Text>
      <Text style={[styles.statValueText, tabularNums(), { color }]}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: Palette.canvas },
  content: { paddingTop: 24, paddingBottom: 40 },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-end",
    paddingHorizontal: Metrics.screenGutter,
    marginBottom: 4,
  },
  dateLabel: { color: Palette.inkSoft, letterSpacing: 0.8 },
  ringWrapper: { alignItems: "center", paddingVertical: 22 },
  statRow: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    gap: 22,
    marginBottom: 22,
  },
  dot: { color: Palette.hairline },
  statLabelRow: { flexDirection: "row", alignItems: "baseline", gap: 4 },
  statLabelText: { ...monoStyle(11, "400"), color: Palette.textTertiary },
  statValueText: { ...monoStyle(11, "600") },
  card: {
    marginHorizontal: Metrics.screenGutter,
    marginBottom: 22,
    backgroundColor: Palette.surface,
    borderWidth: 1,
    borderColor: Palette.hairline,
    borderRadius: 14,
    padding: 18,
    gap: 10,
  },
  macroCard: { flexDirection: "row", gap: 18 },
  insightText: { fontSize: 16, color: Palette.ink, lineHeight: 22 },
  divider: { height: 1, backgroundColor: Palette.hairlineSoft },
  actionsRow: { flexDirection: "row", gap: 10 },
  flexButton: { flex: 1 },
  entriesSection: { paddingHorizontal: Metrics.screenGutter, marginBottom: 18, gap: 10 },
  entriesHeader: { flexDirection: "row", justifyContent: "space-between", alignItems: "baseline" },
  entriesLabel: { color: Palette.inkSoft },
  repeatLink: { fontSize: 15, fontWeight: "600", color: Palette.greenText },
  entriesCard: {
    backgroundColor: Palette.surface,
    borderWidth: 1,
    borderColor: Palette.hairline,
    borderRadius: 14,
    overflow: "hidden",
  },
  rowDivider: { height: 1, backgroundColor: Palette.hairlineSoft, marginLeft: 16 },
  actionRow: { flexDirection: "row", gap: 10, paddingHorizontal: Metrics.screenGutter },
});
