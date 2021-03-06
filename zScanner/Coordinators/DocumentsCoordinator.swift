//
//  DocumentsCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 26/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

protocol DocumentsFlowDelegate: FlowDelegate {
    func logout()
}

// MARK: -
class DocumentsCoordinator: Coordinator {
    
    // MARK: Instance part
    unowned private let flowDelegate: DocumentsFlowDelegate
    private let userSession: UserSession
    
    init(userSession: UserSession, flowDelegate: DocumentsFlowDelegate, window: UIWindow) {
        self.userSession = userSession
        self.flowDelegate = flowDelegate
        self.networkManager = MedicalcNetworkManager(api: api, access_token: userSession.login.access_code)
        
        super.init(window: window)
        
        setupSessionHandler()
    }
    
    // MARK: Interface
    func begin() {
        showDocumentsListScreen()
        setupMenu()
    }
    
    // MARK: Navigation methods
    private func showDocumentsListScreen() {
        let departmentsViewModel = DepartmentsListViewModel(ikemNetworkManager: networkManager)
        let documentsViewModel = DocumentsListViewModel(database: database, ikemNetworkManager: networkManager)
        let viewController = DocumentsListViewController(documentsViewModel: documentsViewModel, departmentsViewModel: departmentsViewModel, coordinator: self)
        push(viewController)
    }
    
    private lazy var menuCoordinator: MenuCoordinator = {
        return MenuCoordinator(login: userSession.login, flowDelegate: self, window: window, navigationController: navigationController)
    }()
    
    private func setupMenu() {
        addChildCoordinator(menuCoordinator)
        menuCoordinator.begin()
    }
    
    private func runNewDocumentFlow() {
        // Tracking
        if documentCreatedInThisSession {
            tracker.track(.createDocumentAgain)
        } else {
            documentCreatedInThisSession = true
        }
        
        // Start new-document flow
        guard let coordinator = NewDocumentCoordinator(userSession: userSession, flowDelegate: self, window: window, navigationController: navigationController) else { return }
        addChildCoordinator(coordinator)
        coordinator.begin()
    }
    
    // MARK: Helpers
    private let api: API = NativeAPI()
    private let networkManager: NetworkManager
    private let database: Database = try! RealmDatabase()
    private let tracker: Tracker = FirebaseAnalytics()
    private var documentCreatedInThisSession = false
    
    private func setupSessionHandler() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appEnteredBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appEnteredBackground() {
        documentCreatedInThisSession = true
    }
}

// MARK: - DocumentsListCoordinator implementation
extension DocumentsCoordinator: DocumentsListCoordinator {
    func createNewDocument() {
        runNewDocumentFlow()
    }
    func openMenu() {
        menuCoordinator.openMenu()
    }
}

// MARK: - NewDocumentFlowDelegate implementation
extension DocumentsCoordinator: NewDocumentFlowDelegate {
    func newDocumentCreated(_ documentViewModel: DocumentViewModel) {
        guard let list = viewControllers.last as? DocumentsListViewController else {
            assertionFailure()
            return
        }
        
        list.insertNewDocument(document: documentViewModel)
    }
}

// MARK: - MenuFlowDelegate implementation
extension DocumentsCoordinator: MenuFlowDelegate {
    func deleteHistory() {
        
        //Tracking
        let numberOfDocuments = database.loadObjects(DocumentDatabaseModel.self).count
        tracker.track(.numberOfDocumentsBeforeDelete(numberOfDocuments))
        
        // Deleting
        database.deleteAll(of: PageDatabaseModel.self)
        database.deleteAll(of: DocumentDatabaseModel.self)
        database.deleteAll(of: PageUploadStatusDatabaseModel.self)
        database.deleteAll(of: DocumentUploadStatusDatabaseModel.self)
        database.deleteAll(of: FolderDatabaseModel.self)
    }
    
    func logout() {
        deleteHistory()
        
        networkManager
            .logout(with: userSession.login.access_code.data(using: .utf8) ?? Data())
            .subscribe(onNext: { [weak self] requestStatus in
                // We care only a little about the result of the network call to /logout
                switch requestStatus {

                    case .progress(_):
                        break

                    case .success(data: let networkModel):
                        break
                        
                    case .error(let error):
                        break

                }
            })

        flowDelegate.logout()
        flowDelegate.coordinatorDidFinish(self)
    }
}
