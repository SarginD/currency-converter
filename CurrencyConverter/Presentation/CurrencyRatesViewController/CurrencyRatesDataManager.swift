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
    var rates = ThreadSafeValueWrapper([RateInfo]())
    var positionsArray = ThreadSafeValueWrapper([String]())

    // Dependencies
    private let currencyRatesService: ICurrencyRatesService = Locator.shared.currencyRatesService()

    var workItems: [DispatchWorkItem] = []
    var timer: DispatchSourceTimer?
    func startUpdatingDataSource(onUpdate: @escaping (Result<(toUpdate: [IndexPath], toDelete: [IndexPath], toInsert: [IndexPath])>) -> Void) {

        let queue = DispatchQueue(label: "customSerialQueue")
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))

        let workItem = DispatchWorkItem { [weak self] in
            guard let `self` = self else { return }
            self.currencyRatesService.loadCurrencyRates(baseCurrency: self.baseCurrency.value) { [weak self] result in
                guard let `self` = self else { return }
                self.workItems.removeAll()
                switch result {
                case .success(let result):
                    guard self.baseCurrency.value == result.baseCurrencyCode else { return }
                    let baseRateInfo = RateInfo(currencyCode: result.baseCurrencyCode, baseCurrencyCode: result.baseCurrencyCode, rate: 1)
                    let newRateInfos = [baseRateInfo] + result.rates
                    let dataSourceDiff = self.calculateDataSourceDiff(newDataSource: newRateInfos)
                    onUpdate(Result.success(dataSourceDiff))
                case .fail(let error):
                    onUpdate(.fail(error))
                }

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

    func calculateCurrencyCodesDiff(oldRatesCurrencyCodes: [String], newRatesCurrencyCodes: [String]) -> (toUpdate: [String], toDelete: [String], toInsert: [String]) {
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

    func calculateDataSourceDiff(newDataSource: [RateInfo]) -> (toUpdate: [IndexPath], toDelete: [IndexPath], toInsert: [IndexPath]) {
        let diff = self.calculateCurrencyCodesDiff(oldRatesCurrencyCodes: self.rates.value.map { $0.currencyCode }, newRatesCurrencyCodes: newDataSource.map { $0.currencyCode })

        var toUpdateArray = [String]()

        diff.toDelete.forEach { currencyCodeToDelete in
            if let indexToDelete = rates.value.index(where: { $0.currencyCode == currencyCodeToDelete }) {
                rates.mutate {
                    $0.remove(at: indexToDelete)
                }
            }
        }
        diff.toInsert.forEach { currencyCodeToInsert in
            if let indexOfItemToInsert = newDataSource.index(where: { $0.currencyCode == currencyCodeToInsert }) {
                let newItem = newDataSource[indexOfItemToInsert]
                rates.mutate {
                    $0.append(newItem)
                }
            }
        }
        diff.toUpdate.forEach { currencyCodeToUpdate in
            guard currencyCodeToUpdate != self.baseCurrency.value else {
                return
            }
            if let indexOfNewItem = newDataSource.index(where: { $0.currencyCode == currencyCodeToUpdate }),
                let indexOfOldItem = rates.value.index(where: { $0.currencyCode == currencyCodeToUpdate }) {
                let newItem = newDataSource[indexOfNewItem]
                let oldItem = rates.value[indexOfOldItem]
                if oldItem.rate != newItem.rate {
                    rates.mutate {
                        $0.remove(at: indexOfOldItem)
                        $0.insert(newItem, at: indexOfOldItem)
                    }
                    toUpdateArray.append(currencyCodeToUpdate)
                }
            }
        }
        return self.updatePositionsArray(newRatesCurrencyCodes: newDataSource.map { $0.currencyCode }, diff: (toUpdateArray, diff.toDelete, diff.toInsert))
    }

    func updatePositionsArray(newRatesCurrencyCodes: [String], diff: (toUpdate: [String], toDelete: [String], toInsert: [String])) -> (toUpdate: [IndexPath], toDelete: [IndexPath], toInsert: [IndexPath]) {

        var indexesToDelete = [IndexPath]()
        diff.toDelete.forEach {
            if let index = positionsArray.value.index(of: $0) {
                positionsArray.mutate {
                    $0.remove(at: index)
                }
                indexesToDelete.append(IndexPath(row: index, section: 0))
            }
        }

        if newRatesCurrencyCodes.count == diff.toInsert.count {
            positionsArray.mutate {
                $0 = newRatesCurrencyCodes
            }
        } else {
            positionsArray.mutate {
                $0 += diff.toInsert
            }
        }
        var indexesToInsert = [IndexPath]()
        diff.toInsert.forEach {
            if let index = positionsArray.value.index(of: $0) {
                indexesToInsert.append(IndexPath(row: index, section: 0))
            }
        }

        var indexesToUpdate = [IndexPath]()
        diff.toUpdate.forEach {
            if let index = positionsArray.value.index(of: $0), index != 0 {
                indexesToUpdate.append(IndexPath(row: index, section: 0))
            }
        }

        return (indexesToUpdate, indexesToDelete, indexesToInsert)
    }

    deinit {
        stopUpdatingDataSource()
    }

}
