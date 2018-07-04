//
//  CurrencyRatesDataManager.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

private extension String {
    static let defaultBaseCurrency: String = "USD"
}

final class CurrencyRatesDataManager {

    var baseCurrency = ThreadSafeValueWrapper(String.defaultBaseCurrency)

    // Dependencies
    private let currencyRatesService: ICurrencyRatesService = Locator.shared.currencyRatesService()

    func loadDataSource(completion: @escaping (Result<CurrencyRates>) -> Void) {
        currencyRatesService.loadCurrencyRates(baseCurrency: "USD", completion: completion)
    }
    var workItems: [DispatchWorkItem] = []

    var timer: DispatchSourceTimer?

    func startUpdatingDataSource(onUpdate: @escaping (Result<CurrencyRates>) -> Void) {

        let queue = DispatchQueue(label: "customSerialQueue")

        timer?.cancel()

        timer = DispatchSource.makeTimerSource(queue: queue)

        timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))

        let workItem = DispatchWorkItem { [weak self] in
            guard let `self` = self else { return }
            self.currencyRatesService.loadCurrencyRates(baseCurrency: self.baseCurrency.value) { [weak self] result in
                guard let `self` = self else { return }
                self.workItems.removeAll()
                onUpdate(result)
                print("update")
            }
        }

        timer?.setEventHandler { [weak self] in
            guard let `self` = self else { return }
            if self.workItems.count > 0 { return }
            self.workItems.append(workItem)
            queue.async(execute: workItem)
        }

        timer?.resume()
    }

    func calculateDiff(oldRatesCurrencyCodes: [String], newRatesCurrencyCodes: [String]) -> (toUpdate: [String], toDelete: [String], toInsert: [String]) {
        let oldSet = Set(oldRatesCurrencyCodes)
        let newSet = Set(newRatesCurrencyCodes)
        let toUpdateSet = oldSet.intersection(newSet)
        let toDeleteSet = oldSet.subtracting(newSet)
        let toInsertSet = newSet.subtracting(oldSet)
        return (toUpdate: Array(toUpdateSet), toDelete: Array(toDeleteSet), toInsert: Array(toInsertSet))
    }

    private func stopUpdatingDataSource() {
        timer?.cancel()
        timer = nil
    }

    deinit {
        stopUpdatingDataSource()
    }

}
