//
//  InitializationEntity.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 9/16/17.
//

import Foundation
import PerfectLib

class Initialization: JSONConvertibleObject {
    
    override func getJSONValues() -> [String : Any] {
        return [
            "href": href ?? "",
            "links": links
        ]
    }
}

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
