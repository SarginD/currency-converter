//
//  ConfigurableView.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

protocol ConfigurableView {
    associatedtype ConfigurationModel

    func configure(with model: ConfigurationModel)
}
