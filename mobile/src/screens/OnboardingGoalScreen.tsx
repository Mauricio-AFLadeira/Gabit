import { GOAL_DIRECTIONS, GoalDirection, dailyTarget, mockData } from "@mauit/shared";
import { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { useNavigation } from "@react-navigation/native";
import React, { useState } from "react";
import {
  GestureResponderEvent,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { PrimaryButton } from "../components/Buttons";
import { GoalOptionRow } from "../components/GoalOptionRow";
import { RootStackParamList } from "../navigation/types";
import { Palette } from "../theme/colors";
import { Metrics } from "../theme/metrics";
import { monoStyle, tabularNums } from "../theme/typography";

type Nav = NativeStackNavigationProp<RootStackParamList>;

/** Screen 01 — the one onboarding screen where the domain shows itself:
 * pick a direction, pick a rate, and the target is derived, never typed. */
export function OnboardingGoalScreen() {
  const navigation = useNavigation<Nav>();
  const [direction, setDirection] = useState<GoalDirection>(mockData.defaultDirection);
  const [ratePerWeek, setRatePerWeek] = useState(mockData.defaultRatePerWeek);

  const target = dailyTarget(mockData.maintenanceCalories, direction, ratePerWeek);

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <View style={styles.stepIndicator}>
        {[0, 1, 2, 3].map((index) => (
          <View
            key={index}
            style={[styles.step, { backgroundColor: index < 3 ? Palette.green : Palette.hairline }]}
          />
        ))}
      </View>

      <Text style={styles.title}>{"What are you\nworking toward?"}</Text>
      <Text style={styles.subtitle}>
        You can change this any time — the daily target recalculates itself.
      </Text>

      <View style={styles.optionsList}>
        {GOAL_DIRECTIONS.map((option) => (
          <GoalOptionRow
            key={option}
            direction={option}
            isSelected={option === direction}
            onPress={() => setDirection(option)}
          />
        ))}
      </View>

      <View style={styles.rateSection}>
        <Text style={monoStyle(11, "600")}>RATE</Text>
        <View style={styles.rateValueRow}>
          <Text style={[styles.rateValue, tabularNums()]}>{ratePerWeek.toFixed(2)}</Text>
          <Text style={monoStyle(13, "400")}>kg / week</Text>
        </View>

        <RateSlider
          value={ratePerWeek}
          min={mockData.minRatePerWeek}
          max={mockData.maxRatePerWeek}
          onChange={setRatePerWeek}
        />

        <View style={styles.rateLabels}>
          <Text style={styles.rateLabelText}>gentle</Text>
          <Text style={styles.rateLabelText}>aggressive</Text>
        </View>
      </View>

      <View style={styles.targetCard}>
        <Text style={monoStyle(10.5, "600")}>YOUR DAILY TARGET</Text>
        <View style={styles.targetRow}>
          <Text style={[styles.targetValue, tabularNums()]}>{target}</Text>
          <Text style={monoStyle(12, "400")}>kcal</Text>
          <Text style={styles.maintenanceLabel}>maintenance {mockData.maintenanceCalories}</Text>
        </View>
      </View>

      <PrimaryButton title="Continue" onPress={() => navigation.replace("Main")} />
    </ScrollView>
  );
}

interface RateSliderProps {
  value: number;
  min: number;
  max: number;
  onChange: (value: number) => void;
}

/** A hand-built track + thumb (via RN's raw responder events) rather than
 * the platform slider, to match the doc's pill track and floating disc
 * thumb exactly. */
function RateSlider({ value, min, max, onChange }: RateSliderProps) {
  const [width, setWidth] = useState(0);
  const fraction = max > min ? (value - min) / (max - min) : 0;

  const updateFromLocationX = (locationX: number) => {
    if (width <= 0) return;
    const clamped = Math.min(1, Math.max(0, locationX / width));
    onChange(min + clamped * (max - min));
  };

  const handleResponderEvent = (event: GestureResponderEvent) => {
    updateFromLocationX(event.nativeEvent.locationX);
  };

  return (
    <View
      style={styles.sliderTrack}
      onLayout={(event) => setWidth(event.nativeEvent.layout.width)}
      onStartShouldSetResponder={() => true}
      onMoveShouldSetResponder={() => true}
      onResponderGrant={handleResponderEvent}
      onResponderMove={handleResponderEvent}
    >
      <View style={styles.sliderTrackBg} />
      <View style={[styles.sliderTrackFill, { width: `${fraction * 100}%` }]} />
      <View style={[styles.sliderThumb, { left: Math.max(0, fraction * width - 14) }]} />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: Palette.canvas },
  content: { paddingHorizontal: Metrics.screenGutter, paddingTop: 32, paddingBottom: 40, gap: 4 },
  stepIndicator: { flexDirection: "row", gap: 5, marginBottom: 26 },
  step: { flex: 1, height: 3, borderRadius: 2 },
  title: {
    fontSize: 32,
    fontWeight: "700",
    color: Palette.ink,
    letterSpacing: -0.6,
    lineHeight: 38,
    marginBottom: 8,
  },
  subtitle: { fontSize: 15, color: Palette.textTertiary, marginBottom: 28 },
  optionsList: { gap: 10, marginBottom: 30 },
  rateSection: { marginBottom: 24 },
  rateValueRow: { flexDirection: "row", alignItems: "baseline", gap: 8, marginTop: 12, marginBottom: 14 },
  rateValue: { fontSize: 34, fontWeight: "600", color: Palette.ink, letterSpacing: -0.5 },
  sliderTrack: { height: 44, justifyContent: "center", marginBottom: 8 },
  sliderTrackBg: { height: 5, borderRadius: 999, backgroundColor: Palette.hairline },
  sliderTrackFill: {
    position: "absolute",
    height: 5,
    borderRadius: 999,
    backgroundColor: Palette.green,
  },
  sliderThumb: {
    position: "absolute",
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: "#FFFFFF",
    borderWidth: 1,
    borderColor: Palette.controlBorder,
    shadowColor: "#000",
    shadowOpacity: 0.12,
    shadowRadius: 3,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  rateLabels: { flexDirection: "row", justifyContent: "space-between" },
  rateLabelText: { ...monoStyle(10.5, "400"), color: Palette.inkSoft },
  targetCard: {
    backgroundColor: Palette.surface,
    borderWidth: 1,
    borderColor: Palette.hairline,
    borderRadius: 14,
    paddingHorizontal: 18,
    paddingVertical: 16,
    gap: 6,
    marginBottom: 16,
  },
  targetRow: { flexDirection: "row", alignItems: "baseline", gap: 7 },
  targetValue: { fontSize: 28, fontWeight: "600", color: Palette.ink, letterSpacing: -0.5 },
  maintenanceLabel: { fontSize: 13, color: Palette.inkSoft, marginLeft: "auto" },
});
