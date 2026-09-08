import SwiftUI
import UIKit

/// The doc's UIKit interop: a custom numeric keypad, built in UIKit and
/// bridged in through `UIViewRepresentable`. Keys are 44pt+ tall to clear
/// the doc's minimum hit target.
struct NumericKeypad: UIViewRepresentable {
    @Binding var digits: String
    @Binding var multiplierActive: Bool
    var maxDigits = 5

    func makeUIView(context: Context) -> KeypadContainerView {
        let view = KeypadContainerView()
        view.onDigit = { digit in
            guard digits.count < maxDigits else { return }
            digits.append(String(digit))
        }
        view.onBackspace = {
            guard !digits.isEmpty else { return }
            digits.removeLast()
        }
        view.onToggleMultiplier = {
            multiplierActive.toggle()
        }
        return view
    }

    func updateUIView(_ uiView: KeypadContainerView, context: Context) {
        uiView.setMultiplierActive(multiplierActive)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: KeypadContainerView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? uiView.intrinsicContentSize.width, height: uiView.intrinsicContentSize.height)
    }
}

/// Plain UIKit — no SwiftUI import inside the view itself — so it could be
/// dropped into a UIKit screen unchanged.
final class KeypadContainerView: UIView {
    var onDigit: ((Int) -> Void)?
    var onBackspace: (() -> Void)?
    var onToggleMultiplier: (() -> Void)?

    private let multiplierKey = KeyButton(title: "\u{00D7}2", style: .function)
    private let topBorder = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(Palette.keypadTray)
        buildLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMultiplierActive(_ active: Bool) {
        multiplierKey.setActive(active)
    }

    /// 4 rows × 46pt of keys + 3× 8pt row gaps + the 32pt macro-chip row +
    /// the 8pt gap above it + the container's own 10pt/8pt top/bottom inset.
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 266)
    }

    private func buildLayout() {
        topBorder.backgroundColor = UIColor(Palette.keypadTrayBorder)
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topBorder)

        let macroRow = UIStackView(arrangedSubviews: [
            macroChip("P 20"), macroChip("C 8"), macroChip("F 4"),
        ])
        macroRow.axis = .horizontal
        macroRow.spacing = 8
        macroRow.distribution = .fillEqually

        let digitGrid = makeDigitGrid()

        let stack = UIStackView(arrangedSubviews: [macroRow, digitGrid])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 1),

            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }

    private func macroChip(_ title: String) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(Palette.textSecondary)
        label.textAlignment = .center

        let container = UIView()
        container.backgroundColor = UIColor(Palette.surface)
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(Palette.keypadKeyBorder).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 32).isActive = true

        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    private func makeDigitGrid() -> UIStackView {
        let rows: [[KeyButton]] = [
            [key("1"), key("2"), key("3")],
            [key("4"), key("5"), key("6")],
            [key("7"), key("8"), key("9")],
            [multiplierKey, key("0"), key("\u{232B}", style: .function)],
        ]

        multiplierKey.addAction(UIAction { [weak self] _ in self?.onToggleMultiplier?() }, for: .touchUpInside)

        let rowStacks = rows.map { row -> UIStackView in
            let rowStack = UIStackView(arrangedSubviews: row)
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .fillEqually
            return rowStack
        }

        let grid = UIStackView(arrangedSubviews: rowStacks)
        grid.axis = .vertical
        grid.spacing = 8
        return grid
    }

    private func key(_ title: String, style: KeyButton.Style = .digit) -> KeyButton {
        let button = KeyButton(title: title, style: style)
        if let digit = Int(title) {
            button.addAction(UIAction { [weak self] _ in self?.onDigit?(digit) }, for: .touchUpInside)
        } else if title == "\u{232B}" {
            button.addAction(UIAction { [weak self] _ in self?.onBackspace?() }, for: .touchUpInside)
        }
        return button
    }
}

/// One key. Digit keys are white with a hairline drop shadow; function keys
/// (×2, backspace) sit on a flat, slightly darker fill with no shadow.
final class KeyButton: UIButton {
    enum Style {
        case digit
        case function
    }

    private let style: Style

    init(title: String, style: Style) {
        self.style = style
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 46).isActive = true
        layer.cornerRadius = 9

        setTitle(title, for: .normal)
        setTitleColor(UIColor(style == .digit ? Palette.ink : Palette.textSecondary), for: .normal)
        titleLabel?.font =
            style == .digit
            ? .monospacedDigitSystemFont(ofSize: 25, weight: .regular)
            : .monospacedSystemFont(ofSize: title == "\u{00D7}2" ? 14 : 20, weight: .regular)

        applyIdleAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Only meaningful for the ×2 multiplier key.
    func setActive(_ active: Bool) {
        backgroundColor = UIColor(active ? Palette.ink : Palette.keypadFunctionKey)
        setTitleColor(active ? .white : UIColor(Palette.textSecondary), for: .normal)
    }

    private func applyIdleAppearance() {
        switch style {
        case .digit:
            backgroundColor = UIColor(Palette.surface)
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.09
            layer.shadowRadius = 0
            layer.shadowOffset = CGSize(width: 0, height: 1)
        case .function:
            backgroundColor = UIColor(Palette.keypadFunctionKey)
        }
    }
}
