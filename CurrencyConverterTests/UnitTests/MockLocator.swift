//
//  MockLocator.swift
//  CurrencyConverterTests
//
//  Created by d.sargin on 12/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation
@testable import CurrencyConverter

internal extension String {
    static let currencyRatesResourceName = "CurrencyRates"
}

struct MockLocator {

    static let shared = MockLocator()

    func requestManager(resourceName: String) -> IRequestManager {
        let requestManager = RequestManagerMock()
        requestManager.resourceName = resourceName
        return requestManager
    }

    func currencyRatesService(resourceName: String) -> ICurrencyRatesService {
        return CurrencyRatesService(requestManager: MockLocator.shared.requestManager(resourceName: resourceName))
    }
}
