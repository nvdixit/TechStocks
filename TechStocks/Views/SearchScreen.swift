//
//  SearchScreen.swift
//  TechStocks
//
//  Created by Nikhil Dixit on 4/19/20.
//  Copyright © 2020 Nikhil Dixit. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

// Baby class for tying together all three values to each other correctly in SearchScreen.swift only
struct Company {
    var sharePrice: Double
    var name: String
    var tickerSymbol: String
}

class SearchScreen: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let defaults = UserDefaults.standard
    
    //All API urls
    let searchAPIUrl = "https://ticker-2e1ica8b9.now.sh//keyword/"
    let priceAPIUrlOne = "https://cloud.iexapis.com/stable/stock/"
    let priceAPIUrlTwo = "/quote/close?token=pk_5a71125156c341b2827bdac41dffe4c8&period=annual"
    
    //Array that holds all the possible companies and prices
    var potentialStocks = [Company]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUIColorScheme()
        //Set all UI element delegates and dataSources
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
    }
    
    func setUIColorScheme() {
        if defaults.bool(forKey: "nightMode") {
            self.view.backgroundColor = UIColor.black
            tableView.backgroundColor = UIColor.black
            searchBar.barTintColor = UIColor.black
            let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
            textFieldInsideSearchBar?.textColor = UIColor.white
            tableView.separatorColor = UIColor.lightGray
        }
    }
    
    //MARK -- TableView DataSource methods 
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return potentialStocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchStockCell", for:  indexPath)
        cell.textLabel?.text = potentialStocks[indexPath.row].tickerSymbol + " - \(potentialStocks[indexPath.row].name)"
        cell.detailTextLabel?.text = String(format: "$%.02f", potentialStocks[indexPath.row].sharePrice)
        
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
    
    //Determines the cell selected in search tableView
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //Messagebox to determine if user wants to add new stock
        let alert = UIAlertController(title: "Add Stock", message: "Are you sure you want to add this stock to your portfolio?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { action in
            switch action.style{
            case .default:

                let newStock = Stock(context: MainScreen().context)
                newStock.name = self.potentialStocks[indexPath.row].name
                newStock.stockSymbol = self.potentialStocks[indexPath.row].tickerSymbol
                newStock.stockPrice = self.potentialStocks[indexPath.row].sharePrice
                
                do {
                    try MainScreen().context.save()
                }
                catch {
                    print("Error Saving Context")
                }
                
            case .cancel:
                print("cancel")

            case .destructive:
                print("destructive")
                
            @unknown default:
                print("Error")
            }
            
        }))
    }
    
    //MARK -- SearchBar delegate method to detect typed text
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        potentialStocks.removeAll()
        
        if(searchText == "") {
            self.potentialStocks.removeAll()
        }
        else {
            Alamofire.request(searchAPIUrl + searchText, method : .get).responseJSON { response in
                 
                 if(response.result.isSuccess){
                     
                     let companyInfoJSON : JSON = JSON(response.result.value!)
                     //ALGORITHM STILL NEEDS WORK (SPAMMING IEX FOR STOCK PRICES) --> LOOK INTO CREATING THE DICTIONARY INITIALLY AND CARVING AWAY UNNCESSARY RESULTS WHILE KEEPING STOCK PRICE
                     for i in 0..<companyInfoJSON.count {
                         let companyName = companyInfoJSON[i]["name"].string
                         let companySymbol = companyInfoJSON[i]["symbol"].string
                         var sharePrice = 0.0
                        
                         Alamofire.request(self.priceAPIUrlOne + companySymbol! + self.priceAPIUrlTwo, method : .get).responseString { response in
                                        
                             if(response.result.isSuccess){
                                 let stockJSON : Double = Double(response.result.value ?? "0.0") ?? 0.0
                                 sharePrice = stockJSON
                                 self.tableView.reloadData()
                             }
                             else {
                                 print(response)
                             }
                         }
                        
                         let potentialStockToAdd = Company(sharePrice: sharePrice, name: companyName!, tickerSymbol: companySymbol!)
                         self.potentialStocks.append(potentialStockToAdd)
                         self.tableView.reloadData()
                     }
                     self.tableView.reloadData()
                 }
                 else {
                     print(response)
                 }
             }
        }
        self.tableView.reloadData()
    }
}
