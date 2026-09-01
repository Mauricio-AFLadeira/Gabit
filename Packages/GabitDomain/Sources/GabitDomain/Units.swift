import Foundation

/// Energy in kilocalories.
///
/// The domain deals in whole kilocalories at its boundaries but keeps the
/// arithmetic in `Double` — rounding once, at the edge, is what stops a chain
/// of intermediate roundings from drifting the daily target by a few kcal.
public typealias Kcal = Double

/// Mass in kilograms.
public typealias Kg = Double

/// Length in centimetres.
public typealias Cm = Double

/// Energy released by one kilogram of body fat.
///
/// The conventional 7,700 kcal/kg. It is the constant that turns "0.5 kg per
/// week" into a daily number, so it is stated once, here, rather than inlined
/// at each call site.
public let kcalPerKgOfFat: Kcal = 7_700

extension Kcal {

    /// Rounds to whole kilocalories for presentation and storage.
    var roundedToKcal: Kcal { (self).rounded() }
}
