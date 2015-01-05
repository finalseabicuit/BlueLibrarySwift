/*
* Copyright (c) 2014 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit

class ViewController: UIViewController {

	@IBOutlet var dataTable: UITableView!
	@IBOutlet var toolbar: UIToolbar!
    @IBOutlet weak var scroller: HorizontalScroller!
    
    private var allAlbums = [Album]()
    private var currentAlbumData: (titles:[String], values:[String])?
    private var currentAlbumIndex = 0
    
    // We will use this array as a stack to push and pop operation for the undo option
    var undoStack: [(Album, Int)] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.navigationBar.translucent = false
        currentAlbumIndex = 0
        
        allAlbums = LibraryAPI.sharedInstance.getAlbums()
        
        // the uitableview that presents the album data
        dataTable.delegate = self
        dataTable.dataSource = self
        dataTable.backgroundView = nil
        view.addSubview(dataTable!)
        
        self.showDataForAlbum(currentAlbumIndex)
        
        loadPreviousState()
        
        scroller.delegate = self
        reloadScroller()
        
        let undoButton = UIBarButtonItem(barButtonSystemItem: .Undo, target: self, action:"undoAction")
        undoButton.enabled = false;
        let space = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target:nil, action:nil)
        let trashButton = UIBarButtonItem(barButtonSystemItem: .Trash, target:self, action:"deleteAlbum")
        let toolbarButtonItems = [undoButton, space, trashButton]
        toolbar.setItems(toolbarButtonItems, animated: true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCurrentState", name: UIApplicationDidEnterBackgroundNotification, object: nil)
	}
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func showDataForAlbum(albumIndex: Int) {
        // defensive code: make sure the requested index is lower than the amount of albums
        if (albumIndex < allAlbums.count && albumIndex > -1) {
            // fetch the album
            let album = allAlbums[albumIndex]
            // save the albums data to present it later in the tableview
            currentAlbumData = album.ae_tableRepresentation()
        } else {
            currentAlbumData = nil
        }
        // we have the data we need, let's refresh our tableview
        dataTable!.reloadData()
    }
    
    func reloadScroller() {
        allAlbums = LibraryAPI.sharedInstance.getAlbums()
        if currentAlbumIndex < 0 {
            currentAlbumIndex = 0
        } else if currentAlbumIndex >= allAlbums.count {
            currentAlbumIndex = allAlbums.count - 1
        }
        scroller.reload()
        showDataForAlbum(currentAlbumIndex)
    }

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
    
    // MARK: Memento Pattern
    func saveCurrentState() {
        // When the user leaves the app and then comes back again, he wants it to be in the exact same state
        // he left it. In order to do this we need to save the currently displayed album.
        // Since it's only one piece of information we can use NSUserDefaults.
        NSUserDefaults.standardUserDefaults().setInteger(currentAlbumIndex, forKey: "currentAlbumIndex")
        LibraryAPI.sharedInstance.saveAlbums()
    }
    
    func loadPreviousState() {
        currentAlbumIndex = NSUserDefaults.standardUserDefaults().integerForKey("currentAlbumIndex")
        showDataForAlbum(currentAlbumIndex)
    }
    
    func initialViewIndex(scroller: HorizontalScroller) -> Int {
        return currentAlbumIndex
    }
    
    func addAlbumAtIndex(album: Album, index: Int) {
        LibraryAPI.sharedInstance.addAlbum(album, index: index)
        currentAlbumIndex = index
        reloadScroller()
    }
    
    func deleteAlbum() {
        var deletedAlbum: Album = allAlbums[currentAlbumIndex]
        
        var undoAction = (deletedAlbum, currentAlbumIndex)
        undoStack.insert(undoAction, atIndex: 0)
        
        LibraryAPI.sharedInstance.deleteAlbum(currentAlbumIndex)
        reloadScroller()
        
        let barButtonItems = toolbar.items as [UIBarButtonItem]
        var undoButton: UIBarButtonItem = barButtonItems[0]
        undoButton.enabled = true
        
        if (allAlbums.count == 0) {
            var trashButton: UIBarButtonItem = barButtonItems[2]
            trashButton.enabled = false
        }
    }
    
    func undoAction() {
        let barButtonItems = toolbar.items as [UIBarButtonItem]
        
        if undoStack.count > 0 {
            let (deletedAlbum, index) = undoStack.removeAtIndex(0)
            addAlbumAtIndex(deletedAlbum, index: index)
        }
        
        if undoStack.count == 0 {
            var undoButton: UIBarButtonItem = barButtonItems[0]
            undoButton.enabled = false
        }
        
        let trashButton: UIBarButtonItem = barButtonItems[2]
        trashButton.enabled = true
    }

}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let albumData = currentAlbumData {
            return albumData.titles.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        if let albumData = currentAlbumData {
            cell.textLabel?.text = albumData.titles[indexPath.row]
            if let detailTextLabel = cell.detailTextLabel {
                detailTextLabel.text = albumData.values[indexPath.row]
            }
        }
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
}

extension ViewController: HorizontalScrollerDelegate {
    func horizontalScrollerClickedViewAtIndex(scroller: HorizontalScroller, index: Int) {
        let previousAlbumView = scroller.viewAtIndex(currentAlbumIndex) as AlbumView
        previousAlbumView.highlightAlbum(didHighlightView: false)
        
        currentAlbumIndex = index
        
        let albumView = scroller.viewAtIndex(index) as AlbumView
        albumView.highlightAlbum(didHighlightView: true)
        
        showDataForAlbum(index)
    }
    
    func numberOfViewsForHorizontalScroller(scroller: HorizontalScroller) -> Int {
        return allAlbums.count
    }
    
    func horizontalScrollerViewAtIndex(scroller: HorizontalScroller, index: Int) -> UIView {
        let album = allAlbums[index]
        let albumView = AlbumView(frame: CGRectMake(0, 0, 100, 100), albumCover: album.coverUrl)
        if currentAlbumIndex == index {
            albumView.highlightAlbum(didHighlightView: true)
        } else {
            albumView.highlightAlbum(didHighlightView: false)
        }
        return albumView
    }
}
