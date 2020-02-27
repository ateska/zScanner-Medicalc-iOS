//
//  DocumentSubTypeDatabaseModel.swift
//  zScanner
//
//  Created by Jan Provazník on 27/02/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class DocumentSubTypeDatabaseModel: Object {
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    
    convenience init(documentSubType: DocumentSubTypeDomainModel) {
        self.init()
           
        self.id = documentSubType.id
        self.name = documentSubType.name
    }
}

extension DocumentSubTypeDatabaseModel {
    func toDomainModel() -> DocumentSubTypeDomainModel {
        return DocumentSubTypeDomainModel(
            id: id,
            name: name
        )
    }
}
