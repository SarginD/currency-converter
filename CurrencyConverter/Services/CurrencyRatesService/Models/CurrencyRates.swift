//
//  CurrencyRates.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import SwiftyJSON

struct CurrencyRates {

    let baseCurrency: String
    let date: Date
    let rates: [String: Double]
}

extension CurrencyRates: JSONParsable {

    static func from(_ json: JSON) -> CurrencyRates? {
        guard let ratesDictionary = json["rates"].dictionaryObject as? [String: Double] else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        let dateString = json["date"].stringValue
        guard let date = dateFormatter.date(from: dateString) else {
            return nil
        }

        return CurrencyRates(baseCurrency: json["base"].stringValue,
                             date: date,
                             rates: ratesDictionary)
    }
}
