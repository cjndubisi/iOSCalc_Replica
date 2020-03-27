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
        brain.add(operation: "+")
        brain.add(operand: 4)

        XCTAssertEqual(brain.evaluate(), 7)
    }

    func testCanEvaluateMuliplicationOperation() {
        brain.add(operand: 3)
        brain.add(operation: "×")
        brain.add(operand: 4)

        XCTAssertEqual(brain.evaluate(), 12)
    }

    func testShouldReturnLastOperandForIncompeteMuliplication() {
        brain.add(operand: 3)
        brain.add(operation: "+")
        brain.add(operand: 4)


        XCTAssertEqual(brain.evaluate(with: "×"), 4.0)
    }

    func testCompleteOperationsEndingInAddition() {
        brain.add(operand: 1)
        brain.add(operation: "+")
        brain.add(operand: 3)
        brain.add(operation: "×")
        brain.add(operand: 5)

        XCTAssertEqual(brain.evaluate(with: "+"), 16)
    }

    func testCompleteOperationsEndingInMuliplication() {
        brain.add(operand: 1)
        brain.add(operation: "+")
        brain.add(operand: 3)
        brain.add(operation: "×")
        brain.add(operand: 5)

        XCTAssertEqual(brain.evaluate(with: "×"), 15)
        XCTAssertEqual(brain.evaluate(with: "+"), 16)

    }
}