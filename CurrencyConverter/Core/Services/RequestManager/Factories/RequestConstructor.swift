//
//  RequestConstructor.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

protocol IRequestConstructor {

    func constructURLRequest(from requestModel: IRequest) -> URLRequest?
}

final class RequestConstructor: IRequestConstructor {

    func constructURLRequest(from requestModel: IRequest) -> URLRequest? {
        guard let url = url(for: requestModel) else { return nil}

        let urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: requestModel.timeoutInterval())
        return urlRequest
    }

    private func url(for request: IRequest) -> URL? {
        var urlString = "\(request.domain())/\(request.service())"

        let queryString = request.parameters().map { "\($0)=\($1)" }.joined(separator: "&")

        if !queryString.isEmpty {
            urlString = urlString + "?" + queryString
        }

        return URL(string: urlString)
    }
}
