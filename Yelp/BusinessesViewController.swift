//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Timothy Lee on 4/23/15.
//  Copyright (c) 2015 Timothy Lee. All rights reserved.
//

import UIKit

class BusinessesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FiltersViewControllerDelegate, UISearchResultsUpdating, UIScrollViewDelegate {

  @IBOutlet weak var tableView: UITableView!

  var businesses: [Business]!
  private var filteredBusinesses: [Business]!
  private var searchController: UISearchController!
  private var isMoreDataLoading = false
  private var loadingMoreView:InfiniteScrollActivityView?

  private let limit = 30
  private var offset = 0
  private var deals: Bool? = false
  private var distance:Double? = nil
  private var sortBy:YelpSortMode? = nil
  private var categories:[String]? = nil


  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.delegate = self
    tableView.dataSource = self
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 120

    // Set up Search bar
    searchController = UISearchController(searchResultsController: nil)
    searchController.dimsBackgroundDuringPresentation = false
    searchController.searchResultsUpdater = self
    searchController.searchBar.sizeToFit()
    searchController.hidesNavigationBarDuringPresentation = false
    navigationItem.titleView = searchController.searchBar

    // Set up Infinite Scroll loading indicator
    let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
    loadingMoreView = InfiniteScrollActivityView(frame: frame)
    loadingMoreView!.isHidden = true
    tableView.addSubview(loadingMoreView!)

    var insets = tableView.contentInset
    insets.bottom += InfiniteScrollActivityView.defaultHeight
    tableView.contentInset = insets

    Business.searchWithTerm(term: "Thai", completion: { (businesses: [Business]?, error: Error?) -> Void in
      self.businesses = businesses
      self.filteredBusinesses = businesses
      self.tableView.reloadData()
      self.offset = self.businesses.count
    })
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if filteredBusinesses != nil {
      return filteredBusinesses!.count
    } else {
      return 0
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "BusinessCell", for: indexPath
      ) as! BusinessCell
    cell.business = filteredBusinesses[indexPath.row]
    return cell
  }

  func updateSearchResults(for searchController: UISearchController) {
    if let searchText = searchController.searchBar.text {
      filteredBusinesses = searchText.isEmpty ? businesses : businesses.filter({(data: Business) -> Bool in
        return data.name!.range(of: searchText, options: .caseInsensitive) != nil
      })
      tableView.reloadData()
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if (!isMoreDataLoading) {
      let scrollViewContentHeight = tableView.contentSize.height
      let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
      if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging) {
        isMoreDataLoading = true
        let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView?.frame = frame
        loadingMoreView!.startAnimating()
        loadMoreData()
      }
    }
  }

  func loadMoreData() {
    Business.searchWithTerm(term: "Restaurants", sort: sortBy, categories: categories, deals: deals, distanceInMeters: distance, limit: limit, offset: offset, completion: { (businesses: [Business]!, error: Error!) -> Void in
      self.businesses.append(contentsOf: businesses)
      self.filteredBusinesses = self.businesses
      self.offset += self.businesses.count
      self.isMoreDataLoading = false
      self.loadingMoreView!.stopAnimating()
      self.tableView.reloadData()

    })
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String : AnyObject]) {
    deals = filters["deals"] as? Bool
    distance = filters["distance"] as? Double
    sortBy = filters["sortBy"] as? YelpSortMode
    categories = filters["categories"] as? [String]

    Business.searchWithTerm(term: "Restaurants", sort: sortBy, categories: categories, deals: deals, distanceInMeters: distance, limit: limit, offset: 0, completion: { (businesses: [Business]!, error: Error!) -> Void in
      self.businesses = businesses
      self.filteredBusinesses = businesses
      self.tableView.reloadData()
      self.offset = self.businesses.count
    })
  }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      let navController = segue.destination as! UINavigationController
      let filtersViewController = navController.topViewController as! FiltersViewController
      filtersViewController.delegate = self
    }
}
