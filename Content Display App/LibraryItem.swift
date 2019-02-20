//
//  LibraryItem.swift
//  Content Display App
//
//  Created by David on 2/20/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import CoreData

class LibraryItem: GeneratedLibraryItem, Codable {
    
    // The following code based on: https://medium.com/@andrea.prearo/working-with-codable-and-core-data-83983e77198e
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case windows
    }
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext,
            let managedObjectContext = decoder.userInfo[codingUserInfoKeyManagedObjectContext] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "LibraryItem", in: managedObjectContext) else {
                fatalError("Failed to decode LibraryItem")
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)!
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        
        // I had a lot of fun figuring this out, due to Core Data's silly preference for NSOrderedSet! It was a real adventure, full of EXC_BAD_ACCESS! <3 Core Data
        self.removeFromWindows(at: NSIndexSet(indexesIn: NSRange(location: 0, length: self.windows?.count ?? 0)))
        if let windows = try container.decodeIfPresent([LibraryItemWindow].self, forKey: .windows) {
            self.addToWindows(NSOrderedSet(array: windows))
        }
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        if let windowsArray = windows?.array as? [LibraryItemWindow] {
            try container.encode(windowsArray, forKey: .windows)
        }
    }
    
}
