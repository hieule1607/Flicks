//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Lam Hieu on 3/12/16.
//  Copyright © 2016 Lam Hieu. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource , UITableViewDelegate , UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate , UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var errorNetworkView: UIView!
    
    var movies: [NSDictionary]?
    var searchController : UISearchController!
    var endpoint: String!
    var filteredMovies: [NSDictionary]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Adding Search Bar
        self.searchController = UISearchController(searchResultsController:  nil)
        
        self.searchController.searchResultsUpdater = self
        self.searchController.delegate = self
        self.searchController.searchBar.delegate = self
        
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.dimsBackgroundDuringPresentation = false
        
        self.navigationItem.titleView = searchController.searchBar
        
        self.definesPresentationContext = true
        
        // Load Now Playing Movies
        loadMoviesFromMovieAPI()
        filteredMovies = movies
        
        // Initialize a UIRefreshControl
        let refreshControl = UIRefreshControl()
        
        refreshControl.addTarget(self, action: "refreshControlAction:", forControlEvents: UIControlEvents.ValueChanged)
        
        tableView.insertSubview(refreshControl, atIndex: 0)

    }
    
    @IBAction func showHideView(sender: AnyObject) {
        switch (sender.selectedSegmentIndex){
        case 0:
            self.tableView.hidden = false
            self.collectionView.hidden = true
            break
        case 1:
            self.tableView.hidden = true
            self.collectionView.hidden = false
            break
        default:
            break
        }
        
    }
    //TablleView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        if searchController.active && searchController.searchBar.text != "" {
            if let movies = filteredMovies{
                return movies.count
            }else{
                return 0
            }
            
        }else{
            if let movies = movies{
                return movies.count
            }else{
                return 0
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieTableCell", forIndexPath: indexPath) as! MovieCell
        
        var movie: NSDictionary
        if searchController.active && searchController.searchBar.text != "" {
            movie = filteredMovies![indexPath.row]
        } else {
            movie = movies![indexPath.row]
        }
        
        let title = movie.objectForKey("title") as! String
        let overview = movie["overview"] as! String
        
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        let posterBaseUrl = "http://image.tmdb.org/t/p/w500"
        if let posterPath = movie["poster_path"] as? String {
            let posterUrl = NSURL(string: posterBaseUrl + posterPath)
            cell.posterView.setImageWithURL(posterUrl!)
        }
        else {
            // No poster image. Can either set to nil (no image) or a default movie poster image
            // that you include as an asset
            cell.posterView.image = nil
        }

        return cell
    }
    
    // Collection View
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            if let movies = filteredMovies{
                return movies.count
            }else{
                return 0
            }
            
        }else{
            if let movies = movies{
                return movies.count
            }else{
                return 0
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MovieCollectionCell", forIndexPath: indexPath) as! MovieCollectionCell
        
        var movie: NSDictionary
        if searchController.active && searchController.searchBar.text != "" {
            movie = filteredMovies![indexPath.row]
        } else {
            movie = movies![indexPath.row]
        }
        let posterBaseUrl = "http://image.tmdb.org/t/p/w500"
        if let posterPath = movie["poster_path"] as? String {
            let posterUrl = NSURL(string: posterBaseUrl + posterPath)
            cell.posterView.setImageWithURL(posterUrl!)
        }
        else {
            // No poster image. Can either set to nil (no image) or a default movie poster image
            // that you include as an asset
            cell.posterView.image = nil
        }
        return cell
    }
    
    // Load Movies Data
    func loadMoviesFromMovieAPI() {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(
            URL: url!,
            cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
            timeoutInterval: 10)
        
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        // Display HUD right before the request is made
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (data, response, error) in
                
                // Hide HUD once the network request comes back (must be done on main UI thread)
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                
                if let data = data {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            self.errorNetworkView.hidden = true
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                                                        
                    }
                }else{
                    self.errorNetworkView.hidden = false
                   
                    print("There was a network error")
                }
                
                // Reload the tableView now that there is new data
                self.tableView.reloadData()
                self.collectionView.reloadData()
                
        })
        task.resume()
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl) {
        
        // ... Create the NSURLRequest
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(
            URL: url!,
            cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
            timeoutInterval: 10)
        
        // Configure session so that completion handler is executed on main UI thread
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (data, response, error) in
                
                // ... Use the new data to update the data source ...
                if let data = data {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            self.errorNetworkView.hidden = true
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            
                    }
                }else{
                    self.errorNetworkView.hidden = false
                    //                    self.showNotification()
                    print("There was a network error")
                }
                
                // Reload the tableView now that there is new data
                self.tableView.reloadData()
                
                
                // Tell the refreshControl to stop spinning
                refreshControl.endRefreshing()
        });
        task.resume()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        var movie: NSDictionary
        if (segmentedControl.selectedSegmentIndex == 0) {
            let tableCell = sender as! UITableViewCell
            let tableIndexPath = tableView.indexPathForCell(tableCell)
        
            if searchController.active && searchController.searchBar.text != "" {
                movie = filteredMovies![tableIndexPath!.row]
            }else {
                movie = movies![tableIndexPath!.row]
            }

        }else {
            let collectionCell = sender as! UICollectionViewCell
            let collectionIndexPath = collectionView.indexPathForCell(collectionCell)
            
            if searchController.active && searchController.searchBar.text != "" {
                movie = filteredMovies![collectionIndexPath!.row]
            }else {
                movie = movies![collectionIndexPath!.row]
            }
        }
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        
        detailViewController.movie = movie
    }
    
    // Search
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredMovies = movies?.filter {
            movie in
            let title = movie["title"] as? String
            
            return title!.lowercaseString.containsString(searchText.lowercaseString)
        }
        
        tableView.reloadData()
        collectionView.reloadData()
    }
    
}

