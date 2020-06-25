//
//  MainScreen.swift
//  TechStocks
//
//  Created by Nikhil Dixit on 4/1/20.
//  Copyright © 2020 Nikhil Dixit. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import CoreData

class MainScreen: UITableViewController {

    let urlOne = "https://cloud.iexapis.com/stable/stock/"
    let urlTwo = "/quote/close?token=pk_5a71125156c341b2827bdac41dffe4c8&period=annual"
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    //1 2D array to hold all companies
    var companies: [[Stock]] = [[Stock]]()
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(FileManager.default.urls(for: .documentationDirectory, in: .userDomainMask))
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        refreshGUI()
        refreshInterimData()
        
        for i in 0..<companies.count {
            //HTTP request
            for j in 0..<companies[i].count {
                //stockPriceRequest(row: i, col: j)
            }
        }
        self.tableView.reloadData()
    }
    
    // MARK -- Custom Methods
    //Refreshes GUI for light/dark themes
    func refreshGUI() {
        
        if defaults.bool(forKey: "nightMode") {
            navigationController?.navigationBar.barTintColor = UIColor.black
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
            self.tableView.backgroundColor = UIColor.black
            self.tableView.separatorColor = UIColor.darkGray
            self.navigationController!.navigationBar.tintColor = UIColor.systemOrange
        }
        else {
            navigationController?.navigationBar.barTintColor = UIColor.white
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
            self.tableView.backgroundColor = UIColor.white
            self.tableView.separatorColor = UIColor.lightGray
            self.navigationController!.navigationBar.tintColor = UIColor.systemBlue
        }
        self.tableView.reloadData()
    }
    
    //Retrives data from persistant container and adds it to interim array
    func refreshInterimData() {
        companies.removeAll()
        var tempCompanies = [Stock]()
        
        //Temporary arrays that will be appended to companies[[]]
        var tempFavoriteCompanies = [Stock]()
        var tempNonFavCompanies = [Stock]()
        
        let request : NSFetchRequest<Stock> = Stock.fetchRequest()
        do {
            tempCompanies = try context.fetch(request)
        }
        catch {
            print("Error fetching data from context: \(error)")
        }
        
        //Goes through tempCompanies and assigns each stock to correct array
        for i in 0..<tempCompanies.count {
            
            if tempCompanies[i].isFavorite {
                tempFavoriteCompanies.append(tempCompanies[i])
            }
            else {
                tempNonFavCompanies.append(tempCompanies[i])
            }
        }
        companies.append(tempFavoriteCompanies)
        companies.append(tempNonFavCompanies)
        self.tableView.reloadData()
    }
    
    //Master function to request price data from the IEX Cloud API
    func stockPriceRequest(row: Int, col: Int) {
        
        Alamofire.request(urlOne + companies[row][col].stockSymbol! + urlTwo, method : .get).responseString { response in
            if(response.result.isSuccess){
                let stockJSON : Double = Double(response.result.value ?? "0.0") ?? 0.0
                self.companies[row][col].stockPrice = stockJSON
                self.tableView.reloadData()
            }
            else {
                print(response)
            }
        
        }
        self.tableView.reloadData()
    }
    
    //Saves items to persistant storage
    func saveItems() {
        do {
            try context.save()
        }
        catch {
            print("Error Saving Context")
        }
    }
    
    // MARK -- UI Methods
    // These two methods switch the status bar to dark mode
    override var preferredStatusBarStyle: UIStatusBarStyle {

        if defaults.bool(forKey: "nightMode") {
            return .darkContent
        }
        else {
            return .lightContent
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {

        if defaults.bool(forKey: "nightMode") {
            navigationController?.navigationBar.barStyle = .black
        }
        else {
            navigationController?.navigationBar.barStyle = .default
        }

    }
    
    //Executes whenever view is displayed on screen
    override func viewWillAppear(_ animated: Bool) {
        refreshInterimData()
        refreshGUI()
        self.tableView.reloadData()
    }
    
    
    //MARK -- TableViewController Methods
    
    //Provides number of cells in a section of the tableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return companies[section].count
    }

    //Creates and assigns appropriate text values to UITableViewCells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StockCell", for:  indexPath)
        
        cell.textLabel?.text = "\(companies[indexPath.section][indexPath.row].stockSymbol!) - \(companies[indexPath.section][indexPath.row].name!)"
        cell.detailTextLabel?.text = String(format: "$%.02f", companies[indexPath.section][indexPath.row].stockPrice)
        
        if defaults.bool(forKey: "nightMode") {
            cell.backgroundColor = UIColor.black
            cell.textLabel?.textColor = UIColor.white
            cell.detailTextLabel?.textColor = UIColor.white
        }
        else {
            cell.backgroundColor = UIColor.white
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
        }
        
        return cell
    
    }
     
    //Allows user to delete a particular stock via swiping from right to left
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //DATA MUST BE REMOVED FROM PERSISTANT CONTAINER FIRST, OTHERWISE DATASOURCE METHODS TRY TO POPULATE TABLEVIEW WITH VALUES THAT DON'T EXIST WITHIN THE SPECIFIED ARRAY
            context.delete(companies[indexPath.section][indexPath.row])
            companies[indexPath.section].remove(at: indexPath.row)
            
            saveItems()
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.tableView.reloadData()
        }
    }
    
    //Allows user to favorite a particular stock via swiping from left to right
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var closeAction : UIContextualAction = UIContextualAction()
        
        print(indexPath.section)
        print(indexPath.row)
        
        //Decision structure that determines which section user is in (Favorites or Non-Favorites) and completes appropriate action
        if companies[indexPath.section][indexPath.row].isFavorite {
            closeAction = UIContextualAction(style: .normal, title:  "Unfavorite", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                print("OK, marked as Closed")
                self.companies[indexPath.section][indexPath.row].isFavorite = false
                self.saveItems()
                success(true)
            })
        }
        else {
            closeAction = UIContextualAction(style: .normal, title:  "Favorite", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                print("OK, marked as Closed")
                self.companies[indexPath.section][indexPath.row].isFavorite = true
                self.saveItems()
                success(true)
            })
        }
        return UISwipeActionsConfiguration(actions: [closeAction])
      
    }
    
    // Number of sections in tableView (Should always be 2 because of favorites and non-favorites)
    override func numberOfSections(in tableView: UITableView) -> Int {
        return companies.count
    }
    
    // Favorites header
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Favorites"
        }
        return "Non-Favorites"
    }
    
    //Changes color of section headers/section header text
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        
        if defaults.bool(forKey: "nightMode") {
            view.tintColor = UIColor.darkGray
            header.textLabel?.textColor = UIColor.white
        }
        else {
            view.tintColor = UIColor.systemGray4
            header.textLabel?.textColor = UIColor.black
        }
    }
}
