//
//  CalculatorViewModel.swift
//  Calculator
//
//  Created by Chijioke on 3/26/20.
//  Copyright © 2020 Chijioke. All rights reserved.
//

import RxSwift
import RxCocoa

enum Element {
    case operation(String)
    case operand(Double)
}

enum Operation {
    case constant(Double)
    case nullaryOperation(() -> Double)
    case unaryOperation((Double) -> Double)
    case binaryOperation((Double, Double) -> Double)
    case equals

    static var operations: [String: Operation] = [
        "%": Operation.unaryOperation({ $0/100 }),
        "±": Operation.unaryOperation({ -$0 }),
        "×": Operation.binaryOperation(*),
        "÷": Operation.binaryOperation(/),
        "+": Operation.binaryOperation(+),
        "-": Operation.binaryOperation(-),
        "=": Operation.equals
    ]

}
protocol Brain {
    mutating func add(operand: Double)
    mutating func add(operation: String)

    mutating func evaluate() -> Double?
}

struct CalculatorBrain: Brain {

    private var opStack = [Element]()

    mutating func add(operand: Double) {
        opStack.append(Element.operand(operand))
    }

    mutating func add(operation: String) {
        opStack.append(Element.operation(operation))
    }

    mutating func evaluate() -> Double? {
        guard opStack.count % 3 == 0 else { return nil }
        if case let .operand(value) = evaluate(stack: opStack) {
            return value
        }
        return nil
     }

    private func evaluate(stack: [Element]) -> Element? {
        var mutating = stack

        guard let element = mutating.popLast() else {
            return nil
        }
        switch element {
        case let .operation(value):
            switch Operation.operations[value] {
            case let .binaryOperation(function):
                if case let .operand(first) = mutating.popLast(), case let .operand(second) = mutating.popLast() {
                    return evaluate(stack: [Element.operand(function(second, first))] + mutating)
                }
            case .equals:
                return evaluate(stack: mutating)
            default:
                return element
            }
        case .operand:
            return element
        }

        return element
    }
}

public struct CalculatorViewModel {

    private(set) var displayDriver: Driver<String>

    // observers
    let numberPressed: AnyObserver<String>
    let binaryOperationPressed: AnyObserver<String>

    // update AC to C
    let canReset: Observable<Bool>

    // disposables
    let disposables: CompositeDisposable
    var brain: Brain!

    init() {
        let numberAction = PublishSubject<String>()
        let display = BehaviorRelay<String>(value: "0")
        let binaryOperationAction = PublishSubject<String>()

        let userIsTyping = BehaviorRelay<Bool>(value: false)
        var core: Brain = CalculatorBrain()

        let numberToDisplay = numberAction.withLatestFrom(display) { number, display in
            let isTyping = userIsTyping.value
            guard isTyping else {
                userIsTyping.accept(true)
                return number
            }
            return display + number
        }
        .bind(to: display)

        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0

        let operationTapped = userIsTyping.filter{ !$0 }
            .skip(1) // ignore first item
            .withLatestFrom(display)
            .compactMap({ formatter.number(from: $0)?.doubleValue })
            .subscribe(onNext: {
                core.add(operand: $0)
            })


        let binaryToken = binaryOperationAction.filter { !$0.isEmpty }
            .scan("", accumulator: { (acc, nextOp) -> String in
                guard Operation.operations.keys.contains(acc) else { return nextOp }

                // add current display and last operation
                core.add(operand: formatter.number(from: display.value)!.doubleValue)
                core.add(operation: acc)

                return nextOp
            })
            .subscribe(onNext: { operation in
                // handle Equals
                if let result = core.evaluate(), let number = formatter.string(from: result as NSNumber) {
                    display.accept(number)
                }
                userIsTyping.accept(false)
        })

        brain = core
        binaryOperationPressed = binaryOperationAction.asObserver()
        numberPressed = numberAction.asObserver()
        displayDriver = display.asDriver()
        canReset = userIsTyping.asObservable()
        disposables = CompositeDisposable(disposables: [numberToDisplay, binaryToken, operationTapped])
    }
}
