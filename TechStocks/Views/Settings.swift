//
//  Settings.swift
//  TechStocks
//
//  Created by Nikhil Dixit on 5/25/20.
//  Copyright © 2020 Nikhil Dixit. All rights reserved.
//

import UIKit
import CoreData
import MarqueeLabel

class Settings: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var currencyPickerView: UIPickerView!
    @IBOutlet weak var sortOrderPickerView: UIPickerView!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var darkModeLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var sortCriteriaLabel: UILabel!
    
    let defaults = UserDefaults.standard
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var currencies = ["AUD", "BRL","CAD","CNY","EUR","GBP","HKD","IDR","ILS","INR","JPY","MXN","NOK","NZD","PLN","RON","RUB","SEK","SGD","USD","ZAR"]
    var sortingOptions = ["A-Z", "Z-A", "Highest Share Price", "Lowest Share Price"]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Tests if dark mode should be active and sets colors accordingly
        if defaults.bool(forKey: "nightMode") {
            darkModeSwitch.setOn(true, animated: false)
            setUIColorScheme(backgroundColor: UIColor.black, textColor: UIColor.white)
        }
        
    }
    
    //Sets color scheme of UI, Parameters are the colors to set the UI Color
    func setUIColorScheme(backgroundColor: UIColor, textColor: UIColor) {
        
        if defaults.bool(forKey: "nightMode"){
            self.navigationController!.navigationBar.tintColor = UIColor.systemOrange
        }
        else {
            self.navigationController!.navigationBar.tintColor = UIColor.systemBlue
        }
        
        navigationController?.navigationBar.barTintColor = backgroundColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: textColor]
        currencyPickerView.backgroundColor = backgroundColor
        sortOrderPickerView.backgroundColor = backgroundColor
        currencyPickerView.setValue(textColor, forKeyPath: "textColor")
        sortOrderPickerView.setValue(textColor, forKeyPath: "textColor")
        self.view.backgroundColor = backgroundColor
        darkModeLabel.textColor = textColor
        currencyLabel.textColor = textColor
        sortCriteriaLabel.textColor = textColor
    }
    
    //Executes if darkModeSwitch flipped
    @IBAction func darkModeSwitch(_ sender: Any) {
        
        if darkModeSwitch.isOn {
            defaults.set(true, forKey: "nightMode")
            setUIColorScheme(backgroundColor: UIColor.black, textColor: UIColor.white)
        }
        else {
            defaults.set(false, forKey: "nightMode")
            setUIColorScheme(backgroundColor: UIColor.white, textColor: UIColor.black)
        }
    }
    
    @IBAction func applySortSettings(_ sender: Any) {
        
    }
    
    
    //Currency PickerView DataSource Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView.tag == 0 {
            return currencies.count
        }
        else {
            return sortingOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView.tag == 0 {
            return currencies[row]
        }
        else {
            return sortingOptions[row]
        }
    }
    
}
