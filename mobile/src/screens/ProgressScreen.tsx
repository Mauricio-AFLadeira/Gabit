import { formatSignedDecimal, formatSignedInteger, mockData } from "@mauit/shared";
import React, { useMemo, useState } from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { OutlineButton, SegmentedPill } from "../components/Buttons";
import { MiniLineChart } from "../components/MiniLineChart";
import { Palette } from "../theme/colors";
import { Metrics } from "../theme/metrics";
import { Typography, monoStyle } from "../theme/typography";

type Range = "4w" | "12w" | "1y";

const RANGE_LABELS: Record<Range, string> = { "4w": "4 w", "12w": "12 w", "1y": "1 y" };
const RANGE_KEYS = Object.keys(RANGE_LABELS) as Range[];

function shortDate(iso: string): string {
  const date = new Date(`${iso}T00:00:00Z`);
  const day = new Intl.DateTimeFormat("en-US", { day: "2-digit", timeZone: "UTC" }).format(date);
  const month = new Intl.DateTimeFormat("en-US", { month: "short", timeZone: "UTC" }).format(date);
  return `${day} ${month}`;
}

/** Screen 04 — trend over readings. The projection states its own
 * uncertainty; a real backend would drop it entirely once the trend
 * stopped supporting one (see backend/README.md). */
export function ProgressScreen() {
  const [range, setRange] = useState<Range>("12w");
  const readings = mockData.weightReadings;

  const visible = useMemo(() => (range === "4w" ? readings.slice(-4) : readings), [range, readings]);

  const first = visible[0];
  const last = visible[visible.length - 1];
  const mid = visible[Math.floor(visible.length / 2)];

  const deltaLabel = useMemo(() => {
    if (!first || !last) return "";
    const deltaKg = first.kg - last.kg;
    const spanWeeks = Math.max(
      1,
      Math.round((new Date(last.date).getTime() - new Date(first.date).getTime()) / (7 * 24 * 60 * 60 * 1000)),
    );
    return `${formatSignedDecimal(-deltaKg)} kg / ${spanWeeks} w`;
  }, [first, last]);

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={[Typography.largeTitle, styles.title]}>Progress</Text>

      <View style={styles.rangeTabs}>
        {RANGE_KEYS.map((key) => (
          <SegmentedPill
            key={key}
            title={RANGE_LABELS[key]}
            isSelected={key === range}
            onPress={() => setRange(key)}
            height={34}
            fontSize={13.5}
          />
        ))}
      </View>

      <View style={styles.weightCard}>
        <View style={styles.weightHeaderRow}>
          <Text style={styles.weightValue}>{last ? last.kg.toFixed(1) : "—"}</Text>
          <Text style={monoStyle(13, "400")}>kg</Text>
          <Text style={[monoStyle(12, "600"), styles.deltaLabel]}>{deltaLabel}</Text>
        </View>
        <Text style={[monoStyle(10.5, "400"), styles.averageLabel]}>7-DAY AVERAGE</Text>
        <View style={styles.chartWrapper}>
          <MiniLineChart values={visible.map((reading) => reading.kg)} />
        </View>
        <View style={styles.dateRow}>
          <Text style={styles.dateText}>{first ? shortDate(first.date) : ""}</Text>
          <Text style={styles.dateText}>{mid ? shortDate(mid.date) : ""}</Text>
          <Text style={styles.dateText}>{last ? shortDate(last.date) : ""}</Text>
        </View>
      </View>

      <View style={styles.projectionCard}>
        <View style={styles.projectionAccent} />
        <View style={styles.projectionContent}>
          <Text style={[monoStyle(10, "600"), styles.projectionLabel]}>PROJECTION</Text>
          <Text style={styles.projectionBody}>
            {mockData.progressProjection.prefix}
            <Text style={styles.projectionEmphasis}>{mockData.progressProjection.emphasis}</Text>
            {mockData.progressProjection.suffix}
          </Text>
          <Text style={styles.projectionFootnote}>{mockData.progressFootnote}</Text>
        </View>
      </View>

      <View style={styles.adherenceSection}>
        <Text style={Typography.label}>Adherence</Text>
        <View style={styles.adherenceCard}>
          <StatColumn value={`${mockData.daysLogged}`} caption="days logged" />
          <StatColumn value={`${mockData.percentWithinTarget}%`} caption="within target" />
          <StatColumn value={formatSignedInteger(mockData.averageDailyBalance)} caption="avg. balance" />
        </View>
      </View>

      <OutlineButton title="Add weight check-in" strong onPress={() => {}} />
    </ScrollView>
  );
}

function StatColumn({ value, caption }: { value: string; caption: string }) {
  return (
    <View style={styles.statColumn}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statCaption}>{caption}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: Palette.canvas },
  content: { paddingHorizontal: Metrics.screenGutter, paddingTop: 24, paddingBottom: 40, gap: 14 },
  title: { marginBottom: 6 },
  rangeTabs: { flexDirection: "row", gap: 6 },
  weightCard: {
    backgroundColor: Palette.surface,
    borderWidth: 1,
    borderColor: Palette.hairline,
    borderRadius: 14,
    paddingHorizontal: 18,
    paddingTop: 18,
    paddingBottom: 14,
  },
  weightHeaderRow: { flexDirection: "row", alignItems: "baseline", gap: 8, marginBottom: 4 },
  weightValue: { fontSize: 40, fontWeight: "600", color: Palette.ink, letterSpacing: -1.2 },
  deltaLabel: { color: Palette.greenText, marginLeft: "auto" },
  averageLabel: { color: Palette.inkSoft, letterSpacing: 0.7, marginBottom: 16 },
  chartWrapper: { height: 130, marginBottom: 6 },
  dateRow: { flexDirection: "row", justifyContent: "space-between" },
  dateText: { ...monoStyle(10, "400"), color: Palette.inkSoft },
  projectionCard: {
    flexDirection: "row",
    backgroundColor: Palette.surface,
    borderWidth: 1,
    borderColor: Palette.hairline,
    borderRadius: 14,
    overflow: "hidden",
  },
  projectionAccent: { width: 3, backgroundColor: Palette.green },
  projectionContent: { flex: 1, padding: 16, gap: 7 },
  projectionLabel: { color: Palette.greenIcon, letterSpacing: 1 },
  projectionBody: { fontSize: 16, color: Palette.ink, lineHeight: 22 },
  projectionEmphasis: { fontWeight: "700" },
  projectionFootnote: { fontSize: 13, color: Palette.inkSoft, marginTop: 1 },
  adherenceSection: { gap: 10 },
  adherenceCard: {
    flexDirection: "row",
    justifyContent: "space-between",
    backgroundColor: Palette.surface,
    borderWidth: 1,
    borderColor: Palette.hairline,
    borderRadius: 14,
    paddingHorizontal: 18,
    paddingVertical: 16,
  },
  statColumn: { gap: 3 },
  statValue: { fontSize: 24, fontWeight: "600", color: Palette.ink },
  statCaption: { fontSize: 12.5, color: Palette.inkSoft },
});
