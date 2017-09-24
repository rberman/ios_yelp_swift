//
//  FiltersViewController.swift
//  Yelp
//
//  Created by ruthie_berman on 9/21/17.
//  Copyright © 2017 Timothy Lee. All rights reserved.
//

import UIKit

@objc protocol FiltersViewControllerDelegate {
  @objc optional func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String:AnyObject])
}



class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SwitchCellDelegate {

  @IBOutlet weak var tableView: UITableView!

  weak var delegate: FiltersViewControllerDelegate?

  private enum Section: Int {
    case deals = 0, distance, sortBy, category
  }
  private var sectionDetails = [SectionDetails]()
  struct SectionDetails {
    var name: String
    var collapsed: Bool
    var isCollapsible: Bool
    var settings: [[String:String]]

    init(name: String, collapsed: Bool = false, isCollapsible: Bool, settings: [[String:String]]) {
      self.name = name
      self.collapsed = collapsed
      self.isCollapsible = isCollapsible
      self.settings = settings
    }
  }

  private var dealsSwitchState: Bool = false
  private var distanceSwitchState: Double? = nil
  private var sortedBySwitchState: YelpSortMode? = nil
  private var categorySwitchStates = [Int:Bool]()

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.dataSource = self
    tableView.delegate = self
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 50;

    sectionDetails = [
      SectionDetails(name: "Deals", isCollapsible: false, settings: yelpDeals()),
      SectionDetails(name: "Distance", collapsed: true, isCollapsible: true, settings: yelpDistance()),
      SectionDetails(name: "Sort By", collapsed: true, isCollapsible: true, settings: yelpSortBy()),
      SectionDetails(name: "Category", isCollapsible: false, settings: yelpCategories()),
    ]

    // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction private func cancelButtonTapped(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }

  @IBAction private func searchButtonTapped(_ sender: Any) {
    var filters = [String:AnyObject]()

    filters["deals"] = dealsSwitchState as AnyObject

    if distanceSwitchState != nil {
      let metersPerMile = 1609.34
      let distanceInMeters = distanceSwitchState! * metersPerMile
      filters["distance"] = distanceInMeters as AnyObject
    }

    if sortedBySwitchState != nil {
      filters["sortBy"] = sortedBySwitchState as AnyObject
    }

    var selectedCategories = [String]()
    for (row, isSelected) in categorySwitchStates {
      if isSelected {
        selectedCategories.append(sectionDetails[Section.category.rawValue].settings[row]["code"]!)
      }
    }

    if selectedCategories.count > 0 {
      filters["categories"] = selectedCategories as AnyObject
    }

    delegate?.filtersViewController!(filtersViewController: self, didUpdateFilters: filters)
    dismiss(animated: true, completion: nil)
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return sectionDetails.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if sectionDetails[section].isCollapsible && sectionDetails[section].collapsed {
      return 0
    } else {
      return sectionDetails[section].settings.count
    }
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerCell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell") as! HeaderCell
    headerCell.nameLabel.text = (section == Section.deals.rawValue) ? " " : sectionDetails[section].name
    headerCell.section = section
    headerCell.backgroundColor = (section == Section.deals.rawValue) ? headerCell.backgroundColor : UIColor.white
    headerCell.isUserInteractionEnabled = true
    headerCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(headerCellTapped(_:))))
    if sectionDetails[section].isCollapsible && sectionDetails[section].collapsed{
      headerCell.accessoryType = .disclosureIndicator
    }
    return headerCell
  }

  func headerCellTapped(_ sender: UITapGestureRecognizer) {
    let headerCell = sender.view as! HeaderCell
    headerCell.accessoryType = .checkmark
    let sectionIsCollapsed = sectionDetails[headerCell.section].collapsed
    sectionDetails[headerCell.section].collapsed = !sectionIsCollapsed
    tableView.reloadData()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == Section.deals.rawValue || indexPath.section == Section.category.rawValue {
      let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
      cell.switchLabel.text = sectionDetails[indexPath.section].settings[indexPath.row]["name"]
      cell.onSwitch.isOn = false
      cell.delegate = self
      if indexPath.section == Section.category.rawValue {
        cell.onSwitch.isOn = categorySwitchStates[indexPath.row] ?? false
      }
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: "CheckCell", for: indexPath) as! CheckCell
      cell.checkLabel.text = sectionDetails[indexPath.section].settings[indexPath.row]["name"]
      return cell
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == Section.distance.rawValue || indexPath.section == Section.sortBy.rawValue {
      let cell = tableView.cellForRow(at: indexPath)
      cell?.accessoryType = .checkmark
      deselectCheckedCells(section: indexPath.section, exceptRow: indexPath.row)
    }
    if indexPath.section == Section.distance.rawValue {
      switch indexPath.row {
      case 0:
        distanceSwitchState = 0.3
      case 1:
        distanceSwitchState = 1.0
      case 2:
        distanceSwitchState = 5.0
      case 3:
        distanceSwitchState = 20.0
      default:
        distanceSwitchState = 5.0
      }
    }
    else if indexPath.section == Section.sortBy.rawValue{
      switch indexPath.row {
      case 0:
        sortedBySwitchState = YelpSortMode.bestMatched
      case 1:
        sortedBySwitchState = YelpSortMode.distance
      case 2:
        sortedBySwitchState = YelpSortMode.highestRated
      default:
        sortedBySwitchState = YelpSortMode.bestMatched
      }
    }
  }

  private func deselectCheckedCells(section: Int, exceptRow: Int?) {
    for row in 0 ..< tableView.numberOfRows(inSection: section) {
      if exceptRow == row {
        continue
      }
      let cell = tableView.cellForRow(at: [section, row]) as! CheckCell
      cell.accessoryType = .none
    }
  }

  func switchCell(switchCell: SwitchCell, didChangeValue value: Bool) {
    let indexPath = tableView.indexPath(for: switchCell)!
    if indexPath.section == Section.deals.rawValue {
      dealsSwitchState = value
    } else if indexPath.section == Section.category.rawValue {
      categorySwitchStates[indexPath.row] = value
    }
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */

  private func yelpDeals() -> [[String:String]] {
    return [["name" : "Offering a Deal"]]
  }

  private func yelpDistance() -> [[String:String]] {
    return [["name" : "0.3 miles"],
            ["name" : "1 miles"],
            ["name" : "5 miles"],
            ["name" : "20 miles"]]
  }

  private func yelpSortBy() -> [[String:String]] {
    return [["name" : "Best Matched", "code": "0"],
            ["name" : "Distance", "code": "1"],
            ["name" : "Highest Rated", "code": "2"],]
  }

  private func yelpCategories() -> [[String:String]] {
    return [["name" : "Afghan", "code": "afghani"],
            ["name" : "African", "code": "african"],
            ["name" : "American, New", "code": "newamerican"],
            ["name" : "American, Traditional", "code": "tradamerican"],
            ["name" : "Arabian", "code": "arabian"],
            ["name" : "Argentine", "code": "argentine"],
            ["name" : "Armenian", "code": "armenian"],
            ["name" : "Asian Fusion", "code": "asianfusion"],
            ["name" : "Asturian", "code": "asturian"],
            ["name" : "Australian", "code": "australian"],
            ["name" : "Austrian", "code": "austrian"],
            ["name" : "Baguettes", "code": "baguettes"],
            ["name" : "Bangladeshi", "code": "bangladeshi"],
            ["name" : "Barbeque", "code": "bbq"],
            ["name" : "Basque", "code": "basque"],
            ["name" : "Bavarian", "code": "bavarian"],
            ["name" : "Beer Garden", "code": "beergarden"],
            ["name" : "Beer Hall", "code": "beerhall"],
            ["name" : "Beisl", "code": "beisl"],
            ["name" : "Belgian", "code": "belgian"],
            ["name" : "Bistros", "code": "bistros"],
            ["name" : "Black Sea", "code": "blacksea"],
            ["name" : "Brasseries", "code": "brasseries"],
            ["name" : "Brazilian", "code": "brazilian"],
            ["name" : "Breakfast & Brunch", "code": "breakfast_brunch"],
            ["name" : "British", "code": "british"],
            ["name" : "Buffets", "code": "buffets"],
            ["name" : "Bulgarian", "code": "bulgarian"],
            ["name" : "Burgers", "code": "burgers"],
            ["name" : "Burmese", "code": "burmese"],
            ["name" : "Cafes", "code": "cafes"],
            ["name" : "Cafeteria", "code": "cafeteria"],
            ["name" : "Cajun/Creole", "code": "cajun"],
            ["name" : "Cambodian", "code": "cambodian"],
            ["name" : "Canadian", "code": "New)"],
            ["name" : "Canteen", "code": "canteen"],
            ["name" : "Caribbean", "code": "caribbean"],
            ["name" : "Catalan", "code": "catalan"],
            ["name" : "Chech", "code": "chech"],
            ["name" : "Cheesesteaks", "code": "cheesesteaks"],
            ["name" : "Chicken Shop", "code": "chickenshop"],
            ["name" : "Chicken Wings", "code": "chicken_wings"],
            ["name" : "Chilean", "code": "chilean"],
            ["name" : "Chinese", "code": "chinese"],
            ["name" : "Comfort Food", "code": "comfortfood"],
            ["name" : "Corsican", "code": "corsican"],
            ["name" : "Creperies", "code": "creperies"],
            ["name" : "Cuban", "code": "cuban"],
            ["name" : "Curry Sausage", "code": "currysausage"],
            ["name" : "Cypriot", "code": "cypriot"],
            ["name" : "Czech", "code": "czech"],
            ["name" : "Czech/Slovakian", "code": "czechslovakian"],
            ["name" : "Danish", "code": "danish"],
            ["name" : "Delis", "code": "delis"],
            ["name" : "Diners", "code": "diners"],
            ["name" : "Dumplings", "code": "dumplings"],
            ["name" : "Eastern European", "code": "eastern_european"],
            ["name" : "Ethiopian", "code": "ethiopian"],
            ["name" : "Fast Food", "code": "hotdogs"],
            ["name" : "Filipino", "code": "filipino"],
            ["name" : "Fish & Chips", "code": "fishnchips"],
            ["name" : "Fondue", "code": "fondue"],
            ["name" : "Food Court", "code": "food_court"],
            ["name" : "Food Stands", "code": "foodstands"],
            ["name" : "French", "code": "french"],
            ["name" : "French Southwest", "code": "sud_ouest"],
            ["name" : "Galician", "code": "galician"],
            ["name" : "Gastropubs", "code": "gastropubs"],
            ["name" : "Georgian", "code": "georgian"],
            ["name" : "German", "code": "german"],
            ["name" : "Giblets", "code": "giblets"],
            ["name" : "Gluten-Free", "code": "gluten_free"],
            ["name" : "Greek", "code": "greek"],
            ["name" : "Halal", "code": "halal"],
            ["name" : "Hawaiian", "code": "hawaiian"],
            ["name" : "Heuriger", "code": "heuriger"],
            ["name" : "Himalayan/Nepalese", "code": "himalayan"],
            ["name" : "Hong Kong Style Cafe", "code": "hkcafe"],
            ["name" : "Hot Dogs", "code": "hotdog"],
            ["name" : "Hot Pot", "code": "hotpot"],
            ["name" : "Hungarian", "code": "hungarian"],
            ["name" : "Iberian", "code": "iberian"],
            ["name" : "Indian", "code": "indpak"],
            ["name" : "Indonesian", "code": "indonesian"],
            ["name" : "International", "code": "international"],
            ["name" : "Irish", "code": "irish"],
            ["name" : "Island Pub", "code": "island_pub"],
            ["name" : "Israeli", "code": "israeli"],
            ["name" : "Italian", "code": "italian"],
            ["name" : "Japanese", "code": "japanese"],
            ["name" : "Jewish", "code": "jewish"],
            ["name" : "Kebab", "code": "kebab"],
            ["name" : "Korean", "code": "korean"],
            ["name" : "Kosher", "code": "kosher"],
            ["name" : "Kurdish", "code": "kurdish"],
            ["name" : "Laos", "code": "laos"],
            ["name" : "Laotian", "code": "laotian"],
            ["name" : "Latin American", "code": "latin"],
            ["name" : "Live/Raw Food", "code": "raw_food"],
            ["name" : "Lyonnais", "code": "lyonnais"],
            ["name" : "Malaysian", "code": "malaysian"],
            ["name" : "Meatballs", "code": "meatballs"],
            ["name" : "Mediterranean", "code": "mediterranean"],
            ["name" : "Mexican", "code": "mexican"],
            ["name" : "Middle Eastern", "code": "mideastern"],
            ["name" : "Milk Bars", "code": "milkbars"],
            ["name" : "Modern Australian", "code": "modern_australian"],
            ["name" : "Modern European", "code": "modern_european"],
            ["name" : "Mongolian", "code": "mongolian"],
            ["name" : "Moroccan", "code": "moroccan"],
            ["name" : "New Zealand", "code": "newzealand"],
            ["name" : "Night Food", "code": "nightfood"],
            ["name" : "Norcinerie", "code": "norcinerie"],
            ["name" : "Open Sandwiches", "code": "opensandwiches"],
            ["name" : "Oriental", "code": "oriental"],
            ["name" : "Pakistani", "code": "pakistani"],
            ["name" : "Parent Cafes", "code": "eltern_cafes"],
            ["name" : "Parma", "code": "parma"],
            ["name" : "Persian/Iranian", "code": "persian"],
            ["name" : "Peruvian", "code": "peruvian"],
            ["name" : "Pita", "code": "pita"],
            ["name" : "Pizza", "code": "pizza"],
            ["name" : "Polish", "code": "polish"],
            ["name" : "Portuguese", "code": "portuguese"],
            ["name" : "Potatoes", "code": "potatoes"],
            ["name" : "Poutineries", "code": "poutineries"],
            ["name" : "Pub Food", "code": "pubfood"],
            ["name" : "Rice", "code": "riceshop"],
            ["name" : "Romanian", "code": "romanian"],
            ["name" : "Rotisserie Chicken", "code": "rotisserie_chicken"],
            ["name" : "Rumanian", "code": "rumanian"],
            ["name" : "Russian", "code": "russian"],
            ["name" : "Salad", "code": "salad"],
            ["name" : "Sandwiches", "code": "sandwiches"],
            ["name" : "Scandinavian", "code": "scandinavian"],
            ["name" : "Scottish", "code": "scottish"],
            ["name" : "Seafood", "code": "seafood"],
            ["name" : "Serbo Croatian", "code": "serbocroatian"],
            ["name" : "Signature Cuisine", "code": "signature_cuisine"],
            ["name" : "Singaporean", "code": "singaporean"],
            ["name" : "Slovakian", "code": "slovakian"],
            ["name" : "Soul Food", "code": "soulfood"],
            ["name" : "Soup", "code": "soup"],
            ["name" : "Southern", "code": "southern"],
            ["name" : "Spanish", "code": "spanish"],
            ["name" : "Steakhouses", "code": "steak"],
            ["name" : "Sushi Bars", "code": "sushi"],
            ["name" : "Swabian", "code": "swabian"],
            ["name" : "Swedish", "code": "swedish"],
            ["name" : "Swiss Food", "code": "swissfood"],
            ["name" : "Tabernas", "code": "tabernas"],
            ["name" : "Taiwanese", "code": "taiwanese"],
            ["name" : "Tapas Bars", "code": "tapas"],
            ["name" : "Tapas/Small Plates", "code": "tapasmallplates"],
            ["name" : "Tex-Mex", "code": "tex-mex"],
            ["name" : "Thai", "code": "thai"],
            ["name" : "Traditional Norwegian", "code": "norwegian"],
            ["name" : "Traditional Swedish", "code": "traditional_swedish"],
            ["name" : "Trattorie", "code": "trattorie"],
            ["name" : "Turkish", "code": "turkish"],
            ["name" : "Ukrainian", "code": "ukrainian"],
            ["name" : "Uzbek", "code": "uzbek"],
            ["name" : "Vegan", "code": "vegan"],
            ["name" : "Vegetarian", "code": "vegetarian"],
            ["name" : "Venison", "code": "venison"],
            ["name" : "Vietnamese", "code": "vietnamese"],
            ["name" : "Wok", "code": "wok"],
            ["name" : "Wraps", "code": "wraps"],
            ["name" : "Yugoslav", "code": "yugoslav"]]
  }
}
