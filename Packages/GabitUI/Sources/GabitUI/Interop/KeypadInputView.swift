#if canImport(UIKit)

    import SwiftUI
    import UIKit

    /// The keys the pad offers. `×2` is the second-helping key: it doubles what
    /// is already entered rather than making the user retype it.
    public enum KeypadKey: Hashable, Sendable {
        case digit(Int)
        case double
        case delete

        var title: String {
            switch self {
            case .digit(let value): String(value)
            case .double: "×2"
            case .delete: "⌫"
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .digit(let value): String(value)
            case .double: "Double the amount"
            case .delete: "Delete"
            }
        }
    }

    /// The one deliberate UIKit interop, per plan §2.
    ///
    /// It earns its keep rather than decorating the project. A `UIInputView`
    /// subclass is the only way to get a pad that the system treats as a real
    /// keyboard: it inherits the keyboard background material, it participates in
    /// the input-accessory and safe-area layout, and it dismisses with the
    /// keyboard instead of sitting over the content. Rebuilding that in SwiftUI
    /// means reimplementing behaviour UIKit already has, and getting it subtly
    /// wrong on the devices you did not test.
    ///
    /// The interop stays thin: UIKit owns the pad's layout and touch handling,
    /// SwiftUI owns everything above it, and the only thing crossing the boundary
    /// is a key press.
    public struct KeypadInputView: UIViewRepresentable {

        private let onKey: (KeypadKey) -> Void

        public init(onKey: @escaping (KeypadKey) -> Void) {
            self.onKey = onKey
        }

        public func makeCoordinator() -> Coordinator {
            Coordinator(onKey: onKey)
        }

        public func makeUIView(context: Context) -> UIInputView {
            let view = KeypadView(target: context.coordinator, action: #selector(Coordinator.keyPressed(_:)))
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }

        public func updateUIView(_ uiView: UIInputView, context: Context) {
            context.coordinator.onKey = onKey
        }

        @MainActor
        public final class Coordinator: NSObject {

            var onKey: (KeypadKey) -> Void

            init(onKey: @escaping (KeypadKey) -> Void) {
                self.onKey = onKey
            }

            @objc
            func keyPressed(_ sender: UIButton) {
                guard let key = KeypadView.key(forTag: sender.tag) else { return }
                UISelectionFeedbackGenerator().selectionChanged()
                onKey(key)
            }
        }
    }

    /// The pad itself. Four rows of three, every key at least 44 points tall,
    /// per the foundations sheet.
    final class KeypadView: UIInputView {

        private static let layout: [[KeypadKey]] = [
            [.digit(1), .digit(2), .digit(3)],
            [.digit(4), .digit(5), .digit(6)],
            [.digit(7), .digit(8), .digit(9)],
            [.double, .digit(0), .delete],
        ]

        /// Buttons carry an `Int` tag, so the mapping back to a key lives here
        /// rather than being re-derived at the call site.
        static func key(forTag tag: Int) -> KeypadKey? {
            let flattened = layout.flatMap(\.self)
            guard flattened.indices.contains(tag) else { return nil }
            return flattened[tag]
        }

        init(target: Any, action: Selector) {
            super.init(frame: .zero, inputViewStyle: .keyboard)
            build(target: target, action: action)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("KeypadView is created in code only")
        }

        private func build(target: Any, action: Selector) {
            let rows = UIStackView()
            rows.axis = .vertical
            rows.distribution = .fillEqually
            rows.spacing = Layout.Space.xs
            rows.translatesAutoresizingMaskIntoConstraints = false

            var tag = 0
            for row in Self.layout {
                let stack = UIStackView()
                stack.axis = .horizontal
                stack.distribution = .fillEqually
                stack.spacing = Layout.Space.xs

                for key in row {
                    stack.addArrangedSubview(makeButton(key, tag: tag, target: target, action: action))
                    tag += 1
                }
                rows.addArrangedSubview(stack)
            }

            addSubview(rows)
            NSLayoutConstraint.activate([
                rows.topAnchor.constraint(equalTo: topAnchor, constant: Layout.Space.xs),
                rows.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.Space.xs),
                rows.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.Space.xs),
                rows.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.Space.xs),
                rows.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.minimumHitTarget * 4),
            ])
        }

        private func makeButton(
            _ key: KeypadKey,
            tag: Int,
            target: Any,
            action: Selector
        ) -> UIButton {
            var configuration = UIButton.Configuration.plain()
            configuration.title = key.title
            configuration.baseForegroundColor = UIColor.label
            configuration.background.backgroundColor = UIColor.secondarySystemGroupedBackground
            configuration.background.cornerRadius = Layout.Radius.control

            let button = UIButton(configuration: configuration)
            button.tag = tag
            button.titleLabel?.font = .preferredFont(forTextStyle: .title2)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.accessibilityLabel = key.accessibilityLabel
            button.addTarget(target, action: action, for: .touchUpInside)
            button.heightAnchor.constraint(
                greaterThanOrEqualToConstant: Layout.minimumHitTarget
            ).isActive = true
            return button
        }
    }

#endif
