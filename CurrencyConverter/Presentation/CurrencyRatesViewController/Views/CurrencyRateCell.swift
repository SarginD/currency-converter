//
//  CurrencyRateCell.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import UIKit

protocol CurrencyRateCellDelegate: class {
    func currencyRateCellDidBeginEditing(_ currencyRateCell: CurrencyRateCell)
    func currencyRateCellDidChange(_ currencyRateCell: CurrencyRateCell)
}

private extension CGFloat {
    static let minLineWidth = 1 / UIScreen.main.scale
}

final class CurrencyRateCell: UITableViewCell, ConfigurableView, UITextFieldDelegate {

    weak var delegate: CurrencyRateCellDelegate?
    private lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.allowsFloats = true
        numberFormatter.decimalSeparator = ","
        numberFormatter.alwaysShowsDecimalSeparator = false
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumIntegerDigits = 1
        return numberFormatter
    }()

    // UI
    @IBOutlet weak var currencyCodeLabel: UILabel!
    @IBOutlet weak var currencyNameLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var flagImageView: UIImageView!
    private lazy var bottomView: UIView = {
        let bottomView = UIView()
        addSubview(bottomView)
        bottomView.snp.makeConstraints {
            $0.bottom.left.right.equalTo(amountTextField)
            $0.height.equalTo(CGFloat.minLineWidth)
        }
        return bottomView
    }()

    // Model
    struct ViewModel {
        let currencyCode: String
        let currencyName: String?
        let currencyFlag: UIImage?
        var amount: Double?
    }

    var model: ViewModel?

    // MARK: - View Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        amountTextField.keyboardType = .decimalPad
        amountTextField.delegate = self
        amountTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        selectionStyle = .none
        bottomView.backgroundColor = .lightGray
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.currencyCodeLabel.text = nil
        self.currencyNameLabel.text = nil
        self.amountTextField.text = nil
        self.flagImageView.image = nil
    }

    // MARK: - ConfigurableView

    typealias ConfigurationModel = ViewModel

    func configure(with model: ViewModel) {
        self.model = model
        currencyCodeLabel.text = model.currencyCode

        currencyNameLabel.isHidden = model.currencyName == nil
        currencyNameLabel.text = model.currencyName

        flagImageView.isHidden = model.currencyFlag == nil
        flagImageView.image = model.currencyFlag

        if let amount = model.amount {
            amountTextField.text = numberFormatter.string(from: NSNumber(floatLiteral: amount))
        } else {
            amountTextField.text = nil
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.currencyRateCellDidBeginEditing(self)
        animateBottomView(isActive: true)
    }

    @objc func textFieldDidChange(textField: UITextField) {
        guard var amountText = textField.text else {
            model?.amount = nil
            return
        }
        amountText = amountText.replacingOccurrences(of: ".", with: ",")
        let amountValue = numberFormatter.number(from: amountText)?.doubleValue
        guard model?.amount != amountValue else { return }
        model?.amount = amountValue
        delegate?.currencyRateCellDidChange(self)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let nsString = textField.text as NSString?
        guard let resultString = nsString?.replacingCharacters(in: range, with: string) else { return true }
        guard !resultString.isEmpty else { return true }
        let amountText = resultString.replacingOccurrences(of: ".", with: ",")
        return numberFormatter.number(from: amountText)?.doubleValue != nil
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        animateBottomView(isActive: false)
    }

    // MARK: - Private API

    private func animateBottomView(isActive: Bool) {
        let height: CGFloat = isActive ? 2 : .minLineWidth
        let color: UIColor = isActive ? tintColor : .lightGray

        UIView.animate(withDuration: 0.2) {
            self.bottomView.backgroundColor = color
            self.bottomView.snp.updateConstraints {
                $0.height.equalTo(height)
            }
            self.layoutIfNeeded()
        }
    }

}
