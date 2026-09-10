import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { NavigationContainer } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import React from "react";
import { Text } from "react-native";
import { LogFoodScreen } from "../screens/LogFoodScreen";
import { OnboardingGoalScreen } from "../screens/OnboardingGoalScreen";
import { ProgressScreen } from "../screens/ProgressScreen";
import { TodayScreen } from "../screens/TodayScreen";
import { Palette } from "../theme/colors";
import { MainTabParamList, RootStackParamList } from "./types";

const RootStack = createNativeStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();

/** Onboarding leads into a Today/Progress tab flow; Today presents Log
 * food as a modal — the RN equivalent of the Swift version's `.sheet`. */
export function RootNavigator() {
  return (
    <NavigationContainer>
      <RootStack.Navigator initialRouteName="Onboarding" screenOptions={{ headerShown: false }}>
        <RootStack.Screen name="Onboarding" component={OnboardingGoalScreen} />
        <RootStack.Screen name="Main" component={MainTabs} />
        <RootStack.Group screenOptions={{ presentation: "modal" }}>
          <RootStack.Screen name="LogFood" component={LogFoodScreen} />
        </RootStack.Group>
      </RootStack.Navigator>
    </NavigationContainer>
  );
}

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: Palette.ink,
        tabBarInactiveTintColor: Palette.inkSoft,
        tabBarStyle: { backgroundColor: Palette.surface, borderTopColor: Palette.hairline },
      }}
    >
      <Tab.Screen
        name="Today"
        component={TodayScreen}
        options={{ tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 18 }}>◔</Text> }}
      />
      <Tab.Screen
        name="Progress"
        component={ProgressScreen}
        options={{ tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 18 }}>↗</Text> }}
      />
    </Tab.Navigator>
  );
}
