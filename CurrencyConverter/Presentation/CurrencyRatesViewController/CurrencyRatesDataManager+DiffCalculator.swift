//
//  CurrencyRatesDataManager+DiffCalculator.swift
//  CurrencyConverter
//
//  Created by Daniil Sargin on 10/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

typealias CurrencyCodesDiff = (toUpdate: [String], toDelete: [String], toInsert: [String])
typealias IndexPathsDiff = (toUpdate: [IndexPath], toDelete: [IndexPath], toInsert: [IndexPath])

extension CurrencyRatesDataManager {

    func calculateCurrencyCodesDiff(oldRatesCurrencyCodes: [String], newRatesCurrencyCodes: [String]) -> CurrencyCodesDiff {
        let oldSet = Set(oldRatesCurrencyCodes)
        let newSet = Set(newRatesCurrencyCodes)
        let toUpdateSet = oldSet.intersection(newSet)
        let toDeleteSet = oldSet.subtracting(newSet)
        let toInsertSet = newSet.subtracting(oldSet)
        return (toUpdate: Array(toUpdateSet), toDelete: Array(toDeleteSet), toInsert: Array(toInsertSet))
    }

    func updateDataSource(newDataSource: [RateInfo]) -> IndexPathsDiff {
        let diff = self.calculateCurrencyCodesDiff(oldRatesCurrencyCodes: self.rates.value.map { $0.currencyCode },
                                                   newRatesCurrencyCodes: newDataSource.map { $0.currencyCode })

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
        return self.updatePositionsArray(newRatesCurrencyCodes: newDataSource.map { $0.currencyCode },
                                         currencyCodesDiff: (toUpdateArray, diff.toDelete, diff.toInsert))
    }

    func updatePositionsArray(newRatesCurrencyCodes: [String], currencyCodesDiff: CurrencyCodesDiff) -> IndexPathsDiff {

        var indexesToDelete = [IndexPath]()
        currencyCodesDiff.toDelete.forEach {
            if let index = positionsArray.value.index(of: $0) {
                positionsArray.mutate {
                    $0.remove(at: index)
                }
                indexesToDelete.append(IndexPath(row: index, section: 0))
            }
        }

        if newRatesCurrencyCodes.count == currencyCodesDiff.toInsert.count {
            positionsArray.mutate {
                $0 = newRatesCurrencyCodes
            }
        } else {
            positionsArray.mutate {
                $0 += currencyCodesDiff.toInsert
            }
        }
        var indexesToInsert = [IndexPath]()
        currencyCodesDiff.toInsert.forEach {
            if let index = positionsArray.value.index(of: $0) {
                indexesToInsert.append(IndexPath(row: index, section: 0))
            }
        }

        var indexesToUpdate = [IndexPath]()
        currencyCodesDiff.toUpdate.forEach {
            if let index = positionsArray.value.index(of: $0), index != 0 {
                indexesToUpdate.append(IndexPath(row: index, section: 0))
            }
        }

        return (indexesToUpdate, indexesToDelete, indexesToInsert)
    }
}
