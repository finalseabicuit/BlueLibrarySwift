//
//  AlbumExtensions.swift
//  BlueLibrarySwift
//
//  Created by chanju Jeon on 2015. 1. 2..
//  Copyright (c) 2015년 Raywenderlich. All rights reserved.
//

import Foundation

extension Album {
    func ae_tableRepresentation() -> (titles: [String], values: [String]) {
        return (["Artist", "Album", "Genre", "Year"], [artist, title, genre, year])
    }
}