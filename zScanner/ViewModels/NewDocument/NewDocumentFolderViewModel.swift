//
//  NewDocumentFolderViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 10/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class NewDocumentFolderViewModel {
    
    // MARK: Instance part
    private let database: Database
    private let networkManager: NetworkManager
    private let tracker: Tracker
    
    init(database: Database, networkManager: NetworkManager, tracker: Tracker) {
        self.database = database
        self.networkManager = networkManager
        self.tracker = tracker
        
        history = database
            .loadObjects(FolderDatabaseModel.self)
            .sorted(by: { $0.lastUsed > $1.lastUsed })
            .prefix(Config.folderUsageHistoryCount)
            .map({ $0.toDomainModel() })
    }
    
    // MARK: Interface
    let history: [FolderDomainModel]
    let searchResults = BehaviorRelay<[FolderDomainModel]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    var lastUsedSearchMode: SearchMode = .history
    
    func search(query: String) {
        lastUsedSearchMode = .search
        activeSearch = networkManager.searchFolders(with: query)
    }
    
    func getFolder(with id: String) {
        lastUsedSearchMode = .scan
        let id = id.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
        activeSearch = networkManager.getFolder(with: id).map({ (result) -> RequestStatus<[FolderNetworkModel]> in
            switch result {
                case .progress(let percentage): return .progress(percentage)
                case .success(data: let folder): return .success(data: [folder])
                case .error(let error): return .error(error)
            }
        })
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    private var activeSearch: Observable<RequestStatus<[FolderNetworkModel]>>? {
        didSet {
            activeSearchDisposable = activeSearch?.subscribe(onNext: { [weak self] status in
                switch status {
                case .progress:
                    self?.isLoading.accept(true)
                case .success(data: let folders):
                    self?.isLoading.accept(false)
                    let folders = folders.map({ $0.toDomainModel() })
                    self?.searchResults.accept(folders)
                    
                    if folders.isEmpty {
                        self?.tracker.track(.userNotFound)
                    }
                case .error:
                    self?.isLoading.accept(false)
                    self?.searchResults.accept([])
                }
            })
        }
    }
    
    private var activeSearchDisposable: Disposable? {
        didSet {
            oldValue?.dispose()
            activeSearchDisposable?.disposed(by: disposeBag)
        }
    }
}
