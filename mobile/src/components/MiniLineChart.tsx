import React, { useState } from "react";
import { LayoutChangeEvent, StyleSheet, View } from "react-native";
import Svg, { Circle, Line, Polyline } from "react-native-svg";
import { Palette } from "../theme/colors";

interface MiniLineChartProps {
  values: number[];
  color?: string;
}

const GRIDLINE_FRACTIONS = [0.1, 0.45, 0.8];

/** The weight-trend sparkline: three faint gridlines, a rounded polyline
 * normalized to the data's own min/max, and a dot marking the latest
 * point. Measures itself via onLayout since RN's SVG needs explicit pixel
 * dimensions (no percentage-based viewBox auto-sizing). */
export function MiniLineChart({ values, color = Palette.green }: MiniLineChartProps) {
  const [size, setSize] = useState({ width: 0, height: 0 });

  const onLayout = (event: LayoutChangeEvent) => {
    const { width, height } = event.nativeEvent.layout;
    setSize({ width, height });
  };

  const min = values.length ? Math.min(...values) : 0;
  const max = values.length ? Math.max(...values) : 1;
  const normalized = values.map((value) => (max > min ? 1 - (value - min) / (max - min) : 0.5));

  const points = normalized
    .map((value, index) => {
      const x = normalized.length > 1 ? (size.width * index) / (normalized.length - 1) : 0;
      const y = size.height * value;
      return `${x},${y}`;
    })
    .join(" ");

  const lastPoint = normalized[normalized.length - 1];

  return (
    <View style={styles.container} onLayout={onLayout}>
      {size.width > 0 && size.height > 0 && (
        <Svg width={size.width} height={size.height}>
          {GRIDLINE_FRACTIONS.map((fraction) => (
            <Line
              key={fraction}
              x1={0}
              y1={size.height * fraction}
              x2={size.width}
              y2={size.height * fraction}
              stroke={Palette.hairlineSoft}
              strokeWidth={1}
            />
          ))}
          {normalized.length > 1 && (
            <Polyline
              points={points}
              fill="none"
              stroke={color}
              strokeWidth={2.5}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          )}
          {normalized.length > 1 && lastPoint !== undefined && (
            <Circle cx={size.width} cy={size.height * lastPoint} r={4.5} fill={color} />
          )}
        </Svg>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { width: "100%", height: "100%" },
});
