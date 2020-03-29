//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Chijioke on 3/29/20.
//  Copyright © 2020 Chijioke. All rights reserved.
//

import Foundation

enum Element {
    case operation(Operation)
    case operand(Double)
}

enum Precedence: Int {
    case high = 10
    case low = 5
}

enum BrainAction: String {
    case clear = "c"
    case reset = "ac"
    case evaluate = "="
}

enum Operation: String {
    case multiply = "×"
    case divide = "÷"
    case add = "+"
    case subtract = "−"
    case none

    var action: (Double, Double) -> Double {
        switch self {
        case .multiply: return  (*)
        case .divide: return  (/)
        case .add: return  (+)
        case .subtract: return  (-)
        case .none: return { _, _ in Double.greatestFiniteMagnitude }
        }
    }

    var precedence: Precedence {
        switch self {
        case .multiply: return  .high
        case .divide: return  .high
        case .add: return  .low
        case .subtract: return  .low
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

    mutating func clear()
    func evaluate() -> Double?
    func evaluate(with operation: Operation) -> Double?
    func tansform(number: Double, using operator: UnaryOperation) -> Double
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

    mutating func clear() {
        opStack = []
    }

    func evaluate() -> Double? {
        let result = evaluate(precedence: .low, stack: opStack)
        return result.result
    }

    func evaluate(with operation: Operation) -> Double? {
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
