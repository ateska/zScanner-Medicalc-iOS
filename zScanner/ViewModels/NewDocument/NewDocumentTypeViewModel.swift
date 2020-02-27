//
//  NewDocumentTypeViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift

class NewDocumentTypeViewModel {
    
    // MARK: Instance part
    private let database: Database
    let folderName: String
    
    init(database: Database, folderName: String) {
        self.database = database
        self.folderName = folderName
        self.isValid = Observable
            .combineLatest(fields.map({ $0.isValid }))
            .map({ results in results.reduce(true, { $0 && $1 }) })
    }
    
    // MARK: Interface
    private(set) lazy var fields: [FormField] = [
        TextInputField(title: "form.documentDecription.title".localized, validator: { _ in true }),
    ]
    
    private(set) lazy var documentTypes: [FormField] = {
        var documentTypes: [DocumentTypeDomainModel] {
            return database.loadObjects(DocumentTypeDatabaseModel.self)
                .map({ $0.toDomainModel() })
                .sorted(by: { $0.name < $1.name })
        }
        
        var fields: [ListPickerField<DocumentSubTypeDomainModel>] = []
        documentTypes.forEach { (documentType) in
            fields.append(ListPickerField<DocumentSubTypeDomainModel>(title: documentType.name, list: documentType.subtypes))
        }
    
        return fields
    }()
    
    var isValid = Observable<Bool>.just(false)
    
    func addDateTimePickerPlaceholder(at index: Int, for date: DateTimePickerField) {
        fields.insert(DateTimePickerPlaceholder(for: date), at: index)
    }
    
    func removeDateTimePickerPlaceholder() {
        fields.removeAll(where: { $0 is DateTimePickerPlaceholder })
    }
}
