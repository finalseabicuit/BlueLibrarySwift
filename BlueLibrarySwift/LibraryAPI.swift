//
//  LibraryAPI.swift
//  BlueLibrarySwift
//
//  Created by chanju Jeon on 2015. 1. 2..
//  Copyright (c) 2015년 Raywenderlich. All rights reserved.
//

import UIKit

class LibraryAPI: NSObject {
    class var sharedInstance: LibraryAPI {
        struct Singleton {
            static let instance = LibraryAPI()
        }
        return Singleton.instance
    }
    
    
}
