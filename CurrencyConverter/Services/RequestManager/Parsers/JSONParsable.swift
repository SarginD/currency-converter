//
//  JSONParsable.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import SwiftyJSON

protocol JSONParsable {

    static func from(_ json: JSON) -> Self?
}
