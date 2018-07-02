//
//  Parser.swift
//  CurrencyConverter
//
//  Created by d.sargin on 01/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

protocol IResultParser {
    func parseResponse(_ response: Any) -> Any?
}
