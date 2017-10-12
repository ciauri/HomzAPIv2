//
//  InitializationEntity.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 9/16/17.
//

import Foundation
import PerfectLib

class Initialization {}

// MARK: - RESTEntity
extension Initialization: RESTEntity {
    var href: URL? {
        return NewHomzAPI.shared.baseURL
    }
    
    var links: [String:URL] {
        return [
            "mapListings" : ListingResource.mapRoute.absoluteURLString.urlValue!,
            "featuredListings": ListingResource.featuredRoute.absoluteURLString.urlValue!,
            "allBuilders" : BuilderResource.allRoute.absoluteURLString.urlValue!,
            "featuredBuilders" : BuilderResource.featuredRoute.absoluteURLString.urlValue!
        ]
    }
}

// MARK: - Encodable
extension Initialization: Encodable {
    
    fileprivate enum CodingKeys: String, CodingKey {
        case href
        case links
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(href, forKey: .href)
        try container.encode(links, forKey: .links)
    }

}
