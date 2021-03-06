//
//  CalculatorViewModelTest.swift
//  CalculatorTests
//
//  Created by Chijioke on 3/26/20.
//  Copyright © 2020 Chijioke. All rights reserved.
//

import XCTest
import RxTest
import RxSwift
@testable import Calculator

class CalculatorViewModelTests: XCTestCase {

    var viewModel: CalculatorViewModel!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        self.scheduler = TestScheduler(initialClock: 0)
        self.disposeBag = DisposeBag()

        viewModel = CalculatorViewModel()
    }

    override func tearDown() {
        viewModel = nil
    }

    func testKeypadDrivesDisplay() {
        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createHotObservable([.next(1, "1"), .next(2, "0")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events, [.next(0, "0"), .next(1, "1"), .next(2, "10")])
    }


    func testAddititionPasses() {
        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "1"), .next(3, "1")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, Operation.add.rawValue), .next(4, Operation.add.rawValue)])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events, [.next(0, "0"), .next(1, "1"), .next(2, "1"), .next(3, "1"), .next(4, "2")])
    }

    func testSubstractionPasses() {
        // 3 - 2 +
        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "3"), .next(3, "2")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, Operation.subtract.rawValue), .next(4, Operation.add.rawValue)])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events, [.next(0, "0"), .next(1, "3"), .next(2, "3"), .next(3, "2"), .next(4, "1")])
    }

    func testMultiplicationPasses() {
        // 3 * 2 +
        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "3"),
                                        .next(3, "2")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, Operation.multiply.rawValue),
                                        .next(4, Operation.add.rawValue)])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events, [.next(0, "0"), .next(1, "3"),
                                        .next(2, "3"), .next(3, "2"),
                                        .next(4, "6")])
    }

    func testCanComputeMultipleAddAndSubOperation() {
        // 3 - 2 + 4 -

        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "3"), .next(3, "2"), .next(5, "4")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, Operation.subtract.rawValue),
                                        .next(4, Operation.add.rawValue),
                                        .next(6, Operation.subtract.rawValue)])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events, [.next(0, "0"), .next(1, "3"), .next(2, "3"), .next(3, "2"), .next(4, "1"), .next(5, "4"), .next(6, "5")])
    }

    func testComputeMulitplicaitonOperationFirst() {
           // 3 x 2 + 4

        let display = scheduler.createObserver(String.self)
        
        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "3"), .next(3, "2")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)
        
        scheduler.createColdObservable([.next(2, Operation.subtract.rawValue),
                                        .next(4, Operation.multiply.rawValue)])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)
        
        scheduler.start()

        XCTAssertEqual(display.events, [.next(0, "0"), .next(1, "3"),
                                        .next(2, "3"), .next(3, "2"),
                                        .next(4, "2")])
       }

    func testReEvaluatesWhenChangingOperand() {
        // 1 + 3 * 5 * -> 15; + -> 16

        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "1"), .next(3, "3"), .next(5, "5")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, Operation.add.rawValue),
                                        .next(4, Operation.multiply.rawValue),
                                        .next(6, Operation.add.rawValue),
                                        .next(8, Operation.multiply.rawValue)])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events[(display.events.count-2)...], [.next(6, "16"), .next(8, "15")])
    }

    func testSelectedOperation() {
        let selectedObserver = scheduler.createObserver(String.self)

        viewModel.numberPressed.onNext("3")

        let record: [Recorded<Event<String>>] = [.next(2, Operation.add.rawValue),
                                       .next(4, Operation.multiply.rawValue),
                                       .next(6, Operation.add.rawValue),
                                       .next(8, Operation.multiply.rawValue)]

        scheduler.createColdObservable(record)
            .bind(to: selectedObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(selectedObserver.events, record)
    }

    func testDecimalOccurance() {
        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "."), .next(3, "2")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events[1...], [.next(1, "0."), .next(3, "0.2")])
    }

    func testIgnoresExtraDecimal() {
        let display = scheduler.createObserver(String.self)
        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "."), .next(3, "2"), .next(4, ".")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events[1...], [.next(1, "0."), .next(3, "0.2"), .next(4, "0.2")])
    }

    func testClearChangesToACWhenDispalyHasDigitAndOperatorIsSelected() {

       let display = scheduler.createObserver(String.self)
        let reseter = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)
        viewModel.clearTextDriver.drive(reseter).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "123")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, Operation.add.rawValue)])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(3, .clear)])
        .bind(to: viewModel.clearAction)
        .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(reseter.events, [.next(0, "AC"), .next(1, "C"), .next(2, "C"), .next(3, "AC")])
        XCTAssertEqual(display.events.last, .next(3, "0"))
    }

    func testEqualsOperator() {

        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "2"), .next(3, "6")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, Operation.subtract.rawValue)])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(4, .evaluate)])
            .bind(to: viewModel.equalAction)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events.last, .next(4, "-4"))
    }

    func testEqualsWithOneOperandAndOneOperator() {

        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "7")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, Operation.multiply.rawValue)])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(3, .evaluate)])
            .bind(to: viewModel.equalAction)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events.last, .next(3, "49"))
    }
}
