//
//  Event.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

enum Event {
    case login
    case logout
    
    case userFoundBy(SearchMode)
    case userNotFound
    
    case deleteImage
    case galleryUsed(Bool)
    
    case numberOfDocumentsBeforeDelete(Int)
    case createDocumentAgain
}
