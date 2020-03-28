//
//  CalculatorBrainTest.swift
//  CalculatorTests
//
//  Created by Chijioke on 3/27/20.
//  Copyright © 2020 Chijioke. All rights reserved.
//

import XCTest
@testable import Calculator

class CalculatorBrainTest: XCTestCase {

    var brain: Brain!

    override func setUp() {
        brain = CalculatorBrain()
    }

    override func tearDown() {
        brain = nil
    }

    func testCanEvaluateSimpleAddOperation() {
        brain.add(operand: 3)
        brain.add(operation: .add)
        brain.add(operand: 4)

        XCTAssertEqual(brain.evaluate(), 7)
    }

    func testCanEvaluateMuliplicationOperation() {
        brain.add(operand: 3)
        brain.add(operation: .multiply)
        brain.add(operand: 4)

        XCTAssertEqual(brain.evaluate(), 12)
    }

    func testShouldReturnLastOperandForIncompeteMuliplication() {
        brain.add(operand: 3)
        brain.add(operation: .add)
        brain.add(operand: 4)


        XCTAssertEqual(brain.evaluate(with: .multiply), 4.0)
    }

    func testCompleteOperationsEndingInAddition() {
        brain.add(operand: 1)
        brain.add(operation: .add)
        brain.add(operand: 3)
        brain.add(operation: .multiply)
        brain.add(operand: 5)

        XCTAssertEqual(brain.evaluate(with: .add), 16)
    }

    func testCompleteOperationsEndingInMuliplication() {
        brain.add(operand: 1)
        brain.add(operation: .add)
        brain.add(operand: 3)
        brain.add(operation: .multiply)
        brain.add(operand: 5)

        XCTAssertEqual(brain.evaluate(with: .multiply), 15)
        XCTAssertEqual(brain.evaluate(with: .add), 16)

    }

    func testDivisionOperationsEndingInAddition() {
        brain.add(operand: 15)
        brain.add(operation: .divide)
        brain.add(operand: 2)
        brain.add(operation: .divide)
        brain.add(operand: 2)

        XCTAssertEqual(brain.evaluate(with: .divide), 3.75)
        XCTAssertEqual(brain.evaluate(with: .add), 3.75)
    }
}
