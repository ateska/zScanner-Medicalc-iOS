//
//  DocumentTypesRequest.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct DocumentTypesRequest: Request {
    typealias DataType = TypeNetworkModel
    
    var endpoint: Endpoint = MedicalcEndpoint.documentTypes
    var method: HTTPMethod = .get
    var parameters: Parameters? = nil
    var headers: HTTPHeaders = [:]
    
    init() {}
}
