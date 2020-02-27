//
//  DcumentTypeDatabaseModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class DocumentTypeDatabaseModel: Object {
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    let subtypes = List<DocumentSubTypeDatabaseModel>()
    
    convenience init(documentType: DocumentTypeDomainModel) {
        self.init()
        
        self.id = documentType.id
        self.name = documentType.name
        
        self.subtypes.append(objectsIn: documentType.subtypes.map({ DocumentSubTypeDatabaseModel(documentSubType: $0) }))
    }
    
    override class func primaryKey() -> String {
        return "id"
    }
}

//MARK: -
extension DocumentTypeDatabaseModel {
    func toDomainModel() -> DocumentTypeDomainModel {
        return DocumentTypeDomainModel(
            id: id,
            name: name,
            subtypes: subtypes.map({ $0.toDomainModel() })
        )
    }
}
