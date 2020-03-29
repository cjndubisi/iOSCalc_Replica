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
    case none

    var action: (Double, Double) -> Double {
        switch self {
            case Operation.multiply: return  (*)
            case Operation.divide: return  (/)
            case Operation.add: return  (+)
            case Operation.subtract: return  (-)
        case .none: return { _, _ in Double.greatestFiniteMagnitude }
        }
    }

    var precedence: Precedence {
        switch self {
        case Operation.multiply: return  .high
        case Operation.divide: return  .high
        case Operation.add: return  .low
        case Operation.subtract: return  .low
        case .none: return .low
        }
    }
}

enum UnaryOperation: String {
    case negate = "±"
    case percentage = "%"

    var action: (Double) -> Double {
        switch self {
        case .negate: return ({ -$0 })
        case .percentage: return ({ $0/100 })
        }
    }
}

protocol Brain {
    var isEmpty: Bool { get }
    mutating func add(operand: Double)
    mutating func add(operation: Operation)
    func tansform(number: Double, using operator: UnaryOperation) -> Double

    mutating func evaluate() -> Double?
    mutating func evaluate(with operation: Operation) -> Double?
}

extension Brain {
    func tansform(number: Double, using operation: UnaryOperation) -> Double {
        return operation.action(number)
    }
}

struct CalculatorBrain: Brain {

    private var opStack = [Element]()

    var isEmpty: Bool {
        return opStack.isEmpty
    }

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
        guard opStack.first != nil else { return nil }
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
                    // eg 1 + 5 * 3 -> + is less than *
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

fileprivate var formatter: NumberFormatter {
    let formatter = NumberFormatter()

    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 8
    formatter.maximum = NSNumber(integerLiteral:  111111111 * 9)
    formatter.numberStyle = .decimal

    return formatter
}


public struct CalculatorViewModel {

    let displayDriver: Driver<String>
    let selectedOperation: Observable<Operation>
    // observers
    let numberPressed: AnyObserver<String>
    let binaryOperationPressed: AnyObserver<String>
    let UnaryOperationPressed: AnyObserver<String>
    // disposables
    let disposables: CompositeDisposable
    var brain: Brain!

    init() {
        let numberAction = PublishSubject<String>()
        let display = BehaviorRelay<String>(value: "0")
        let binaryOperationAction = PublishSubject<String>()
        let UnaryOperationAction = PublishSubject<String>()
        let selected = PublishSubject<Operation>()

        let userIsTyping = BehaviorRelay<Bool>(value: false)
        var core: Brain = CalculatorBrain()
        let displayRaw = display.map({ $0.replacingOccurrences(of: ",", with: "") })

        // convert to type
        let typedBinaryAction = binaryOperationAction
            .asObservable()
            .compactMap({ Operation(rawValue: $0)})

        let numberToDisplay = numberAction.withLatestFrom(displayRaw) { number, display in
            // user is typing after either return(s)
            defer { userIsTyping.accept(true) }

            let isTyping = userIsTyping.value

            // ignore extra decmial
            if number == "." && display.contains(".") {
                return display
            }

            guard isTyping || number == "." else {
                selected.onNext(.none)
                return formatter.string(from: formatter.number(from: number)!)!
            }

            if number == "." && display == "0" {
                return "0."
            }

            // format
            let fallback = formatter.number(from: display)!
            return formatter.string(from: formatter.number(from: display + number) ?? fallback)!
        }
        .bind(to: display)

        let typedunaryAction = UnaryOperationAction
            .filter({ _ in userIsTyping.value })
            .compactMap({ UnaryOperation(rawValue: $0) })
            .withLatestFrom(displayRaw, resultSelector: { (op: $0, display: $1) })
            .compactMap { result -> Double? in
                let doubleValue = formatter.number(from: result.display)?.doubleValue
                guard let display = doubleValue else { return  nil }
                return result.op.action(display)
        }
        .map({ formatter.string(from: $0 as NSNumber)! })
        .bind(to: display)


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
                guard !core.isEmpty else { return }
                selected.onNext(operation)
                if let result = core.evaluate(with: operation), let number = formatter.string(from: result as NSNumber) {
                    display.accept(number)
                }
        })

        brain = core
        selectedOperation = selected.asObservable()
        binaryOperationPressed = binaryOperationAction.asObserver()
        UnaryOperationPressed = UnaryOperationAction.asObserver()
        numberPressed = numberAction.asObserver()
        displayDriver = display.asDriver()
        disposables = CompositeDisposable(disposables: [numberToDisplay,
                                                        binaryToken,
                                                        operationTapped,
                                                        token,
                                                        typedunaryAction])
    }
}
