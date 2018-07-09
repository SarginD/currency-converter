//
//  CurrencyRates.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import SwiftyJSON

struct CurrencyRates {
    var baseCurrencyCode: String
    let date: Date
    let rates: [RateInfo]
}

extension CurrencyRates: JSONParsable {

    static func from(_ json: JSON) -> CurrencyRates? {
        guard let ratesDictionary = json["rates"].dictionaryObject as? [String: Double] else {
            return nil
        }

        let baseCurrencyCode = json["base"].stringValue
        let rates = ratesDictionary.map {
            RateInfo(currencyCode: $0.key,
                baseCurrencyCode: baseCurrencyCode,
                rate: $0.value)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        let dateString = json["date"].stringValue
        guard let date = dateFormatter.date(from: dateString) else {
            return nil
        }

        return CurrencyRates(baseCurrencyCode: baseCurrencyCode,
                             date: date,
                             rates: rates)
    }
}
