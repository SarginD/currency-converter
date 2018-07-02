//
//  CurrencyRatesRequest.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

final class CurrencyRatesRequest: ModelRequest {

    typealias Model = CurrencyRates

    private let baseCurrency: String

    init(baseCurrency: String) {
        self.baseCurrency = baseCurrency
    }

    func parameters() -> [AnyHashable : Any] {
        return ["base": baseCurrency]
    }

    func domain() -> String {
        return "https://revolut.duckdns.org"
    }

    func service() -> String {
        return "latest"
    }

}
