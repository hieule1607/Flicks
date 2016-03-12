//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Lam Hieu on 3/9/16.
//  Copyright © 2016 Lam Hieu. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource , UITableViewDelegate , UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var errorNetworkView: UIView!
    
    var movies: [NSDictionary]?
    var searchController : UISearchController!
    var endpoint: String!
    var filteredMovies: [NSDictionary]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        
        // Initialize a UIRefreshControl
        let refreshControl = UIRefreshControl()
        
        refreshControl.addTarget(self, action: "refreshControlAction:", forControlEvents: UIControlEvents.ValueChanged)
        
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        // Adding Search Bar
        self.searchController = UISearchController(searchResultsController:  nil)
        
        self.searchController.searchResultsUpdater = self
        self.searchController.delegate = self
        self.searchController.searchBar.delegate = self
        
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.sizeToFit()
        self.navigationItem.titleView = searchController.searchBar
        
        self.definesPresentationContext = true
        
        
        // Load Now Playing Movies
        loadMoviesFromMovieAPI()
        filteredMovies = movies
//        errorNetworkView.set
    }
    
/*
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
    
        return 1
    
*/
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
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        var movie: NSDictionary
        if searchController.active && searchController.searchBar.text != "" {
            movie = filteredMovies![indexPath.row]
        } else {
            movie = movies![indexPath.row]
        }
        
        let title = movie.objectForKey("title") as! String
        let overview = movie["overview"] as! String
        
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
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        return cell
    }
    
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
                            self.tableView.reloadData()
                            
                    }
                }else{
                    self.errorNetworkView.hidden = false
//                    self.showNotification()
                    print("There was a network error")
                }
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
                            self.tableView.reloadData()
                            
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
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
        var movie: NSDictionary
        
        if searchController.active && searchController.searchBar.text != "" {
            movie = filteredMovies![indexPath!.row]
        }else {
            movie = movies![indexPath!.row]
        }
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        
        detailViewController.movie = movie
    }
 /*
    func showNotification() {
        
        let errorNotifcation: UIAlertView = UIAlertView(title: "Network Error", message: "You can't access to Server. Please check connect to Internet!", delegate: self, cancelButtonTitle: "Done")
        errorNotifcation.show()
    }
*/
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
    }

}
