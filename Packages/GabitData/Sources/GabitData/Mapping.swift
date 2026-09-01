#if canImport(SwiftData)

    import Foundation

    import GabitDomain

    // The only place that knows both shapes. Keeping the translation in one file
    // means a change to a domain type produces one compiler error here rather
    // than a scattering of them across the store.

    extension ProfileRecord {

        convenience init(_ profile: Profile) {
            let kind: String
            let rate: Double
            switch profile.goal {
            case .cut(let weightRate):
                kind = "cut"
                rate = weightRate.kgPerWeek
            case .maintain:
                kind = "maintain"
                rate = 0
            case .bulk(let weightRate):
                kind = "bulk"
                rate = weightRate.kgPerWeek
            }

            self.init(
                sexRaw: profile.sex.rawValue,
                birthDate: profile.birthDate,
                heightCm: profile.heightCm,
                weightKg: profile.weightKg,
                activityRaw: profile.activity.rawValue,
                goalKindRaw: kind,
                goalRateKgPerWeek: rate
            )
        }

        /// Reads back into the domain, falling back rather than throwing.
        ///
        /// An unrecognised raw value means the store is newer than this build.
        /// Refusing to launch would be the worse failure: a sensible default
        /// lets the user keep logging while the mismatch is fixed.
        var domainValue: Profile {
            let rate = WeightRate(kgPerWeek: goalRateKgPerWeek)
            let goal: Goal =
                switch goalKindRaw {
                case "cut": .cut(rate: rate)
                case "bulk": .bulk(rate: rate)
                default: .maintain
                }

            return Profile(
                sex: Sex(rawValue: sexRaw) ?? .female,
                birthDate: birthDate,
                heightCm: heightCm,
                weightKg: weightKg,
                activity: Activity(rawValue: activityRaw) ?? .moderate,
                goal: goal
            )
        }

        func update(from profile: Profile) {
            let replacement = ProfileRecord(profile)
            sexRaw = replacement.sexRaw
            birthDate = replacement.birthDate
            heightCm = replacement.heightCm
            weightKg = replacement.weightKg
            activityRaw = replacement.activityRaw
            goalKindRaw = replacement.goalKindRaw
            goalRateKgPerWeek = replacement.goalRateKgPerWeek
        }
    }

    extension FoodEntryRecord {

        convenience init(_ entry: FoodEntry) {
            self.init(
                id: entry.id,
                name: entry.name,
                kcal: entry.kcal,
                proteinG: entry.macros?.proteinG,
                carbsG: entry.macros?.carbsG,
                fatG: entry.macros?.fatG,
                slotRaw: entry.slot.rawValue,
                loggedAt: entry.loggedAt
            )
        }

        var domainValue: FoodEntry {
            // Macros are all-or-nothing: an entry logged with calories only must
            // round-trip back as nil, not as a misleading set of zeroes.
            let macros: Macros? =
                if let proteinG, let carbsG, let fatG {
                    Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG)
                } else {
                    nil
                }

            return FoodEntry(
                id: id,
                name: name,
                kcal: kcal,
                macros: macros,
                slot: MealSlot(rawValue: slotRaw) ?? .snack,
                loggedAt: loggedAt
            )
        }
    }

    extension BurnEntryRecord {

        convenience init(_ entry: BurnEntry) {
            self.init(
                id: entry.id,
                kindRaw: entry.kind.rawValue,
                name: entry.name,
                kcal: entry.kcal,
                occurredAt: entry.occurredAt
            )
        }

        var domainValue: BurnEntry {
            BurnEntry(
                id: id,
                kind: BurnKind(rawValue: kindRaw) ?? .manual,
                name: name,
                kcal: kcal,
                occurredAt: occurredAt
            )
        }
    }

    extension WeightCheckInRecord {

        convenience init(_ checkIn: WeightCheckIn) {
            self.init(id: checkIn.id, weightKg: checkIn.weightKg, takenAt: checkIn.takenAt)
        }

        var domainValue: WeightCheckIn {
            WeightCheckIn(id: id, weightKg: weightKg, takenAt: takenAt)
        }
    }

    extension DayLogRecord {

        var domainValue: DayLog {
            DayLog(
                date: date,
                food: food.map(\.domainValue).sorted { $0.loggedAt < $1.loggedAt },
                burn: burn.map(\.domainValue).sorted { $0.occurredAt < $1.occurredAt }
            )
        }
    }

#endif
