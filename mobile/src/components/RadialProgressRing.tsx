import React from "react";
import { StyleSheet, Text, View } from "react-native";
import Svg, { Circle } from "react-native-svg";
import { Palette } from "../theme/colors";
import { Typography, tabularNums } from "../theme/typography";

interface RadialProgressRingProps {
  consumedFraction: number;
  burnFraction: number;
  isOverBudget: boolean;
  centerValue: string;
  centerLabel: string;
}

const DIAMETER = 236;
const CENTER = DIAMETER / 2;
const OUTER_RADIUS = 104;
const OUTER_STROKE = 14;
const INNER_RADIUS = 84;
const INNER_STROKE = 5;
const OUTER_CIRCUMFERENCE = 2 * Math.PI * OUTER_RADIUS;
const INNER_CIRCUMFERENCE = 2 * Math.PI * INNER_RADIUS;

/** The Today screen's donut: a thick outer arc for calories consumed (net
 * of burn), a thin inner arc crediting burn back separately — it is never
 * folded into the intake figure — and a hero number in the center. */
export function RadialProgressRing({
  consumedFraction,
  burnFraction,
  isOverBudget,
  centerValue,
  centerLabel,
}: RadialProgressRingProps) {
  const outerFraction = isOverBudget ? 1 : consumedFraction;
  const outerDashoffset = OUTER_CIRCUMFERENCE * (1 - outerFraction);
  const innerDashoffset = INNER_CIRCUMFERENCE * (1 - burnFraction);

  return (
    <View style={styles.container}>
      <Svg width={DIAMETER} height={DIAMETER} style={StyleSheet.absoluteFill}>
        <Circle
          cx={CENTER}
          cy={CENTER}
          r={OUTER_RADIUS}
          stroke={Palette.hairline}
          strokeWidth={OUTER_STROKE}
          fill="none"
        />
        <Circle
          cx={CENTER}
          cy={CENTER}
          r={OUTER_RADIUS}
          stroke={isOverBudget ? Palette.red : Palette.green}
          strokeWidth={OUTER_STROKE}
          strokeLinecap="round"
          strokeDasharray={`${OUTER_CIRCUMFERENCE} ${OUTER_CIRCUMFERENCE}`}
          strokeDashoffset={outerDashoffset}
          fill="none"
          rotation={-90}
          origin={`${CENTER}, ${CENTER}`}
        />
        {!isOverBudget && burnFraction > 0 && (
          <Circle
            cx={CENTER}
            cy={CENTER}
            r={INNER_RADIUS}
            stroke={Palette.amber}
            strokeWidth={INNER_STROKE}
            strokeLinecap="round"
            strokeDasharray={`${INNER_CIRCUMFERENCE} ${INNER_CIRCUMFERENCE}`}
            strokeDashoffset={innerDashoffset}
            fill="none"
            rotation={-90}
            origin={`${CENTER}, ${CENTER}`}
          />
        )}
      </Svg>
      <View style={styles.centerContent}>
        <Text
          style={[
            Typography.heroFigure(64),
            tabularNums(),
            { color: isOverBudget ? Palette.redText : Palette.ink, letterSpacing: -1.9 },
          ]}
        >
          {centerValue}
        </Text>
        <Text style={[Typography.label, styles.centerLabel]}>{centerLabel}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: DIAMETER,
    height: DIAMETER,
    alignItems: "center",
    justifyContent: "center",
  },
  centerContent: {
    alignItems: "center",
  },
  centerLabel: {
    color: Palette.inkSoft,
    marginTop: 2,
  },
});
