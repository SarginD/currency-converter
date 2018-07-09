//
//  CurrencyCodesHelper.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

class Helper {
    static let eurCode = "EUR"

    static let defaultLocaleTable: [String : String] = [
        "AUD" : "en_AU",
        "BGN" : "bg_BG",
        "BRL" : "pt_BR",
        "CAD" : "en_CA",
        "CHF" : "gsw_CH",
        "CNY" : "zh_Hans_CN",
        "CZK" : "cs_CZ",
        "DKK" : "da_DK",
        "GBP" : "en_GB",
        "HKD" : "zh_Hans_HK",
        "HRK" : "hr_HR",
        "HUF" : "hu_HU",
        "IDR" : "id_ID",
        "ILS" : "he_IL",
        "INR" : "hi_IN",
        "JPY" : "ja_JP",
        "KRW" : "ko_KR",
        "MXN" : "es_MX",
        "MYR" : "ms_MY",
        "NOK" : "nb_NO",
        "NZD" : "en_NZ",
        "PHP" : "fil_PH",
        "PLN" : "pl_PL",
        "RON" : "ro_RO",
        "RUB" : "ru_RU",
        "SEK" : "sv_SE",
        "SGD" : "en_SG",
        "THB" : "th_TH",
        "TRY" : "tr_TR",
        "USD" : "en_US",
        "ZAR" : "en_ZA"
    ]

    static let localeTable: [String : String] = buildLocaleTable()
}

extension Helper {
    static func buildLocaleTable() -> [String: String] {
        var table: [String : String] = defaultLocaleTable

        for code in Locale.availableIdentifiers {
            let locale = Locale(identifier: code)
            guard let currencyCode = locale.currencyCode else { continue }
            if table[currencyCode] == nil {
                table[currencyCode] = code
            }
        }

        return table
    }

    static func locale(_ currencyCode: String) -> Locale? {
        if currencyCode == eurCode { return nil }
        guard let identifier = localeTable[currencyCode] else { return nil }
        return Locale(identifier: identifier)
    }

    static func regionCode(_ currencyCode: String) -> String? {
        if currencyCode == eurCode { return "EU" }
        return locale(currencyCode)?.regionCode ?? nil
    }

    static func countryName(_ currencyCode: String) -> String {
        if currencyCode == eurCode { return "EU" }
        guard let regionCode = locale(currencyCode)?.regionCode else { return "" }
        return Locale.current.localizedString(forRegionCode: regionCode) ?? ""
    }

    static func currencySymbol(_ currencyCode: String) -> String {
        if currencyCode == eurCode { return "€" }
        return locale(currencyCode)?.currencySymbol ?? ""
    }

    static func currencyName(_ currencyCode: String) -> String {
        return Locale.current.localizedString(forCurrencyCode: currencyCode) ?? ""
    }
}
