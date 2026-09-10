import {
  DayLog,
  EmphasizedSentence,
  GoalDirection,
  QuickAddItem,
  WeightReading,
} from "./types";

/**
 * Hand-authored sample data standing in for the persistence layer the
 * mobile app deliberately doesn't have (the API has a real Postgres
 * instead — see backend/). Every screen renders from here until it's
 * wired up to the API.
 */

// -------------------------------------------------------------- Onboarding -----

export const maintenanceCalories = 2565;
export const defaultDirection: GoalDirection = "recomposition";
export const defaultRatePerWeek = 0.35;
export const minRatePerWeek = 0.1;
export const maxRatePerWeek = 1.0;

// ------------------------------------------------------------------- Today -----

export const onTrackDay: DayLog = {
  id: "day-on-track",
  date: "2026-09-06",
  targetCalories: 2180,
  eatenCalories: 1625,
  burnCalories: 240,
  proteinGrams: 132,
  proteinTarget: 170,
  carbsGrams: 128,
  carbsTarget: 230,
  fatGrams: 46,
  fatTarget: 72,
  entries: [
    {
      id: "entry-1",
      kind: { type: "meal", mealType: "breakfast" },
      title: "Oats, whey, banana",
      time: "08:15",
      calories: 520,
      macros: { proteinGrams: 42, carbsGrams: 68, fatGrams: 9 },
    },
    {
      id: "entry-2",
      kind: { type: "meal", mealType: "lunch" },
      title: "Chicken & rice bowl",
      time: "13:40",
      calories: 735,
      macros: { proteinGrams: 62, carbsGrams: 60, fatGrams: 18 },
    },
    {
      id: "entry-3",
      kind: { type: "exercise" },
      title: "Lifting, 62 min",
      time: "18:05",
      calories: 240,
    },
  ],
};

export const overBudgetDay: DayLog = {
  id: "day-over-budget",
  date: "2026-09-04",
  targetCalories: 2180,
  eatenCalories: 2490,
  burnCalories: 0,
  proteinGrams: 150,
  proteinTarget: 170,
  carbsGrams: 210,
  carbsTarget: 230,
  fatGrams: 70,
  fatTarget: 72,
  entries: [
    {
      id: "entry-4",
      kind: { type: "meal", mealType: "dinner" },
      title: "Pizza, half",
      time: "20:50",
      calories: 910,
      macros: { proteinGrams: 38, carbsGrams: 96, fatGrams: 34 },
    },
    {
      id: "entry-5",
      kind: { type: "meal", mealType: "lunch" },
      title: "Chicken & rice bowl",
      time: "13:20",
      calories: 735,
      macros: { proteinGrams: 62, carbsGrams: 60, fatGrams: 18 },
    },
  ],
  insightNote:
    "One day over doesn't move the trend. Your 7-day average is still −390 kcal, which keeps you on pace.",
};

// -------------------------------------------------------------- Quick add -----

export const recentQuickAdds: QuickAddItem[] = [
  { id: "quick-1", title: "Oats, whey, banana", calories: 520 },
  { id: "quick-2", title: "Chicken bowl", calories: 735 },
  { id: "quick-3", title: "Coffee, oat milk", calories: 95 },
  { id: "quick-4", title: "Eggs ×3", calories: 215 },
];

// --------------------------------------------------------------- Progress -----

function buildWeightReadings(): WeightReading[] {
  const startMs = Date.UTC(2026, 5, 14); // 14 Jun 2026
  const weeklyKg = [
    81.3, 81.0, 81.1, 80.7, 80.4, 80.6, 80.0, 79.7, 79.9, 79.3, 79.0, 78.7, 78.4,
  ];
  return weeklyKg.map((kg, index) => {
    const date = new Date(startMs + index * 7 * 24 * 60 * 60 * 1000);
    return { id: `weight-${index}`, date: date.toISOString().slice(0, 10), kg };
  });
}

export const weightReadings: WeightReading[] = buildWeightReadings();

export const progressProjection: EmphasizedSentence = {
  prefix: "At your average deficit you reach ",
  emphasis: "75 kg around 14 November",
  suffix: " — roughly ten weeks out.",
};

export const progressFootnote =
  "Based on 34 readings. Recalculated every check-in; hidden when the trend flattens.";
export const daysLogged = 68;
export const percentWithinTarget = 81;
export const averageDailyBalance = -480;
