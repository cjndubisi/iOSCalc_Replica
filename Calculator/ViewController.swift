//
//  ViewController.swift
//  Calculator
//
//  Created by Chijioke on 3/25/20.
//  Copyright © 2020 Chijioke. All rights reserved.
//

import Stevia

let padding: CGFloat = 10.0
let rowSize: CGFloat = (UIScreen.main.bounds.width-padding*4)/4.0

class ViewController: UIViewController {

    var display: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        display = UILabel()
        display.textColor = .white
        display.text = "0"
        display.textAlignment = .right
        display.contentMode = .bottom
        display.font = UIFont.systemFont(ofSize: rowSize, weight: .thin)

        let numberStack = buildNumberRows()
        let uniaryStack = uniaryOperationStack()
        let rightOperations = buildOperationStack()
        let leftStack = UIStackView(arrangedSubviews: [uniaryStack, numberStack])
        leftStack.axis = .vertical
        leftStack.spacing = padding

        let stack = UIStackView(arrangedSubviews: [leftStack, rightOperations])
        stack.distribution = .fillProportionally
        stack.spacing = padding
        stack.alignment = .center
        view.sv(display, stack)
        view.layout(
            (>=(rowSize/2)),
            |-20-display.height(rowSize).fillHorizontally()-20-|,
            padding,
            stack.fillHorizontally().centerHorizontally(),
            rowSize/2
        )
    }

    func buildNumberRows() -> UIStackView {
        var rows = [UIStackView]()
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

        let container = UIStackView(arrangedSubviews: rows)
        container.distribution = .fillEqually
        container.spacing = padding
        container.alignment = .center
        container.axis = .vertical

        return container
    }

    func uniaryOperationStack() -> UIStackView {
        var rows = [UIButton]()

        for item in ["AC", "±", "%"] {
            let button = RoundButton()
            uniaryOperationStyle(button)
            numberConstraints(button)
            button.setTitle("\(item)", for: .normal)
            rows.append(button)
        }

        let currentStack = UIStackView(arrangedSubviews: rows)
        currentStack.spacing = padding
        currentStack.distribution = .fillEqually
        currentStack.alignment = .center

        return currentStack
    }

    func buildOperationStack() -> UIStackView {
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

        return currentStack
    }
}

let fontSize: CGFloat = 45
let uniaryOperationStyle: (UIButton) -> Void = { btn in
    btn.setBackgroundColor(ColorPalette.uniaryOperationButton, for: .normal)
    btn.setBackgroundColor(ColorPalette.uniaryOperationButtonHighlighted, for: .highlighted)
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

    static let uniaryOperationButton: UIColor = .init(red: 169/255.0, green: 166/255.0, blue: 169/255, alpha: 1)
    static let uniaryOperationButtonHighlighted: UIColor = .init(red: 219/255.0, green: 217/255.0, blue: 220/255, alpha: 1)
}
