//
//  Rate.swift
//  CurrencyConverter
//
//  Created by d.sargin on 04/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import SwiftyJSON

struct RateInfo {
    let currencyCode: String
    var baseCurrencyCode: String
    var rate: Double
}
