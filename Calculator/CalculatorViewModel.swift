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

enum Precedence: Int {
    case high = 10
    case low = 5
}

enum Operation {
    static var operations: [String: (Double, Double) -> Double] = [
        "×": (*),
        "÷": (/),
        "+": (+),
        "-": (-),
    ]

    static var precedence: [String: Precedence] = [
        "×": .high,
        "÷": .high,
        "+": .low,
        "-": .low,
    ]
}
protocol Brain {
    mutating func add(operand: Double)
    mutating func add(operation: String)

    mutating func evaluate() -> Double?
    mutating func evaluate(with operation: String) -> Double?
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
        let result = evaluate(precedence: .low, stack: opStack)
        return result.result
     }

    mutating func evaluate(with operation: String) -> Double? {
        return evaluate(precedence: Operation.precedence[operation]!, stack: opStack).result
    }

    private func evaluate(precedence: Precedence, stack: [Element]) -> (result: Double?, precedence: Precedence, remaining: [Element]) {
        var mutating = stack

        guard let element = mutating.popLast() else {
            return (nil, .low, mutating)
        }

        switch element {
        case .operation:
            return evaluate(precedence: precedence, stack: mutating)
        case let .operand(value):
            if case let .operation(op) = mutating.last {
                let result = evaluate(precedence: precedence, stack: mutating)

                if precedence.rawValue > result.precedence.rawValue {
                    if result.remaining.isEmpty {
                        return (value, result.precedence, [])
                    }
                    return evaluate(precedence: precedence, stack: result.remaining)
                }
                else if let operand2 = result.result {
                    return (Operation.operations[op]!(operand2, value), .low, result.remaining)
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
