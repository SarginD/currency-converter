//
//  CurrencyRatesServiceTests.swift
//  CurrencyConverterTests
//
//  Created by d.sargin on 12/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import XCTest
@testable import CurrencyConverter

private extension TimeInterval {
    static let timeout: TimeInterval = 4
}

class CurrencyRatesServiceIntegrationTests: XCTestCase {

    func testCurrencyRatesServiceRequestExecution() {
        // given
        let currencyRatesService = Locator.shared.currencyRatesService()
        let baseCurrency = "USD"
        let expectation = XCTestExpectation(description: "Request loaded")

        // when
        currencyRatesService.loadCurrencyRates(baseCurrency: baseCurrency) { result in
            // then
            switch result {
            case .success(let currencyRates):
                XCTAssertNotNil(currencyRates)
                XCTAssertFalse(currencyRates.rates.isEmpty)
                XCTAssertFalse(currencyRates.baseCurrencyCode.isEmpty)
            case .fail:
                XCTFail()
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: .timeout)
    }

    func testCurrencyRatesServiceImagesGathering() {
        // given
        let currencyRatesService = Locator.shared.currencyRatesService()
        let baseCurrency = "USD"
        let expectation = XCTestExpectation(description: "Images loaded")

        // when
        currencyRatesService.loadCurrencyRates(baseCurrency: baseCurrency) { result in
            // then
            switch result {
            case .success(let currencyRates):
                XCTAssertFalse(currencyRates.rates.isEmpty)
                let allCurrencies = currencyRates.rates.map { $0.currencyCode } + [baseCurrency]
                allCurrencies.forEach {
                    XCTAssertNotNil(currencyRatesService.currencyFlagImage(currencyCode: $0))
                }
            case .fail:
                XCTFail()
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: .timeout)
    }

    func testCurrencyRatesServiceCurrencyNamesGathering() {
        // given
        let currencyRatesService = Locator.shared.currencyRatesService()
        let baseCurrency = "USD"
        let expectation = XCTestExpectation(description: "Currency names loaded")

        // when
        currencyRatesService.loadCurrencyRates(baseCurrency: baseCurrency) { result in
            // then
            switch result {
            case .success(let currencyRates):
                XCTAssertFalse(currencyRates.rates.isEmpty)
                let allCurrencies = currencyRates.rates.map { $0.currencyCode } + [baseCurrency]
                allCurrencies.forEach {
                    guard let currencyName = currencyRatesService.currencyRateName(currencyCode: $0) else {
                        XCTFail()
                        return
                    }
                    XCTAssertFalse(currencyName.isEmpty)
                }
            case .fail:
                XCTFail()
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: .timeout)
    }

    

}
