//
//  Result.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case fail(Error)
}
