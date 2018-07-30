//
//  RequestManagerMockTests.swift
//  CurrencyConverterTests
//
//  Created by d.sargin on 12/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import XCTest
@testable import CurrencyConverter

class RequestManagerMockTests: XCTestCase {

    func testCurrencyRatesRequestModelParsing() {
        // given
        let requestManager = MockLocator.shared.requestManager(resourceName: .currencyRatesResourceName)
        let request = CurrencyRatesRequest(baseCurrency: "USD")
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
        requestManager.load(request) { (result) in
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
