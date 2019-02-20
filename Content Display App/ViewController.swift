//
//  ViewController.swift
//  Content Display App
//
//  Created by David on 2/20/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // Set this to true to simulate being offline
    let OFFLINE: Bool = false
    
    // Make sure to fill in the correct values for the below 3 lines
    let username = "CHANGE THIS"
    let password = "CHANGE THIS"
    let contentURL = URL(string: "CHANGE THIS")!
    
    var urlSession: URLSession!
    var currentDataTask: URLSessionDataTask? = nil {
        didSet {
            OperationQueue.main.addOperation {
                if self.currentDataTask == nil {
                    self.isLoading = false
                } else {
                    self.isLoading = true
                }
            }
        }
    }
    let jsonDecoder = JSONDecoder()
    
    var libraryItems: [GeneratedLibraryItem] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure session
        guard let credentials: String = "\(username):\(password)".data(using: .utf8)?.base64EncodedString() else {
            fatalError("There's a problem with the credentials")
        }
        
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.httpAdditionalHeaders = [
            "Authorization": "Basic \(credentials)",
        ]
        
        urlSession = URLSession(configuration: urlSessionConfiguration)
        
        // Configure JSON decoder
        jsonDecoder.dateDecodingStrategy = .iso8601
        jsonDecoder.userInfo[CodingUserInfoKey.managedObjectContext!] = managedObjectContext
        
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchData()
    }
    
    // MARK: - Data operations
    
    func fetchData() {
        guard !OFFLINE else {
            return
        }
        
        let dataTask = urlSession.dataTask(with: contentURL, completionHandler: { (data, response, error) in
            self.currentDataTask = nil
            
            guard error == nil else {
                NSLog("Error retrieving content: \(error!)")
                self.showError(error: error!)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                fatalError("Unexpected type of URL response")
            }
            
            guard let data = data else {
                let message = "No data received from server"
                NSLog(message)
                self.showAlert(title: message)
                return
            }
            
            guard response.statusCode == 200 else {
                let message = "Unexpected HTTP status code: \(response.statusCode)"
                NSLog(message)
                self.showAlert(title: message)
                return
            }
            
            do {
                try self.resetData()
                
            } catch let error {
                NSLog("Error resetting Core Data - cannot display new data. Error: \(error)")
                self.showAlert(title: "Unable to show new data at this time", message: "If the problem persists, please try deleting and reinstalling the app")
                return
            }
            
            do {
                try self.parseJSON(data: data)
                
            } catch let error {
                NSLog("Error parsing JSON: \(error)")
            }
            
            self.saveData()
            self.reloadData()
        })
        dataTask.resume()
        
        currentDataTask = dataTask
    }
    
    func resetData() throws {
        let entityNames = ["LibraryItem", "LibraryItemWindow"]
        for entityName in entityNames {
            try managedObjectContext.persistentStoreCoordinator?.execute(NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: entityName)), with: managedObjectContext)
        }
    }
    
    func saveData() {
        do {
            try managedObjectContext.save()
            
        } catch let error {
            NSLog("Could not save Core Data records: \(error)")
        }
    }
    
    func loadData() {
        do {
            let fetchRequest = NSFetchRequest<GeneratedLibraryItem>(entityName: "LibraryItem")
            libraryItems = try managedObjectContext.fetch(fetchRequest)
            
        } catch let error {
            NSLog("Could not load Core Data records: \(error)")
        }
            
        libraryItems = libraryItems.filter({ (libraryItem) -> Bool in
            let windows: [GeneratedLibraryItemWindow] = libraryItem.windows?.array as? [GeneratedLibraryItemWindow] ?? []
            for window in windows {
                if let start = window.start, let end = window.end, start.timeIntervalSinceNow < 0 && end.timeIntervalSinceNow > 0 {
                    return true
                }
            }
            
            return false
        })
    }
    
    func reloadData(animated: Bool = false) {
        loadData()
        OperationQueue.main.addOperation {
            self.tableView.reloadData()
        }
    }
    
    func parseJSON(data: Data) throws {
        libraryItems = try jsonDecoder.decode([LibraryItem].self, from: data)
    }
    
    // MARK: - UI
    
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                activityIndicator.isHidden = false
                tableView.isHidden = true
            } else {
                activityIndicator.isHidden = true
                tableView.isHidden = false
            }
        }
    }
    
    func showError(error: Error) {
        showAlert(title: error.localizedDescription)
    }
    
    func showAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return libraryItems.count
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let libraryItem = libraryItems[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LibraryItemCell", for: indexPath)
        
        cell.textLabel?.text = libraryItem.name
        
        return cell
    }
}

