//
//  ViewController.swift
//  Calculator
//
//  Created by Chijioke on 3/25/20.
//  Copyright © 2020 Chijioke. All rights reserved.
//

import Stevia
import RxSwift
import RxCocoa

let padding: CGFloat = 10.0
let rowSize: CGFloat = (UIScreen.main.bounds.width-padding*4)/4.0

class ViewController: UIViewController {

    var display: UILabel!
    var viewModel: CalculatorViewModel = .init()
    let disposeBag = DisposeBag()

    private lazy var allButtons: [UIButton] = {
        return self.view.findAll(type: UIButton.self)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        display = UILabel()
        display.textColor = .white
        display.text = "0"
        display.textAlignment = .right
        display.contentMode = .bottom
        display.font = UIFont.systemFont(ofSize: rowSize, weight: .thin)
        display.adjustsFontSizeToFitWidth = true
        display.minimumScaleFactor = 0.6

        let keypad = buildKeypadLayout()

        viewModel.displayDriver.drive(display.rx.text).disposed(by: disposeBag)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(sender:)))
        view.addGestureRecognizer(panGesture)

        // Layout Constratints
        view.sv(display, keypad)
        view.layout(
            (>=(rowSize/2)),
            |-20-display.height(rowSize).fillHorizontally()-20-|,
            padding,
            keypad.fillHorizontally().centerHorizontally(),
            rowSize/2
        )
    }

    var previousHighlighted: UIButton? {
        didSet {
            oldValue?.isHighlighted = false
        }
    }

    @objc func handleGesture(sender: UIPanGestureRecognizer) {
        let location = sender.location(in: view)
        let velocity = sender.velocity(in: view)

        let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
        let highlighted = allButtons.first(where: { $0.bounds.contains(view.convert(location, to: $0)) })
        previousHighlighted = highlighted
        switch sender.state {
        case .began, .changed:
            highlighted?.isHighlighted = true
        case .ended:
            highlighted?.isHighlighted = false
            highlighted?.sendActions(for: .touchUpInside)
            if magnitude > view.bounds.width/2 && display.frame.contains(location) {
                viewModel.delete()
            }
        default: break
        }
    }

    private func buildKeypadLayout() -> UIStackView {
        let (numberStack, buttons) = buildNumberRows()
        let (unaryStack, unaryBtns) = UnaryOperationStack()
        let (rightOperations, operationBtns) = buildOperationStack()
        let leftStack = UIStackView(arrangedSubviews: [unaryStack, numberStack])

        // Target Actions
        let numberTokens = buttons.map { btn -> Disposable in
            let title = btn.currentTitle!
            return btn.rx.tap.map({ title })
                .bind(to: viewModel.numberPressed)
        }

        let unaryToken = unaryBtns.map { btn -> Disposable in
            let title = btn.currentTitle!
            return btn.rx.tap.map({ title })
                .bind(to: viewModel.UnaryOperationPressed)
        }
        if let ACButton = unaryBtns.first(where: {
            ["c", "ac"].contains($0.currentTitle?.lowercased())
        }) {
            unowned let btn = ACButton
            ACButton.rx.tap
                .compactMap { BrainAction(rawValue: btn.currentTitle!.lowercased()) }
                .bind(to: viewModel.clearAction)
                .disposed(by: disposeBag)
            viewModel.clearTextDriver
                .drive(ACButton.rx.title())
                .disposed(by: disposeBag)
        }

        if let equalButton = operationBtns.first(where: {
            $0.currentTitle == BrainAction.evaluate.rawValue
        }) {
            equalButton.rx.tap.map { .evaluate }
                .bind(to: viewModel.equalAction).disposed(by: disposeBag)
        }

        Observable.combineLatest(
            viewModel.selectedOperation,
            Observable.just(operationBtns)
        ) { operation, buttns in
            return buttns.first(where: { $0.currentTitle == operation.rawValue })
            }
        .scan(UIButton()) { (last, next) -> UIButton? in
            last?.isHighlighted = false
            last?.isSelected = false
            next?.isSelected = true
            return next
        }
        .subscribe().disposed(by: disposeBag)

        let binaryOpsTokens = operationBtns.map { btn -> Disposable in
            let title = btn.currentTitle!
            return btn.rx.tap.map({ title }).bind(to: viewModel.binaryOperationPressed)
        }

        self.disposeBag.insert(numberTokens + binaryOpsTokens + unaryToken)


        leftStack.axis = .vertical
        leftStack.spacing = padding

        let stack = UIStackView(arrangedSubviews: [leftStack, rightOperations])
        stack.distribution = .fillProportionally
        stack.spacing = padding
        stack.alignment = .center

        return stack
    }

    private func buildNumberRows() -> (container: UIStackView, subviews: [UIButton]) {
        var rows = [UIStackView]()
        var buttons = [UIButton]()
        var currentStack: UIStackView!

        for (index, item) in (1...9).enumerated() {
            let button = RoundButton()
            numberStyle(button)
            numberConstraints(button)
            button.setTitle("\(item)", for: .normal)

            if index % 3 == 0 {

                currentStack = UIStackView(arrangedSubviews: [button])
                currentStack.spacing = padding
                currentStack.distribution = .fillEqually
                currentStack.alignment = .center
                rows.append(currentStack)
            } else {
                currentStack.addArrangedSubview(button)
            }

            buttons.append(button)
        }

        rows.reverse()

        let zeroButton = RoundButton()
        numberStyle(zeroButton)
        zeroButton.setTitle("0", for: .normal)
        zeroButton.contentHorizontalAlignment = .leading
        zeroButton.contentEdgeInsets.left = (rowSize - (padding * 2))/2
        zeroButton.height(rowSize).width((rowSize + padding / 2.0) * 2)

        let decimalButton = RoundButton()
        numberStyle(decimalButton)
        numberConstraints(decimalButton)
        decimalButton.setTitle(".", for: .normal)

        let bottomStack = UIStackView(arrangedSubviews: [zeroButton, decimalButton])
        bottomStack.spacing = padding
        bottomStack.alignment = .center
        bottomStack.distribution = .fill

        rows.append(bottomStack)
        buttons.append(contentsOf: [zeroButton, decimalButton])

        let container = UIStackView(arrangedSubviews: rows)
        container.distribution = .fillEqually
        container.spacing = padding
        container.alignment = .center
        container.axis = .vertical

        return (container, buttons)
    }

    private func UnaryOperationStack() -> (container: UIStackView, subviews: [UIButton]) {
        var rows = [UIButton]()

        for item in ["AC", "±", "%"] {
            let button = RoundButton()
            UnaryOperationStyle(button)
            numberConstraints(button)
            button.setTitle("\(item)", for: .normal)
            rows.append(button)
        }

        let currentStack = UIStackView(arrangedSubviews: rows)
        currentStack.spacing = padding
        currentStack.distribution = .fillEqually
        currentStack.alignment = .center

        return (currentStack, rows)
    }

    private func buildOperationStack() -> (container: UIStackView, subviews: [UIButton]) {
        var rows = [UIButton]()

        for item in ["=", "+", "-", "×", "÷"]{
            let button = RoundButton()
            operationStyle(button)
            numberConstraints(button)
            button.setTitle("\(item)", for: .normal)
            rows.append(button)
        }

        let currentStack = UIStackView(arrangedSubviews: rows.reversed())
        currentStack.axis = .vertical
        currentStack.spacing = padding
        currentStack.distribution = .fillEqually
        currentStack.alignment = .center

        return (currentStack, rows)
    }
}

let fontSize: CGFloat = 45
let UnaryOperationStyle: (UIButton) -> Void = { btn in
    btn.setBackgroundColor(ColorPalette.UnaryOperationButton, for: .normal)
    btn.setBackgroundColor(ColorPalette.UnaryOperationButtonHighlighted, for: .highlighted)
    btn.titleLabel?.font =  UIFont.systemFont(ofSize: fontSize * 0.8, weight: .medium)
    btn.setTitleColor(.black, for: .normal)
}

let operationStyle: (UIButton) -> Void = { btn in
    btn.setBackgroundColor(ColorPalette.binaryOperationButton, for: .normal)
    btn.setBackgroundColor(ColorPalette.binaryOperationButtonHighlighted, for: .highlighted)
    btn.setBackgroundColor(.white, for: .selected)

    btn.contentEdgeInsets.bottom = 5
    btn.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
    btn.setTitleColor(.white, for: .normal)
    btn.setTitleColor(ColorPalette.binaryOperationButton, for: .selected)
}

let numberStyle: (UIButton) -> Void = { btn in
    btn.setBackgroundColor(ColorPalette.numberButton, for: .normal)
    btn.setBackgroundColor(ColorPalette.numberButtonHighlighted, for: .highlighted)
    btn.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
    btn.setTitleColor(.white, for: .normal)
}

let numberConstraints: (UIButton) -> Void = { btn in
    btn.height(rowSize).width(rowSize)
}

class RoundButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        makeRound()
    }
}

struct ColorPalette {
    static let numberButton: UIColor = .init(red: 54/255.0, green: 51/255.0, blue: 54/255, alpha: 1)
    static let numberButtonHighlighted: UIColor = .init(red: 118/255.0, green: 116/255.0, blue: 118/255, alpha: 1)

    static let binaryOperationButton: UIColor = .init(red: 254/255.0, green: 160/255.0, blue: 43/255, alpha: 1)
    static let binaryOperationButtonHighlighted: UIColor = .init(red: 255/255.0, green: 199/255.0, blue: 148/255, alpha: 1)

    static let UnaryOperationButton: UIColor = .init(red: 169/255.0, green: 166/255.0, blue: 169/255, alpha: 1)
    static let UnaryOperationButtonHighlighted: UIColor = .init(red: 219/255.0, green: 217/255.0, blue: 220/255, alpha: 1)
}
