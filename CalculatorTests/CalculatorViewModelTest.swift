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

        scheduler.createColdObservable([.next(2, "+"), .next(4, "+")])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events, [.next(0, "0"), .next(1, "1"), .next(3, "1"), .next(4, "2")])
    }

    func testSubstractionPasses() {
        // 3 - 2 +
        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "3"), .next(3, "2")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, "-"), .next(4, "+")])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events, [.next(0, "0"), .next(1, "3"), .next(3, "2"), .next(4, "1")])
    }

    func testCanComputeMultipleAddAndSubOperation() {
        // 3 - 2 + 4 -

        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "3"), .next(3, "2"), .next(5, "4")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, "-"), .next(4, "+"), .next(6, "-")])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events, [.next(0, "0"), .next(1, "3"), .next(3, "2"), .next(4, "1"), .next(5, "4"), .next(6, "5")])
    }

    func testEqualsOperationComputesStack() {
        // 3 - 2 + 4 -

        let display = scheduler.createObserver(String.self)

        viewModel.displayDriver.drive(display).disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, "3"), .next(3, "2"), .next(6, "4")])
            .bind(to: viewModel.numberPressed)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(2, "-"), .next(4, "="), .next(5, "+"), .next(7, "-")])
            .bind(to: viewModel.binaryOperationPressed)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(display.events[(display.events.count-3)...], [.next(4, "1"), .next(6, "4"), .next(7, "5")])
    }
}
