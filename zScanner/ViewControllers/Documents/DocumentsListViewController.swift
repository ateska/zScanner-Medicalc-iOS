//
//  DocumentsListViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

protocol DocumentsListCoordinator: BaseCoordinator {
    func createNewDocument()
    func openMenu()
}

class DocumentsListViewController: BaseViewController, ErrorHandling {
    
    // MARK: Instance part
    private unowned let coordinator: DocumentsListCoordinator
    private let viewModel: DocumentsListViewModel
        
    init(viewModel: DocumentsListViewModel, coordinator: DocumentsListCoordinator) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        
        super.init(coordinator: coordinator)
    }
    
    // MARK: Lifecycle
    override func loadView() {
        super.loadView()
        
        setupView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.updateDocuments()
        documentsTableView.reloadSections([0], with: .fade)
    }
    
    override var leftBarButtonItems: [UIBarButtonItem] {
        return [
            UIBarButtonItem(image: #imageLiteral(resourceName: "menuIcon"),style: .plain, target: self, action: #selector(openMenu))
        ]
    }
    
    override var rightBarButtonItems: [UIBarButtonItem] {
        return rightBarButtons
    }
    
    // MARK: Interface
    func insertNewDocument(document: DocumentViewModel) {
        viewModel.insertNewDocument(document)
        documentsTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    private var rightBarButtons: [UIBarButtonItem] = [] {
        didSet {
            navigationItem.rightBarButtonItems = rightBarButtons
        }
    }
    
    private func setupBindings() {
        viewModel.isDepartmentSelected
            .observeOn(MainScheduler.instance)
            .subscribe { (isSelected) in
                guard let isSelected = isSelected.element else { return }
                if isSelected {
                    self.viewModel.documentModesState.onNext(.success)
                } else {
                    self.viewModel.documentModesState.onNext(.awaitingInteraction)
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.documentModesState
            .asObserver()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] status in
                switch status {
                case .awaitingInteraction:
                    self.rightBarButtons = []
                case .loading:
                    self.rightBarButtons = [self.loadingItem]
                case .success:
                    self.rightBarButtons = [self.addButton]
                case .error(let error):
                    self.rightBarButtons = [self.reloadButton]
                    self.handleError(error, okCallback: nil) {
                        self.reloadDocumentTypes()
                    }
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.departments
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self] _ in
                self?.departmentsTableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func newDocument() {
        self.coordinator.createNewDocument()
    }
    
    @objc private func openMenu() {
        coordinator.openMenu()
    }
    
    @objc private func reloadDocumentTypes() {
        viewModel.updateDocumentTypes()
    }
    
    private func setupView() {
        navigationItem.title = "document.screen.title".localized
        
        documentsTableView.dataSource = self
        view.addSubview(documentsTableView)
        documentsTableView.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualToSuperview()
            make.trailing.leading.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.66)
        }
        
        documentsTableView.backgroundView = emptyView
        
        emptyView.addSubview(emptyViewLabel)
        emptyViewLabel.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.75)
            make.centerX.equalToSuperview()
            make.top.equalTo(documentsTableView.sectionHeaderHeight)
            make.centerY.equalToSuperview().multipliedBy(0.666).priority(900)
        }
        
        departmentsTableView.dataSource = self
        departmentsTableView.delegate = self
        view.addSubview(departmentsTableView)
        departmentsTableView.snp.makeConstraints { (make) in
            make.top.equalTo(documentsTableView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newDocument))
    
    private lazy var reloadButton = UIBarButtonItem(image: #imageLiteral(resourceName: "refresh"), style: .plain, target: self, action: #selector(reloadDocumentTypes))
    
    private lazy var loadingItem: UIBarButtonItem = {
        let loading = UIActivityIndicatorView(style: .gray)
        loading.startAnimating()
        let button = UIBarButtonItem(customView: loading)
        button.isEnabled = false
        return button
    }()
    
    private lazy var documentsTableView: UITableView = {
        let tableView = UITableView()
        tableView.registerCell(DocumentTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        return tableView
    }()

    private lazy var departmentsTableView: UITableView = {
        let tableView = UITableView()
        tableView.registerCell(DepartmentTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        return tableView
    }()
    
    private lazy var emptyView = UIView()
    
    private lazy var emptyViewLabel: UILabel = {
        let label = UILabel()
        label.text = "document.emptyView.title".localized
        label.textColor = .black
        label.numberOfLines = 0
        label.font = .body
        label.textAlignment = .center
        return label
    }()
}

//MARK: - UITableViewDataSource implementation
extension DocumentsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == self.documentsTableView {
            return "documents.tableHeader".localized
        } else {
            return "departments.tableHeader".localized
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.documentsTableView {
            let count = viewModel.documents.count
            tableView.backgroundView?.isHidden = count > 0
            return count
        } else {
            do {
                let count = try viewModel.departments.value().count
                return count
            } catch(let error) {
                print(error)
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.documentsTableView {
            let document = viewModel.documents[indexPath.row]
            let cell = tableView.dequeueCell(DocumentTableViewCell.self)
            cell.setup(with: document, delegate: self)
            return cell
        } else {
            let cell = tableView.dequeueCell(DepartmentTableViewCell.self)
            do {
                let department = try viewModel.departments.value()[indexPath.row]
                cell.setup(with: department)
                return cell
            } catch(let error) {
                print(error)
                return cell
            }
        }
    }
}

extension DocumentsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.isDepartmentSelected.accept(true)
    }
}

//MARK: - DocumentViewDelegate implementation
extension DocumentsListViewController: DocumentViewDelegate {}
