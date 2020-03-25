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


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        // Do any additional setup after loading the view.

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
        view.sv(stack)
        stack.fillContainer().centerInContainer()
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
        zeroButton.contentEdgeInsets.left = (rowSize - padding)/2
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
    btn.setBackgroundColor(UIColor(white: 0.8, alpha: 0.6), for: .normal)
    btn.setBackgroundColor(.lightGray, for: .highlighted)
    btn.titleLabel?.font =  UIFont.systemFont(ofSize: fontSize * 0.8, weight: .medium)
    btn.setTitleColor(.black, for: .normal)
}

let operationStyle: (UIButton) -> Void = { btn in
    btn.setBackgroundColor(.orange, for: .normal)
    btn.setBackgroundColor(UIColor.orange.withAlphaComponent(0.5), for: .highlighted)
    btn.contentEdgeInsets.bottom = 5
    btn.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
    btn.setTitleColor(.white, for: .normal)
}


let numberStyle: (UIButton) -> Void = { btn in
    btn.setBackgroundColor(UIColor(white: 1, alpha: 0.2), for: .normal)
    btn.setBackgroundColor(.lightGray, for: .highlighted)
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

