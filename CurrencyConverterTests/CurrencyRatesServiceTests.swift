//
//  CurrencyRatesServiceTests.swift
//  CurrencyConverterTests
//
//  Created by d.sargin on 12/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import XCTest
@testable import CurrencyConverter

class CurrencyRatesServiceTests: XCTestCase {

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
        wait(for: [expectation], timeout: 4)
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
        wait(for: [expectation], timeout: 4)
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
        wait(for: [expectation], timeout: 4)
    }

    func testCurrencyRatesServiceMockRequestExecution() {
        // given
        let currencyRatesService = MockLocator.shared.currencyRatesService(resourceName: .currencyRatesResourceName)
        let baseCurrency = "USD"
        let ratesArray = [
            "AUD": 1.3542,
            "BGN": 1.669,
            "BRL": 3.8337,
            "CAD": 1.316,
            "CHF": 0.99447,
            "CNY": 6.6871,
            "CZK": 22.128,
            "DKK": 6.3613,
            "GBP": 0.7551,
            "HKD": 7.8607,
            "HRK": 6.3118,
            "HUF": 277.06,
            "IDR": 14386,
            "ILS": 3.6409,
            "INR": 68.873,
            "ISK": 107.01,
            "JPY": 111.39,
            "KRW": 1125.4,
            "MXN": 19.084,
            "MYR": 4.0429,
            "NOK": 8.061,
            "NZD": 1.4735,
            "PHP": 53.672,
            "PLN": 3.6879,
            "RON": 3.977,
            "RUB": 62.086,
            "SEK": 8.7678,
            "SGD": 1.3627,
            "THB": 33.318,
            "TRY": 4.7878,
            "ZAR": 13.502,
            "EUR": 0.8534
        ]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: "2018-07-12")
        let expectation = XCTestExpectation(description: "Model parsed")

        // when
        currencyRatesService.loadCurrencyRates(baseCurrency: baseCurrency) { result in
            // then
            switch result {
            case .success(let currencyRates):
                XCTAssertFalse(currencyRates.rates.isEmpty)
                XCTAssertTrue(currencyRates.baseCurrencyCode == "USD")
                XCTAssertTrue(currencyRates.date == date)
                ratesArray.forEach { element in
                    guard let index = currencyRates.rates.index(where: { $0.currencyCode == element.key }) else {
                        XCTFail()
                        return
                    }
                    let rateInfo = currencyRates.rates[index]
                    XCTAssertTrue(rateInfo.baseCurrencyCode == "USD")
                    XCTAssertTrue(rateInfo.currencyCode == element.key)
                    XCTAssertTrue(rateInfo.rate == element.value)
                }
            case .fail:
                XCTFail()
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

}
