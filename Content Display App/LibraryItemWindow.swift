//
//  LibraryItemWindow.swift
//  Content Display App
//
//  Created by David on 2/20/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import CoreData

class LibraryItemWindow: GeneratedLibraryItemWindow, Codable {
    
    // The following code based on: https://medium.com/@andrea.prearo/working-with-codable-and-core-data-83983e77198e
    
    enum CodingKeys: String, CodingKey {
        case id
        case start
        case end
    }
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext,
            let managedObjectContext = decoder.userInfo[codingUserInfoKeyManagedObjectContext] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "LibraryItemWindow", in: managedObjectContext) else {
                fatalError("Failed to decode LibraryItemWindow")
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)!
        self.start = try container.decodeIfPresent(Date.self, forKey: .start)
        self.end = try container.decodeIfPresent(Date.self, forKey: .end)
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(start, forKey: .start)
        try container.encode(end, forKey: .end)
    }

}
