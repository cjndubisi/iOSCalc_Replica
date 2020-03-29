//
//  CalculatorViewModel.swift
//  Calculator
//
//  Created by Chijioke on 3/26/20.
//  Copyright © 2020 Chijioke. All rights reserved.
//

import RxSwift
import RxCocoa

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
    let clearTextDriver: Driver<String>
    let selectedOperation: Observable<Operation>

    // private state
    private let displayRelay: BehaviorRelay<String>
    private let isTyping: BehaviorRelay<Bool>

    // observers
    let numberPressed: AnyObserver<String>
    let binaryOperationPressed: AnyObserver<String>
    let UnaryOperationPressed: AnyObserver<String>
    let clearAction: AnyObserver<BrainAction>
    let equalAction: AnyObserver<BrainAction>

    // disposables
    let disposables: CompositeDisposable
    let brain: Brain!

    init() {
        let numberAction = PublishSubject<String>()
        let display = BehaviorRelay<String>(value: "0")
        let brainAction = PublishSubject<BrainAction>()
        let binaryOperationAction = PublishSubject<String>()
        let UnaryOperationAction = PublishSubject<String>()
        let selected = BehaviorRelay<Operation>(value: .none)

        let userIsTyping = BehaviorRelay<Bool>(value: false)
        var core: Brain = CalculatorBrain()
        let displayRaw = display.map({ $0.replacingOccurrences(of: ",", with: "") })


        // clear
        let clearTapped = brainAction.filter({ $0 != .evaluate })
            .scan(BrainAction.reset) { (last, next) in
                switch (last, next) {
                case (.reset, .clear):
                    display.accept("0")
                    return .clear
                default:
                    display.accept("0")
                    selected.accept(.none)
                    core.clear()
                }
                userIsTyping.accept(false)
                return .reset
        }

        clearTextDriver = Observable.combineLatest(userIsTyping,
                                                   clearTapped.startWith(.reset))
            .map { (typing, state) in
                if state == .clear || !typing && core.isEmpty { return "AC" }

                if typing || !core.isEmpty { return "C" }

                return "C"
        }.asDriver(onErrorJustReturn: "AC")
        // End: Clear

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
                selected.accept(.none)
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

        let operandTapped = Observable.combineLatest(
            display.compactMap({ formatter.number(from: $0)?.doubleValue }),
            typedBinaryAction
        )

        let addOperandToken = operandTapped
            .sample(userIsTyping.skip(1).debug().distinctUntilChanged().filter{ !$0 })
            .map { $0.0 }
            .subscribe(onNext: {
                core.add(operand: $0)
            })


        // Only add an operation when user switchs from
        // selecting an operation to typing a number
        let token = userIsTyping.skip(1).filter({ $0 })
            .withLatestFrom(typedBinaryAction)
            .subscribe(onNext: {
                core.add(operation: $0)
            })

        // Equals
        let equalsTappedToken = brainAction.filter({ $0 == .evaluate })
            .withLatestFrom(operandTapped)
            .subscribe(onNext: {
                if userIsTyping.value {
                    core.add(operand: $0.0)
                    core.add(operation: $0.1)
                } else {
                    core.add(operation: $0.1)
                    core.add(operand: $0.0)
                    selected.accept(.none)
                }

                if let result = core.evaluate(), let number = formatter.string(from: result as NSNumber) {
                    display.accept(number)
                }
            })
        // End Equals

        let binaryToken = typedBinaryAction
            .subscribe(onNext: { operation in
                userIsTyping.accept(false)
                selected.accept(operation)
                if let result = core.evaluate(with: operation), let number = formatter.string(from: result as NSNumber) {
                    display.accept(number)
                }
        })

        brain = core
        isTyping = userIsTyping
        clearAction = brainAction.asObserver()
        equalAction = brainAction.asObserver()
        selectedOperation = selected.asObservable()
        binaryOperationPressed = binaryOperationAction.asObserver()
        UnaryOperationPressed = UnaryOperationAction.asObserver()
        numberPressed = numberAction.asObserver()
        displayRelay = display
        displayDriver = display.asDriver()
        disposables = CompositeDisposable(disposables: [numberToDisplay,
                                                        binaryToken,
                                                        addOperandToken,
                                                        token,
                                                        equalsTappedToken,
                                                        typedunaryAction])
    }

    func delete() {
        let display = displayRelay.value
        guard isTyping.value else { return }

        var number = formatter.number(from: String(display.dropLast()).replacingOccurrences(of: ",", with: ""))
        if number == nil {
            number = NSNumber(value: 0)
        }
        displayRelay.accept(formatter.string(from: number!)!)
    }
}
