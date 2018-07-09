//
//  CurrencyRatesService.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation
import FlagKit

protocol ICurrencyRatesService {
    func loadCurrencyRates(baseCurrency: String, completion: @escaping (Result<CurrencyRates>) -> Void)

    func currencyRateName(currencyCode: String) -> String?

    func currencyFlagImage(currencyCode: String) -> UIImage?
}

final class CurrencyRatesService: ICurrencyRatesService {

    // Dependencies
    private let requestManager: IRequestManager

    // MARK: - Initializers

    init(requestManager: IRequestManager) {
        self.requestManager = requestManager
    }

    // MARK: - ICurrencyRatesService

    func loadCurrencyRates(baseCurrency: String, completion: @escaping (Result<CurrencyRates>) -> Void) {
        let request = CurrencyRatesRequest(baseCurrency: baseCurrency)
        requestManager.load(request, completion: completion)
    }

    func currencyRateName(currencyCode: String) -> String? {
        return Helper.currencyName(currencyCode)
    }

    func currencyFlagImage(currencyCode: String) -> UIImage? {
        guard let regionCode = Helper.regionCode(currencyCode),
            let flag = Flag(countryCode: regionCode) else {
                return nil
        }
        return flag.image(style: .circle)
    }

}
