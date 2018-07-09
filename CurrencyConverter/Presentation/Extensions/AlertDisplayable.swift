//
//  AlertDisplayable.swift
//  CurrencyConverter
//
//  Created by d.sargin on 09/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import UIKit

@objc public protocol AlertDisplayable {

    /// Shows alert with text
    @objc func showAlert(text: String)

    /// Shows alert with title and message
    @objc func showAlert(title: String, message: String)

    /// Shows alert with error
    @objc func showAlert(error: Error)
}

@objc extension UIViewController: AlertDisplayable {

    @objc public func showAlert(text: String) {
        showAlertInternal(title: text, message: nil)
    }

    @objc public func showAlert(title: String, message: String) {
        showAlertInternal(title: title, message: message)
    }

    @objc public func showAlert(error: Error) {
        let text = !error.localizedDescription.isEmpty ? error.localizedDescription : "Error occured"
        showAlertInternal(title: text, message: nil)
    }

    private func showAlertInternal(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
