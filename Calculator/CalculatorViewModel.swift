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
    case operation(Operation)
    case operand(Double)
}

enum Precedence: Int {
    case high = 10
    case low = 5
}

enum Operation: String {
    case multiply = "×"
    case divide = "÷"
    case add = "+"
    case subtract = "-"

    var action: (Double, Double) -> Double {
        switch self {
            case Operation.multiply: return  (*)
            case Operation.divide: return  (/)
            case Operation.add: return  (+)
            case Operation.subtract: return  (-)
        }
    }

    var precedence: Precedence {
        switch self {
        case Operation.multiply: return  .high
        case Operation.divide: return  .high
        case Operation.add: return  .low
        case Operation.subtract: return  .low
        }
    }

}
protocol Brain {
    mutating func add(operand: Double)
    mutating func add(operation: Operation)

    mutating func evaluate() -> Double?
    mutating func evaluate(with operation: Operation) -> Double?
}

struct CalculatorBrain: Brain {

    private var opStack = [Element]()

    mutating func add(operand: Double) {
        opStack.append(Element.operand(operand))
    }

    mutating func add(operation: Operation) {
        opStack.append(.operation(operation))
    }

    mutating func evaluate() -> Double? {
        let result = evaluate(precedence: .low, stack: opStack)
        return result.result
     }

    mutating func evaluate(with operation: Operation) -> Double? {
        return evaluate(precedence: operation.precedence, stack: opStack).result
    }

    private func evaluate(precedence: Precedence, stack: [Element]) -> (result: Double?, precedence: Precedence, remaining: [Element]) {
        var mutating = stack

        guard let element = mutating.popLast() else {
            return (nil, .low, mutating)
        }

        switch element {
        case let .operation(value):
            // call recursively to evalute operation
            return evaluate(precedence:  value.precedence, stack: mutating)
        case let .operand(value):
            if case let .operation(op) = mutating.last {
                if precedence.rawValue > op.precedence.rawValue {
                    // handle when the next operation is less (-, +) than a higer_op (x, /)
                    return (value, precedence, mutating)
                } else if precedence.rawValue == op.precedence.rawValue {
                    let result = evaluate(precedence: op.precedence, stack: mutating)
                    if let operand2 = result.result {
                        return (op.action(operand2, value), op.precedence, result.remaining)
                    }
                } else {
                    let result = evaluate(precedence: op.precedence, stack: mutating)
                    if let operand2 = result.result {
                        let rest = op.action(operand2, value)
                        return evaluate(precedence: .low, stack: result.remaining + [.operand(rest)])
                    }
                }
            }
            return (value, .low, mutating)
        }
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

        // convert to type
        let typedBinaryAction = binaryOperationAction
            .asObservable()
            .compactMap({ Operation(rawValue: $0)})

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
        formatter.maximumFractionDigits = 50


        let operationTapped = Observable.combineLatest(
            display.compactMap({ formatter.number(from: $0)?.doubleValue }),
            typedBinaryAction
        )
            .sample(userIsTyping.skip(1).debug().distinctUntilChanged().filter{ !$0 })
            .subscribe(onNext: {
                core.add(operand: $0.0)
            })


        // Only add an operation when user switchs from
        // selecting an operation to typing a number
        let token = userIsTyping.skip(1).filter({ $0 })
            .withLatestFrom(typedBinaryAction)
            .subscribe(onNext: {
                core.add(operation: $0)
            })

        let binaryToken = typedBinaryAction
            .subscribe(onNext: { operation in
                userIsTyping.accept(false)

                if let result = core.evaluate(with: operation), let number = formatter.string(from: result as NSNumber) {
                    display.accept(number)
                }
        })

        brain = core
        binaryOperationPressed = binaryOperationAction.asObserver()
        numberPressed = numberAction.asObserver()
        displayDriver = display.asDriver()
        canReset = userIsTyping.asObservable()
        disposables = CompositeDisposable(disposables: [numberToDisplay, binaryToken, operationTapped, token])
    }
}
