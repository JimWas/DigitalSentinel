//
//  Item.swift
//  Digital Sentenial
//
//  Created by Jim Washkau on 2/9/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
