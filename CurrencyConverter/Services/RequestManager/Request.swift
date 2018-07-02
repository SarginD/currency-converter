//
//  Request.swift
//  CurrencyConverter
//
//  Created by d.sargin on 01/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

protocol IRequest {

    func parameters() -> [AnyHashable: Any]

    func domain() -> String

    func service() -> String

    func timeoutInterval() -> TimeInterval
}

protocol ModelRequest: IRequest {

    associatedtype Model: JSONParsable
}

extension IRequest {

    func timeoutInterval() -> TimeInterval {
        return 60
    }
}
