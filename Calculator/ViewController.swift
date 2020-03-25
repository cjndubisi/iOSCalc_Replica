//
//  ViewController.swift
//  Calculator
//
//  Created by Chijioke on 3/25/20.
//  Copyright © 2020 Chijioke. All rights reserved.
//

import Stevia

let padding: CGFloat = 20.0
let rowSize: CGFloat = UIScreen.main.bounds.width/4.0

class ViewController: UIViewController {


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        // Do any additional setup after loading the view.

        let numberStack = buildNumberRows()
        let stack = UIStackView(arrangedSubviews: [numberStack])
        stack.spacing = padding
        stack.alignment = .center
        view.sv(stack)
        stack.fillContainer()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }


    func buildNumberRows() -> UIStackView {
        var rows = [UIStackView]()
        var currentStack: UIStackView!

        for (index, item) in (1...9).reversed().enumerated() {
            let button = RoundButton()
            numberStyle(button)
            numberConstraints(button)
            button.setTitle("\(item)", for: .normal)

            if index % 3 == 0 {
                // reverse items
                let subviews = currentStack?.arrangedSubviews
                subviews?.forEach({ $0.removeFromSuperview() })
                subviews?.reversed().forEach({ currentStack?.addArrangedSubview($0) })

                currentStack = UIStackView(arrangedSubviews: [button])
                currentStack.spacing = padding
                currentStack.distribution = .fillEqually
                currentStack.alignment = .center
                rows.append(currentStack)
            } else {
                currentStack.addArrangedSubview(button)
            }
        }

        let zeroButton = RoundButton()
        numberStyle(zeroButton)
        zeroButton.setTitle("0", for: .normal)
        zeroButton.contentHorizontalAlignment = .leading
        zeroButton.contentEdgeInsets.left = (rowSize-padding/2.0)/2
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

}


let numberStyle: (UIButton) -> Void = { btn in
    btn.setBackgroundColor(.darkGray, for: .normal)
    btn.setBackgroundColor(.lightGray, for: .highlighted)
    btn.titleLabel?.font = UIFont.systemFont(ofSize: 30)
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

