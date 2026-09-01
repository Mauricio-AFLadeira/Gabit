import Foundation

/// Platform-agnostic core of Gabit.
///
/// Everything in this module compiles on Linux as well as on Apple platforms,
/// which is what lets the Docker toolchain build, test and lint it. Anything
/// that reaches for SwiftUI, UIKit or another Apple-only framework belongs in
/// `App/` instead.
public enum GabitKit {

    /// Version of the core module, kept in step with the app release.
    public static let version = "0.1.0"
}
